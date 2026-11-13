import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ikai/core/atividades.dart';
import 'package:ikai/core/motor_ik_ai.dart';
import 'package:ikai/core/sem_emoji.dart';
import 'package:ikai/services/auth_service.dart';
import 'package:ikai/services/chat_ik_ai.dart';
import 'package:ikai/services/compromisso_service.dart';
import 'package:ikai/services/gemini_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

String _corpoApi(String texto) => jsonEncode({
      'candidates': [
        {
          'content': {
            'parts': [
              {'text': texto},
            ],
          },
        },
      ],
    });

const _respOk = '{"resposta":"Sem o livro, que tal ouvir e contar uma '
    'história?","ideias":[{"titulo":"Contar a história de um livro que você '
    'amou","passos":"Conte em voz alta, para você mesmo ou para alguém, o '
    'enredo em 5 minutos.","minutos":5},{"titulo":"Caminhar sem '
    'celular","passos":"Saia por 15 minutos sem o aparelho.","minutos":15}]}';

ContextoConversa _ctx({bool permitiu = true, List<TurnoConversa>? turnos}) =>
    ContextoConversa(
      objetivoTitulo: 'Ler',
      temasDeclarados: const ['leitura'],
      condicoes: 'sem o livro',
      textoDaSessao: 'lendo Capitães da Areia',
      turnos: turnos ??
          const [
            TurnoConversa(daIa: true, texto: 'Seu tempo acabou.'),
            TurnoConversa(daIa: false, texto: 'Não tenho meu livro'),
          ],
      permitiuEnvio: permitiu,
    );

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    CompromissoService.instance.limpar();
  });
  tearDown(() => AuthService.instance.sair());

  group('GeminiService.conversar', () {
    test('sem chave ou sem autorização: não chama a rede', () async {
      var chamadas = 0;
      Future<RespostaHttp> espia(u, h, b, l) async {
        chamadas++;
        return RespostaHttp(200, _corpoApi(_respOk));
      }

      final semChave = GeminiService(chave: '', enviar: espia);
      expect((await semChave.conversar(_ctx())).ok, isFalse);
      final semOk = GeminiService(chave: 'k', enviar: espia);
      final r = await semOk.conversar(_ctx(permitiu: false));
      expect(r.ok, isFalse);
      expect(r.motivo, contains('autorizou'));
      expect(chamadas, 0);
    });

    test('resposta válida vira texto e ideias marcadas como da IA', () async {
      final svc = GeminiService(
        chave: 'k',
        enviar: (u, h, b, l) async => RespostaHttp(200, _corpoApi(_respOk)),
      );
      final r = await svc.conversar(_ctx());
      expect(r.ok, isTrue);
      expect(r.resposta!.texto, contains('Sem o livro'));
      expect(r.resposta!.ideias.length, 2);
      expect(r.resposta!.ideias.every((a) => a.deIa), isTrue);
      expect(r.resposta!.ideias.first.minutos, 5);
      expect(r.resposta!.ideias.first.id.startsWith('ia_'), isTrue);
    });

    test('falhas viram resultado com motivo, nunca exceção', () async {
      for (final enviar in <EnviarHttp>[
        (u, h, b, l) async => const RespostaHttp(404, 'x'),
        (u, h, b, l) async => const RespostaHttp(200, 'não é json'),
        (u, h, b, l) async => RespostaHttp(200, _corpoApi('{"x":1}')),
        (u, h, b, l) async => throw Exception('rede'),
      ]) {
        final r = await GeminiService(chave: 'k', enviar: enviar)
            .conversar(_ctx());
        expect(r.ok, isFalse);
        expect(r.motivo, isNotNull);
      }
    });

    test('resposta com cerca de código e emojis é limpa', () async {
      final texto = '```json\n{"resposta":"Oi \u{1F600} tudo bem?",'
          '"ideias":[{"titulo":"Alongar \u{1F9D8}","passos":"Alongue 5 '
          'minutos.","minutos":999}]}\n```';
      final r = GeminiService.extrairConversa(_corpoApi(texto))!;
      expect(temEmoji(r.texto), isFalse);
      expect(temEmoji(r.ideias.first.titulo), isFalse);
      expect(r.ideias.first.minutos, 10); // 999 é inválido: usa o padrão
    });

    test('no máximo 3 ideias e ideias sem passos são ignoradas', () {
      final ideias = [
        for (var k = 0; k < 6; k++)
          {'titulo': 'Ideia $k', 'passos': 'Faça $k.', 'minutos': 5},
        {'titulo': 'Sem passos'},
      ];
      final r = GeminiService.extrairConversa(
          _corpoApi(jsonEncode({'resposta': 'ok', 'ideias': ideias})))!;
      expect(r.ideias.length, 3);
    });

    test('corpo: papéis alternam, texto do usuário fica entre marcas, '
        'sem nome nem e-mail', () {
      final corpo = jsonEncode(GeminiService.montarCorpoConversa(_ctx(
        turnos: const [
          TurnoConversa(daIa: true, texto: 'Abertura'),
          TurnoConversa(daIa: false, texto: 'Não tenho meu livro'),
          TurnoConversa(daIa: false, texto: 'e estou cansado'),
        ],
      )));
      final m = jsonDecode(corpo) as Map;
      final contents = m['contents'] as List;
      expect(contents.length, 1); // a abertura da IA no início é descartada
      expect(contents.first['role'], 'user');
      final t = contents.first['parts'][0]['text'] as String;
      expect(t, contains('<declarado>\nNão tenho meu livro\n</declarado>'));
      expect(t, contains('<declarado>\ne estou cansado'));
      expect(t, contains('Condições ditas por ela: sem o livro'));
      expect(t, contains('Temas que a pessoa declarou: leitura'));
      expect(corpo.contains('@'), isFalse);
      expect(corpo, contains('system_instruction'));
      expect(m['generationConfig']['responseMimeType'], 'application/json');
    });

    test('só as últimas 8 falas são enviadas', () {
      final turnos = [
        for (var k = 0; k < 20; k++)
          TurnoConversa(daIa: k.isOdd, texto: 'fala $k'),
      ];
      final corpo = jsonEncode(GeminiService.montarCorpoConversa(
        _ctx(turnos: [...turnos, const TurnoConversa(daIa: false, texto: 'fim')]),
      ));
      expect(corpo.contains('fala 0'), isFalse);
      expect(corpo, contains('fim'));
    });

    test('a instrução proíbe inferir e pede para respeitar o que falta', () {
      expect(GeminiService.instrucaoDaConversa, contains('Nunca infira'));
      expect(GeminiService.instrucaoDaConversa, contains('sem o livro'));
      expect(temEmoji(GeminiService.instrucaoDaConversa), isFalse);
    });
  });

  group('ChatIkAi sem Gemini', () {
    ChatIkAi chat({Set<Tema>? temas, AoCombinar? aoCombinar}) => ChatIkAi(
          estado: EstadoConversa(temas: temas ?? {Tema.leitura}),
          gemini: GeminiService(chave: ''),
          aoCombinar: aoCombinar,
        );

    test('começa com mensagem da IA e várias opções', () {
      final c = chat()..iniciar();
      expect(c.mensagens.length, 1);
      expect(c.mensagens.first.autor, Autor.ia);
      expect(c.mensagens.first.opcoes.length, 3);
      c.iniciar(); // idempotente
      expect(c.mensagens.length, 1);
    });

    test('"não tenho meu livro": novas opções sem livro, e ainda leitura',
        () async {
      final c = chat()..iniciar();
      await c.enviar('Não tenho meu livro');
      final ultima = c.mensagens.last;
      expect(ultima.autor, Autor.ia);
      expect(ultima.opcoes, isNotEmpty);
      expect(
          ultima.opcoes.any((a) => a.precisa.contains(Material.livro)), isFalse);
      expect(ultima.opcoes.any((a) => a.tema == Tema.leitura), isTrue);
      expect(c.motivoLocal, isNotNull);
      expect(c.ultimaViaGemini, isFalse);
    });

    test('escolher -> pergunta o quando -> combinado registrado', () async {
      final combinados = <String>[];
      final c = chat(aoCombinar: (a, q) => combinados.add('${a.id}|$q'))
        ..iniciar();
      final escolhida = c.mensagens.first.opcoes.first;
      c.escolher(escolhida);
      expect(c.aguardandoQuando, isTrue);
      expect(c.mensagens.last.chips, contains('Antes de dormir'));
      await c.enviar('Depois do jantar');
      expect(combinados, ['${escolhida.id}|Depois do jantar']);
      expect(c.mensagens.last.texto, contains('depois do jantar'));
      expect(c.encerrada, isTrue);
      await c.enviar('mais uma coisa'); // encerrada: ignora
      expect(combinados.length, 1);
    });

    test('desistir da escolha com "outra ideia" não cria combinado',
        () async {
      var criados = 0;
      final c = chat(aoCombinar: (a, q) => criados++)..iniciar();
      c.escolher(c.mensagens.first.opcoes.first);
      await c.enviar('quero outra ideia');
      expect(criados, 0);
      expect(c.aguardandoQuando, isFalse);
      expect(c.mensagens.last.opcoes, isNotEmpty);
    });

    test('mensagem vazia ou só emoji é ignorada; texto longo é cortado',
        () async {
      final c = chat()..iniciar();
      await c.enviar('   ');
      await c.enviar('\u{1F600}');
      expect(c.mensagens.length, 1);
      await c.enviar('a' * 1000);
      final usuario = c.mensagens.firstWhere((m) => m.autor == Autor.usuario);
      expect(usuario.texto.length, ChatIkAi.limiteTexto);
    });

    test('sinal de sofrimento: encaminha para ajuda e não oferece ideias',
        () async {
      final c = chat()..iniciar();
      await c.enviar('às vezes quero morrer');
      final u = c.mensagens.last;
      expect(u.texto, contains('188'));
      expect(u.texto, contains('192'));
      expect(u.opcoes, isEmpty);
    });

    test('descansar encerra sem criar combinado', () async {
      var criados = 0;
      final c = chat(aoCombinar: (a, q) => criados++)..iniciar();
      await c.enviar(ChatIkAi.chipDescansar);
      expect(c.encerrada, isTrue);
      expect(criados, 0);
    });

    test('conversa longa nunca repete opções já recusadas', () async {
      final c = chat(temas: {Tema.leitura, Tema.treino})..iniciar();
      final vistas = <String>{...c.mensagens.first.opcoes.map((a) => a.id)};
      for (var k = 0; k < 5; k++) {
        await c.enviar('outra ideia');
        for (final a in c.mensagens.last.opcoes) {
          expect(vistas.add(a.id), isTrue, reason: 'repetiu ${a.id}');
        }
      }
    });

    test('nenhuma mensagem do chat tem emoji', () async {
      final c = chat()..iniciar();
      await c.enviar('estou cansado e sem livro');
      c.escolher(c.mensagens.last.opcoes.first);
      await c.enviar('agora');
      for (final m in c.mensagens) {
        expect(temEmoji(m.texto), isFalse, reason: m.texto);
        for (final a in m.opcoes) {
          expect(temEmoji('${a.titulo}${a.passos}'), isFalse);
        }
      }
    });
  });

  group('ChatIkAi com Gemini', () {
    test('usa a resposta do Gemini e completa com opções do app', () async {
      String? corpoEnviado;
      final c = ChatIkAi(
        estado: EstadoConversa(temas: {Tema.leitura}),
        nome: 'Ana',
        usarGemini: true,
        gemini: GeminiService(
          chave: 'k',
          enviar: (u, h, b, l) async {
            corpoEnviado = b;
            return RespostaHttp(200, _corpoApi(_respOk));
          },
        ),
      )..iniciar();
      await c.enviar('Não tenho meu livro');
      final u = c.mensagens.last;
      expect(c.ultimaViaGemini, isTrue);
      expect(u.texto, contains('Sem o livro'));
      expect(u.opcoes.where((a) => a.deIa).length, 2);
      expect(u.opcoes.length, greaterThanOrEqualTo(2));
      expect(corpoEnviado!.contains('Ana'), isFalse); // nome nunca sai
      expect(c.pensando, isFalse);
    });

    test('Gemini fora do ar: cai no motor local com várias opções', () async {
      final c = ChatIkAi(
        estado: EstadoConversa(temas: {Tema.leitura}),
        usarGemini: true,
        gemini: GeminiService(
          chave: 'k',
          enviar: (u, h, b, l) async => const RespostaHttp(503, ''),
        ),
      )..iniciar();
      await c.enviar('Não tenho meu livro');
      expect(c.ultimaViaGemini, isFalse);
      expect(c.mensagens.last.opcoes.length, 3);
      expect(c.motivoLocal, contains('503'));
    });

    test('sem autorização (interruptor desligado) não chama a rede',
        () async {
      var chamadas = 0;
      final c = ChatIkAi(
        estado: EstadoConversa(temas: {Tema.leitura}),
        usarGemini: false,
        gemini: GeminiService(
          chave: 'k',
          enviar: (u, h, b, l) async {
            chamadas++;
            return RespostaHttp(200, _corpoApi(_respOk));
          },
        ),
      )..iniciar();
      await c.enviar('Não tenho meu livro');
      expect(chamadas, 0);
    });

    test('sinal de sofrimento nunca vai para o Gemini', () async {
      var chamadas = 0;
      final c = ChatIkAi(
        estado: EstadoConversa(),
        usarGemini: true,
        gemini: GeminiService(
          chave: 'k',
          enviar: (u, h, b, l) async {
            chamadas++;
            return RespostaHttp(200, _corpoApi(_respOk));
          },
        ),
      )..iniciar();
      await c.enviar('quero me machucar');
      expect(chamadas, 0);
      expect(c.mensagens.last.texto, contains('188'));
    });

    test('limite de chamadas à IA por conversa', () async {
      var chamadas = 0;
      final c = ChatIkAi(
        estado: EstadoConversa(temas: {Tema.leitura, Tema.treino}),
        usarGemini: true,
        gemini: GeminiService(
          chave: 'k',
          enviar: (u, h, b, l) async {
            chamadas++;
            return RespostaHttp(200, _corpoApi(_respOk));
          },
        ),
      )..iniciar();
      for (var k = 0; k < 20; k++) {
        await c.enviar('outra ideia $k');
      }
      expect(chamadas, lessThanOrEqualTo(ChatIkAi.limiteChamadasIa));
    });
  });

  group('CompromissoService', () {
    final atv = atividadePorId('tre_alongar')!;

    test('adicionar, pendente e responder', () {
      final s = CompromissoService.instance;
      expect(s.pendente, isNull);
      final c = s.adicionar(atv, 'depois do jantar');
      expect(s.pendente?.id, c.id);
      expect(s.pendente?.quando, 'depois do jantar');
      s.responder(c.id, RespostaCombinado.fiz);
      expect(s.pendente, isNull);
      expect(s.feitos, 1);
      expect(s.respondidos, 1);
      s.responder(c.id, RespostaCombinado.naoFiz); // já respondido: ignora
      expect(s.feitos, 1);
      expect(s.naoFeitos, 0);
    });

    test('novo combinado encerra o anterior sem resposta', () {
      final s = CompromissoService.instance;
      s.adicionar(atv, 'agora');
      s.adicionar(atividadePorId('lei_contar')!, 'amanhã');
      expect(s.todos.length, 2);
      expect(s.naoFeitos, 1);
      expect(s.pendente?.atividadeId, 'lei_contar');
    });

    test('quando vazio vira "agora"; texto longo é cortado; sem emoji', () {
      final s = CompromissoService.instance;
      expect(s.adicionar(atv, '  ').quando, 'agora');
      expect(s.adicionar(atv, 'x' * 200).quando.length,
          CompromissoService.limiteQuando);
      expect(temEmoji(s.adicionar(atv, 'hoje \u{1F600}').quando), isFalse);
    });

    test('grava por conta, não mistura contas e some ao excluir', () async {
      final s = CompromissoService.instance;
      await s.carregarPara('a@x.com');
      s.adicionar(atv, 'agora');
      await Future<void>.delayed(Duration.zero);

      await s.carregarPara('b@x.com');
      expect(s.todos, isEmpty);

      await s.carregarPara('a@x.com');
      expect(s.todos.length, 1);
      expect(s.todos.first.titulo, atv.titulo);

      await s.apagarDaConta();
      expect(s.todos, isEmpty);
      await s.carregarPara('a@x.com');
      expect(s.todos, isEmpty);
    });

    test('limpar esquece a memória, mas o gravado permanece', () async {
      final s = CompromissoService.instance;
      await s.carregarPara('a@x.com');
      s.adicionar(atv, 'agora');
      await Future<void>.delayed(Duration.zero);
      s.limpar();
      expect(s.todos, isEmpty);
      await s.carregarPara('a@x.com');
      expect(s.todos.length, 1);
    });

    test('dados corrompidos não quebram o carregamento', () async {
      SharedPreferences.setMockInitialValues(
          {'combinados_v1_a@x.com': '{lixo'});
      final s = CompromissoService.instance;
      await s.carregarPara('a@x.com');
      expect(s.todos, isEmpty);
    });

    test('limite de itens guardados', () {
      final s = CompromissoService.instance..limpar();
      for (var k = 0; k < CompromissoService.limiteGuardado + 10; k++) {
        s.adicionar(atv, 'q$k');
      }
      expect(s.todos.length, CompromissoService.limiteGuardado);
    });

    test('descartarPendente remove sem contar como feito ou falha', () {
      final s = CompromissoService.instance..limpar();
      s.adicionar(atv, 'agora');
      s.descartarPendente();
      expect(s.todos, isEmpty);
      expect(s.respondidos, 0);
    });
  });
}
