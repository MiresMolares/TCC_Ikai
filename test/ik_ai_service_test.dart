import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ikai/services/auth_service.dart';
import 'package:ikai/services/gemini_service.dart';
import 'package:ikai/services/ik_ai_service.dart';
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

const _ok = '{"sugestoes":["Leia 20 minutos de Capitães da Areia.",'
    '"Monte um treino de 25 minutos.","Escreva cinco frases em francês."]}';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    IkAiService.limpar();
    IkAiService.gemini = GeminiService(chave: '');
  });

  tearDown(() => AuthService.instance.sair());

  group('Sem dados inventados', () {
    test('sem nada declarado: mensagem neutra, sem nome nem livro padrão',
        () async {
      final m = await IkAiService.gerarMensagemFimDeTempo();
      expect(m, 'Seu tempo no Ikai acabou. O que você quer fazer agora, '
          'longe da tela?');
      expect(m.contains('Caio'), isFalse);
      expect(m.contains('Paixão'), isFalse);
    });

    test('usuarioLogado é null sem login e não traz valores padrão', () {
      expect(IkAiService.usuarioLogado, isNull);
      AuthService.instance.entrar('adm@email.com', '1234');
      final u = IkAiService.usuarioLogado!;
      expect(u['vontades'], isEmpty);
      expect(u['categoriaPrincipal'], isNull);
      expect(u['detalhePrincipal'], isNull);
    });

    test('definirUsuarioLogado(null) limpa e não cria padrões', () async {
      IkAiService.definirUsuarioLogado({
        'vontades': ['Ler mais'],
        'categoriaPrincipal': 'Ler mais',
        'detalhePrincipal': 'Dom Casmurro',
      });
      expect(IkAiService.memoria.temDetalhe, isTrue);
      IkAiService.definirUsuarioLogado(null);
      expect(IkAiService.memoria.temDetalhe, isFalse);
    });

    test('nome só aparece se existir, sem vírgula solta', () async {
      final sem = await IkAiService.gerarPerguntaCadastro(
        vontades: const ['Ler mais'],
      );
      expect(sem, startsWith('Que bom que você quer ler mais! Qual livro'));
      final com = await IkAiService.gerarPerguntaCadastro(
        nomeUsuario: 'Ana Souza',
        vontades: const ['Ler mais'],
      );
      expect(com, contains('Ana, qual livro'));
      expect(com.contains('Souza'), isFalse);
    });
  });

  group('Memória declarada', () {
    test('confirmar guarda de verdade e volta ao carregar a mesma conta',
        () async {
      await IkAiService.carregarPara('a@x.com');
      final msg = await IkAiService.confirmarMemoriaSalva(
        nomeUsuario: 'Ana',
        categoriaFoco: 'Ler mais',
        respostaUsuario: '  Capitães   da Areia  ',
      );
      expect(msg, contains('"Capitães da Areia"'));
      expect(IkAiService.memoria.detalhePrincipal, 'Capitães da Areia');

      IkAiService.limpar();
      expect(IkAiService.memoria.temDetalhe, isFalse);
      await IkAiService.carregarPara('a@x.com');
      expect(IkAiService.memoria.detalhePrincipal, 'Capitães da Areia');
      expect(IkAiService.memoria.categoriaPrincipal, 'Ler mais');
    });

    test('outra conta nunca vê a memória da primeira', () async {
      await IkAiService.carregarPara('a@x.com');
      await IkAiService.confirmarMemoriaSalva(
        categoriaFoco: 'Ler mais',
        respostaUsuario: 'Dom Casmurro',
      );
      IkAiService.limpar();
      await IkAiService.carregarPara('b@x.com');
      expect(IkAiService.memoria.temDetalhe, isFalse);
    });

    test('resposta vazia não é guardada e não promete que guardou',
        () async {
      await IkAiService.carregarPara('a@x.com');
      final msg = await IkAiService.confirmarMemoriaSalva(
        categoriaFoco: 'Ler mais',
        respostaUsuario: '   ',
      );
      expect(msg.toLowerCase().contains('guardei'), isFalse);
      expect(IkAiService.memoria.temDetalhe, isFalse);
    });

    test('emojis saem e o tamanho é limitado', () async {
      await IkAiService.carregarPara('a@x.com');
      await IkAiService.confirmarMemoriaSalva(
        categoriaFoco: 'Ler mais',
        respostaUsuario: 'Livro \u{1F4DA} ${'x' * 500}',
      );
      final d = IkAiService.memoria.detalhePrincipal!;
      expect(d.contains('\u{1F4DA}'), isFalse);
      expect(d.length, lessThanOrEqualTo(IkAiService.limiteDetalhe));
    });

    test('apagarDaConta remove também o que estava gravado', () async {
      await IkAiService.carregarPara('a@x.com');
      await IkAiService.confirmarMemoriaSalva(
        categoriaFoco: 'Ler mais',
        respostaUsuario: 'Dom Casmurro',
      );
      await IkAiService.apagarDaConta();
      await IkAiService.carregarPara('a@x.com');
      expect(IkAiService.memoria.temDetalhe, isFalse);
    });
  });

  group('Gemini no fim do tempo', () {
    Future<void> declarar() async {
      await IkAiService.carregarPara('a@x.com');
      await IkAiService.confirmarMemoriaSalva(
        categoriaFoco: 'Ler mais',
        respostaUsuario: 'Capitães da Areia',
      );
    }

    test('sem autorização nada é enviado, mesmo com chave', () async {
      await declarar();
      var chamadas = 0;
      IkAiService.gemini = GeminiService(
        chave: 'K',
        enviar: (u, h, b, l) async {
          chamadas++;
          return RespostaHttp(200, _corpoApi(_ok));
        },
      );
      final m = await IkAiService.gerarMensagemFimDeTempo(
        nomeUsuario: 'Ana',
      );
      expect(chamadas, 0);
      expect(m, contains('Capitães da Areia'));
      expect(m, startsWith('Ana, seu tempo'));
    });

    test('com autorização usa o Gemini e o NOME nunca é enviado', () async {
      await declarar();
      String? corpo;
      IkAiService.gemini = GeminiService(
        chave: 'K',
        enviar: (u, h, b, l) async {
          corpo = b;
          return RespostaHttp(200, _corpoApi(_ok));
        },
      );
      final m = await IkAiService.gerarMensagemFimDeTempo(
        permitiuEnvio: true,
        nomeUsuario: 'Ana Souza',
      );
      expect(corpo, isNotNull);
      expect(corpo!.contains('Ana'), isFalse);
      expect(corpo!.contains('Souza'), isFalse);
      expect(corpo, contains('Capitães da Areia'));
      expect(m, startsWith('Ana, seu tempo no Ikai acabou.'));
      expect(m, contains('Leia 20 minutos'));
    });

    test('falha do Gemini cai na mensagem local', () async {
      await declarar();
      IkAiService.gemini = GeminiService(
        chave: 'K',
        enviar: (u, h, b, l) async => const RespostaHttp(500, 'erro'),
      );
      final m = await IkAiService.gerarMensagemFimDeTempo(
        permitiuEnvio: true,
      );
      expect(m, 'Seu tempo no Ikai acabou. Que tal ler algumas páginas de '
          'Capitães da Areia agora?');
    });
  });

  group('Sugerir outra coisa', () {
    test('percorre as outras vontades sem repetir e anota na lista',
        () async {
      IkAiService.definirUsuarioLogado({
        'vontades': ['Ler mais', 'Treinar mais', 'Meditar'],
        'categoriaPrincipal': 'Ler mais',
        'detalhePrincipal': 'Dom Casmurro',
      });
      final recusadas = <String>[];
      final a = await IkAiService.sugerirOutraCoisa(
        mensagemDoUsuario: 'não quero ler',
        historicoSugestoesRecusadas: recusadas,
      );
      expect(a, contains('treinar'));
      expect(recusadas, ['Treinar mais']);
      final b = await IkAiService.sugerirOutraCoisa(
        mensagemDoUsuario: 'também não',
        historicoSugestoesRecusadas: recusadas,
      );
      expect(b, contains('respiração'));
      expect(recusadas, ['Treinar mais', 'Meditar']);
      final c = await IkAiService.sugerirOutraCoisa(
        mensagemDoUsuario: 'nada',
        historicoSugestoesRecusadas: recusadas,
      );
      expect(c, contains('copo d'));
      expect(recusadas.length, 2);
    });

    test('sem vontades declaradas não inventa nenhuma', () async {
      final r = <String>[];
      final m = await IkAiService.sugerirOutraCoisa(
        mensagemDoUsuario: 'não',
        historicoSugestoesRecusadas: r,
      );
      expect(m, contains('copo d'));
      expect(r, isEmpty);
    });
  });
}
