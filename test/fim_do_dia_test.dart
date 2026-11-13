import 'package:flutter_test/flutter_test.dart';
import 'package:ikai/core/atividades.dart';
import 'package:ikai/core/motor_ik_ai.dart';
import 'package:ikai/core/sem_emoji.dart';
import 'package:ikai/services/acoes_fim_do_dia.dart';
import 'package:ikai/services/chat_ik_ai.dart';
import 'package:ikai/services/compromisso_service.dart';
import 'package:ikai/services/gemini_service.dart';
import 'package:ikai/services/tempo_diario.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final t = TempoDiarioService.instance;
  late DateTime agora;

  ChatIkAi novoChat({String? nome}) => ChatIkAi(
    estado: EstadoConversa(temas: {Tema.leitura}),
    gemini: GeminiService(chave: ''),
    nome: nome,
    fimDoDia: AcoesFimDoDiaReais(t),
  );

  setUp(() async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    SharedPreferences.setMockInitialValues({});
    CompromissoService.instance.limpar();
    agora = DateTime(2026, 11, 11, 9);
    t.agora = () => agora;
    await t.carregarPara('a@x.com');
    t.agora = () => agora;
    t.definirMeta(20);
  });

  group('Conversa de fim do dia', () {
    test('abertura mostra o uso e os caminhos, sem inferir nada', () {
      t.tick(1200);
      final c = novoChat(nome: 'Ana')..iniciar();
      final m = c.mensagens.first;
      expect(m.texto, startsWith('Ana, seu tempo de hoje no Ikai acabou'));
      expect(m.texto, contains('20 min de 20 min'));
      expect(m.chips, [
        ChatIkAi.chipAprendi,
        ChatIkAi.chipContinuar,
        ChatIkAi.chipIdeias,
        ChatIkAi.chipEncerrar,
      ]);
      expect(temEmoji(m.texto), isFalse);
    });

    test(
      'contar o que aprendeu: registra e devolve o que a pessoa disse',
      () async {
        t.tick(1200);
        final c = novoChat()..iniciar();
        await c.enviar(ChatIkAi.chipAprendi);
        expect(c.mensagens.last.texto, contains('o que você aprendeu'));
        await c.enviar('Aprendi como começou a Revolução Francesa');
        expect(
          c.mensagens.last.texto,
          contains('Anotei: "Aprendi como começou a Revolução Francesa"'),
        );
        expect(t.reflexoes.single.tipo, 'aprendi');
        expect(
          t.reflexoes.single.texto,
          'Aprendi como começou a Revolução Francesa',
        );
        // A conversa continua aberta, sem repetir "contar o que aprendi".
        expect(c.mensagens.last.chips.contains(ChatIkAi.chipAprendi), isFalse);
        expect(c.encerrada, isFalse);
      },
    );

    test('continuar: pede o motivo, pergunta o tempo e libera o app', () async {
      t.tick(1200);
      final c = novoChat()..iniciar();
      await c.enviar(ChatIkAi.chipContinuar);
      expect(c.mensagens.last.texto, contains('por que você quer continuar'));
      await c.enviar('quero terminar o capítulo');
      expect(c.mensagens.last.texto, contains('Quanto tempo a mais'));
      expect(c.mensagens.last.chips, [
        '10 min',
        '15 min',
        '30 min',
        'Mudei de ideia',
      ]);
      expect(t.fase, FaseDoDia.fimDeTempo); // ainda não liberou
      await c.enviar('15 min');
      expect(t.fase, FaseDoDia.dentro);
      expect(t.limiteHojeSeg, 1200 + 900);
      expect(t.reflexoes.single.tipo, 'continuar');
      expect(t.reflexoes.single.texto, 'quero terminar o capítulo');
      expect(c.mensagens.last.texto, contains('mais 15 min'));
    });

    test('motivo curto demais não avança', () async {
      t.tick(1200);
      final c = novoChat()..iniciar();
      await c.enviar(ChatIkAi.chipContinuar);
      await c.enviar('ok');
      expect(c.mensagens.last.texto, contains('um pouco mais'));
      expect(t.fase, FaseDoDia.fimDeTempo);
    });

    test('"Mudei de ideia" volta ao menu sem dar tempo', () async {
      t.tick(1200);
      final c = novoChat()..iniciar();
      await c.enviar(ChatIkAi.chipContinuar);
      await c.enviar('mais um pouco por favor');
      await c.enviar(ChatIkAi.chipMudei);
      expect(t.fase, FaseDoDia.fimDeTempo);
      expect(t.limiteHojeSeg, 1200);
      expect(c.mensagens.last.chips.contains(ChatIkAi.chipEncerrar), isTrue);
    });

    test('tempo inválido é recusado e a pergunta se repete', () async {
      t.tick(1200);
      final c = novoChat()..iniciar();
      await c.enviar(ChatIkAi.chipContinuar);
      await c.enviar('preciso terminar a leitura');
      await c.enviar('999 min');
      expect(t.fase, FaseDoDia.fimDeTempo);
      expect(c.mensagens.last.texto, contains('Escolha uma das opções'));
    });

    test('depois de 2 extensões, não oferece mais', () async {
      t.tick(1200);
      t.prorrogar(10, 'primeira vez');
      t.tick(600);
      t.prorrogar(10, 'segunda vez');
      t.tick(600);
      final c = novoChat()..iniciar();
      await c.enviar(ChatIkAi.chipContinuar);
      expect(c.mensagens.last.texto, contains('2 vezes hoje, que é o limite'));
      expect(c.mensagens.last.chips.contains(ChatIkAi.chipEncerrar), isTrue);
      expect(t.fase, FaseDoDia.fimDeTempo);
    });

    test('encerrar por hoje trava o dia', () async {
      t.tick(1200);
      final c = novoChat()..iniciar();
      await c.enviar(ChatIkAi.chipEncerrar);
      expect(t.fase, FaseDoDia.encerrado);
      expect(c.encerrada, isTrue);
    });

    test(
      'fim voluntário: pode voltar ao app e não oferece "continuar"',
      () async {
        t.tick(300);
        t.abrirFimVoluntario();
        final c = novoChat()..iniciar();
        expect(c.mensagens.first.texto, contains('quer encerrar o dia'));
        expect(
          c.mensagens.first.chips.contains(ChatIkAi.chipContinuar),
          isFalse,
        );
        expect(c.mensagens.first.chips.contains(ChatIkAi.chipVoltar), isTrue);
        await c.enviar(ChatIkAi.chipVoltar);
        expect(t.fase, FaseDoDia.dentro);
      },
    );

    test('ideias longe da tela: opções reais e saídas sempre à mão', () async {
      t.tick(1200);
      final c = novoChat()..iniciar();
      await c.enviar(ChatIkAi.chipIdeias);
      final m = c.mensagens.last;
      expect(m.opcoes.length, 3);
      expect(m.chips, contains(ChatIkAi.chipEncerrar));
      expect(m.chips, contains(ChatIkAi.chipContinuar));

      // E ainda entende "sem livro".
      await c.enviar('Não tenho meu livro');
      final u = c.mensagens.last;
      expect(u.opcoes.any((a) => a.precisa.contains(Material.livro)), isFalse);
      expect(u.chips, contains(ChatIkAi.chipEncerrar));
    });

    test('escolher uma ideia no fim do dia mantém a conversa aberta', () async {
      t.tick(1200);
      final criados = <String>[];
      final c = ChatIkAi(
        estado: EstadoConversa(temas: {Tema.leitura}),
        gemini: GeminiService(chave: ''),
        fimDoDia: AcoesFimDoDiaReais(t),
        aoCombinar: (a, q) => criados.add(q),
      )..iniciar();
      await c.enviar(ChatIkAi.chipIdeias);
      c.escolher(c.mensagens.last.opcoes.first);
      await c.enviar('Depois do jantar');
      expect(criados, ['Depois do jantar']);
      expect(c.encerrada, isFalse);
      expect(c.mensagens.last.chips, contains(ChatIkAi.chipEncerrar));
    });

    test(
      'sinal de sofrimento no meio do passo: cuidado, sem registrar nada',
      () async {
        t.tick(1200);
        final c = novoChat()..iniciar();
        await c.enviar(ChatIkAi.chipAprendi);
        await c.enviar('quero me machucar');
        expect(c.mensagens.last.texto, contains('188'));
        expect(t.reflexoes, isEmpty);
      },
    );

    test('nenhum texto da conversa de fim tem emoji', () async {
      t.tick(1200);
      final c = novoChat(nome: 'Ana')..iniciar();
      await c.enviar(ChatIkAi.chipContinuar);
      await c.enviar('terminar o texto');
      await c.enviar('10 min');
      for (final m in c.mensagens) {
        expect(temEmoji(m.texto), isFalse, reason: m.texto);
        for (final ch in m.chips) {
          expect(temEmoji(ch), isFalse);
        }
      }
    });
  });
}
