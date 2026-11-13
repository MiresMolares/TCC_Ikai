import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ikai/data/artigo.dart';
import 'package:ikai/services/api_client.dart';
import 'package:ikai/services/auth_service.dart';
import 'package:ikai/services/chat_fabrica.dart';
import 'package:ikai/services/conteudo_remoto.dart';
import 'package:ikai/services/conteudo_repositorio.dart';
import 'package:ikai/services/conteudo_usuario.dart';
import 'package:ikai/services/config_service.dart';
import 'package:ikai/services/gemini_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Servidor de mentira: guarda as chamadas e devolve respostas combinadas.
class Falso {
  final chamadas = <({String metodo, String caminho, Map<String, String> cab, String? corpo})>[];
  final respostas = <String, RespostaApi>{}; // "METODO /caminho"
  Object? erro;

  Future<RespostaApi> enviar(String m, Uri u, Map<String, String> cab, String? corpo, Duration l) async {
    chamadas.add((metodo: m, caminho: u.path, cab: cab, corpo: corpo));
    if (erro != null) throw erro!;
    return respostas['$m ${u.path}'] ?? const RespostaApi(200, '[]');
  }

  ApiClient api({String base = 'http://srv:3000/'}) =>
      ApiClient(baseUrl: base, enviar: enviar);
}

String json(Object o) => jsonEncode(o);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('ApiClient', () {
    test('sem endereço fica inativo e não chama a rede', () async {
      final f = Falso();
      final api = ApiClient(baseUrl: '', enviar: f.enviar);
      expect(api.ativo, isFalse);
      var lancou = false;
      try {
        await api.pedir('GET', '/artigos');
      } on ErroApi {
        lancou = true;
      }
      expect(lancou, isTrue);
      expect(f.chamadas, isEmpty);
    });

    test('tira a barra final, manda JSON e o token', () async {
      final f = Falso();
      f.respostas['POST /x'] = RespostaApi(200, json({'a': 1}));
      final api = f.api()..token = 'abc';
      final r = await api.pedir('POST', '/x', corpo: {'k': 'v'});
      expect(r, equals({'a': 1}));
      final c = f.chamadas.single;
      expect(c.caminho, '/x');
      expect(c.cab['Authorization'], 'Bearer abc');
      expect(c.cab['Content-Type'], 'application/json');
      expect(jsonDecode(c.corpo!), equals({'k': 'v'}));
      expect(api.baseUrl, 'http://srv:3000');
    });

    test('sem token, não manda Authorization; 204 devolve null', () async {
      final f = Falso();
      f.respostas['DELETE /y'] = const RespostaApi(204, '');
      final api = f.api();
      expect(await api.pedir('DELETE', '/y'), isNull);
      expect(f.chamadas.single.cab.containsKey('Authorization'), isFalse);
    });

    test('erro HTTP traz a mensagem do servidor, ou uma padrão', () async {
      final f = Falso();
      f.respostas['GET /a'] = RespostaApi(409, json({'erro': 'Já existe.'}));
      f.respostas['GET /b'] = const RespostaApi(500, '<html>');
      final api = f.api();
      try {
        await api.pedir('GET', '/a');
        fail('deveria lançar');
      } on ErroApi catch (e) {
        expect(e.status, 409);
        expect(e.mensagem, 'Já existe.');
      }
      try {
        await api.pedir('GET', '/b');
        fail('deveria lançar');
      } on ErroApi catch (e) {
        expect(e.status, 500);
        expect(e.mensagem, contains('500'));
      }
    });

    test('sem rede e tempo esgotado viram erros claros (status 0)', () async {
      final f = Falso()..erro = Exception('socket');
      try {
        await f.api().pedir('GET', '/a');
        fail('deveria lançar');
      } on ErroApi catch (e) {
        expect(e.status, 0);
        expect(e.mensagem, contains('conexão'));
      }
      f.erro = TimeoutException('lento');
      try {
        await f.api().pedir('GET', '/a');
        fail('deveria lançar');
      } on ErroApi catch (e) {
        expect(e.mensagem, contains('demorou'));
      }
    });
  });

  group('AuthService com a API', () {
    Map<String, Object> login({bool ia = true}) => {
          'token': 'tok123',
          'usuario': {'nome': 'Ana Souza', 'email': 'ana@a.com'},
          'ia': ia,
        };

    test('entrar guarda token, usuário e se o servidor tem IA', () async {
      final f = Falso();
      f.respostas['POST /auth/login'] = RespostaApi(200, json(login()));
      final api = f.api();
      final auth = AuthService.paraTeste(api);
      expect(await auth.entrar(' ana@a.com ', 'senha-forte-1'), isNull);
      expect(auth.logado, isTrue);
      expect(auth.usuarioAtual!.primeiroNome, 'Ana');
      expect(api.token, 'tok123');
      expect(api.iaNoServidor, isTrue);
      final enviado = jsonDecode(f.chamadas.single.corpo!) as Map;
      expect(enviado['email'], 'ana@a.com');
    });

    test('login recusado devolve a mensagem do servidor e não entra', () async {
      final f = Falso();
      f.respostas['POST /auth/login'] =
          RespostaApi(401, json({'erro': 'E-mail ou senha incorretos.'}));
      final auth = AuthService.paraTeste(f.api());
      expect(await auth.entrar('ana@a.com', 'errada-errada'),
          'E-mail ou senha incorretos.');
      expect(auth.logado, isFalse);
    });

    test('validações do app acontecem antes de chamar a rede', () async {
      final f = Falso();
      final auth = AuthService.paraTeste(f.api());
      expect(await auth.entrar('', ''), isNotNull);
      expect(await auth.entrar('semarroba', 'x'), isNotNull);
      expect(auth.senhaMinima, 8);
      expect(
        await auth.cadastrar(nome: 'Ana', email: 'a@a.com', senha: '1234567'),
        isNotNull,
      );
      expect(f.chamadas, isEmpty);
    });

    test('cadastrar cria a conta mas não entra', () async {
      final f = Falso();
      f.respostas['POST /auth/cadastro'] = RespostaApi(201, json(login()));
      final api = f.api();
      final auth = AuthService.paraTeste(api);
      expect(
        await auth.cadastrar(nome: 'Ana Souza', email: 'ana@a.com', senha: 'senha-forte-1'),
        isNull,
      );
      expect(auth.logado, isFalse);
      expect(api.token, isNull);
    });

    test('cadastro repetido mostra a mensagem do servidor', () async {
      final f = Falso();
      f.respostas['POST /auth/cadastro'] =
          RespostaApi(409, json({'erro': 'Este e-mail já está cadastrado.'}));
      final auth = AuthService.paraTeste(f.api());
      expect(
        await auth.cadastrar(nome: 'Ana Souza', email: 'ana@a.com', senha: 'senha-forte-1'),
        'Este e-mail já está cadastrado.',
      );
    });

    test('sair apaga o token; perfil e senha usam a API', () async {
      final f = Falso();
      f.respostas['POST /auth/login'] = RespostaApi(200, json(login()));
      f.respostas['PATCH /auth/eu'] = RespostaApi(
        200,
        json({'usuario': {'nome': 'Ana Lima', 'email': 'ana@a.com'}}),
      );
      f.respostas['POST /auth/senha'] = const RespostaApi(204, '');
      final api = f.api();
      final auth = AuthService.paraTeste(api);
      await auth.entrar('ana@a.com', 'senha-forte-1');

      expect(await auth.atualizarPerfil(nome: 'Ana Lima', email: 'ana@a.com'), isNull);
      expect(auth.usuarioAtual!.nome, 'Ana Lima');
      expect(jsonDecode(f.chamadas.last.corpo!), equals({'nome': 'Ana Lima'}));

      expect(await auth.alterarSenha(atual: 'senha-forte-1', nova: '123'), isNotNull);
      expect(await auth.alterarSenha(atual: 'senha-forte-1', nova: 'outra-senha-1'), isNull);

      auth.sair();
      expect(api.token, isNull);
      expect(api.iaNoServidor, isFalse);
      expect(auth.logado, isFalse);
    });

    test('excluir conta: se o servidor falha, continua conectado', () async {
      final f = Falso();
      f.respostas['POST /auth/login'] = RespostaApi(200, json(login()));
      f.respostas['DELETE /meus-dados'] =
          RespostaApi(500, json({'erro': 'Erro interno.'}));
      final auth = AuthService.paraTeste(f.api());
      await auth.entrar('ana@a.com', 'senha-forte-1');
      expect(await auth.excluirConta(), 'Erro interno.');
      expect(auth.logado, isTrue);

      f.respostas['DELETE /meus-dados'] = const RespostaApi(204, '');
      expect(await auth.excluirConta(), isNull);
      expect(auth.logado, isFalse);
    });

    test('apagarNoServidor só apaga uma vez (a exclusão não repete)', () async {
      final f = Falso();
      f.respostas['POST /auth/login'] = RespostaApi(200, json(login()));
      f.respostas['DELETE /meus-dados'] = const RespostaApi(204, '');
      final auth = AuthService.paraTeste(f.api());
      await auth.entrar('ana@a.com', 'senha-forte-1');
      expect(await auth.apagarNoServidor(), isNull);
      expect(await auth.excluirConta(), isNull);
      final apagou = f.chamadas.where((c) => c.metodo == 'DELETE').length;
      expect(apagou, 1);
    });
  });

  group('ConteudoRemoto', () {
    final artigo = Artigo(
      id: 'u17000000000000',
      objetivoId: 'ler',
      categoriaId: 'ler_romance',
      titulo: 'Um título de teste',
      autor: 'Ana',
      resumo: 'Resumo do artigo de teste.',
      nivel: 2,
      tags: const ['romance'],
      paragrafos: const ['Um parágrafo bem comprido para o teste do artigo.'],
      doUsuario: true,
      autorEmail: 'ana@a.com',
      criadoEm: '2026-11-11',
    );

    test('lista artigos, comunidades e mensagens, ignorando lixo', () async {
      final f = Falso();
      f.respostas['GET /artigos'] = RespostaApi(
        200,
        json([
          {
            'id': 'u1aaaaaaaaaa', 'objetivo': 'ler', 'categoria': 'ler_romance',
            'titulo': 'Título', 'autor': 'Ana', 'resumo': 'Resumo curto aqui',
            'nivel': 1, 'tags': ['x1'], 'paragrafos': ['Texto.'],
            'usuario': true, 'email': '', 'em': '2026-11-11',
          },
          {'lixo': true},
        ]),
      );
      f.respostas['GET /comunidades'] = RespostaApi(
        200,
        json([
          {
            'id': 'c1aaaaaaaaaa', 'nome': 'Poesia', 'descricao': 'Uma descrição',
            'icone': 'livro', 'categorias': ['ler_romance'], 'regras': ['r'],
            'usuario': true, 'por': '', 'em': '2026-11-11',
          },
        ]),
      );
      f.respostas['GET /comunidades/c1aaaaaaaaaa/posts'] = RespostaApi(
        200,
        json([
          {'id': 'p1', 'comunidade': 'c1aaaaaaaaaa', 'nome': 'Rui', 'email': '', 'texto': 'oi!', 'ms': 5},
        ]),
      );
      final repo = ConteudoRemoto(f.api());
      final a = await repo.listarArtigos();
      expect(a.length, 1);
      expect(a.first.autorEmail, '');
      expect((await repo.listarComunidades()).single.nome, 'Poesia');
      final p = await repo.listarPosts('c1aaaaaaaaaa');
      expect(p.single.autorEmail, '');
      expect(p.single.texto, 'oi!');
    });

    test('salvar e apagar chamam as rotas certas', () async {
      final f = Falso();
      final repo = ConteudoRemoto(f.api());
      await repo.salvarArtigo(artigo);
      await repo.apagarArtigo('u1');
      await repo.apagarComunidade('c1');
      await repo.apagarPost('c1', 'p1');
      await repo.apagarDoAutor('ana@a.com'); // não chama nada
      final rotas = [for (final c in f.chamadas) '${c.metodo} ${c.caminho}'];
      expect(rotas, equals([
        'POST /artigos',
        'DELETE /artigos/u1',
        'DELETE /comunidades/c1',
        'DELETE /comunidades/c1/posts/p1',
      ]));
      final corpo = jsonDecode(f.chamadas.first.corpo!) as Map;
      expect(corpo['id'], 'u17000000000000');
      expect(corpo['categoria'], 'ler_romance');
    });

    test('recusa do servidor vira ErroDeConteudo com a mensagem dele', () async {
      final f = Falso();
      f.respostas['POST /artigos'] =
          RespostaApi(400, json({'erro': 'O título precisa ter de 5 a 100 caracteres.'}));
      final repo = ConteudoRemoto(f.api());
      try {
        await repo.salvarArtigo(artigo);
        fail('deveria lançar');
      } on ErroDeConteudo catch (e) {
        expect(e.mensagem, contains('título'));
      }
    });

    test('o serviço mostra a mensagem do servidor à pessoa', () async {
      final f = Falso();
      f.respostas['POST /comunidades'] =
          RespostaApi(409, json({'erro': 'Já existe uma comunidade com esse nome.'}));
      final s = ConteudoUsuarioService.paraTeste(
        ConteudoRemoto(f.api()),
        quem: () => (email: 'ana@a.com', nome: 'Ana'),
      );
      final r = await s.criarComunidade(
        nome: 'Poesia',
        descricao: 'Uma descrição boa.',
        iconeId: 'livro',
        categoriaIds: {'ler_romance'},
      );
      expect(r.ok, isFalse);
      expect(r.erro, 'Já existe uma comunidade com esse nome.');

      f.erro = Exception('sem rede');
      final r2 = await s.postar('historia', 'Olá, pessoal');
      expect(r2.erro, contains('conexão'));
    });
  });

  group('Gemini pelo servidor (a chave não fica no app)', () {
    ContextoConversa ctx() => const ContextoConversa(
          turnos: [TurnoConversa(daIa: false, texto: 'estou sem o livro')],
          permitiuEnvio: true,
        );

    test('sem chave e sem servidor: indisponível', () {
      final g = GeminiService(chave: '', api: ApiClient(baseUrl: ''));
      expect(g.configurado, isFalse);
    });

    test('com servidor, login e IA no servidor: disponível sem chave', () async {
      final f = Falso();
      f.respostas['POST /ia/gemini'] = RespostaApi(
        200,
        json({
          'candidates': [
            {
              'content': {
                'parts': [
                  {'text': '{"resposta":"Que tal caminhar?","ideias":[]}'},
                ],
              },
            },
          ],
        }),
      );
      final api = f.api()
        ..token = 'tok'
        ..iaNoServidor = true;
      String? urlUsada;
      Map<String, String>? cabUsados;
      final g = GeminiService(
        chave: '',
        api: api,
        enviar: (url, cab, corpo, limite) async {
          urlUsada = url.toString();
          cabUsados = cab;
          return const RespostaHttp(
            200,
            '{"candidates":[{"content":{"parts":[{"text":"{\\"resposta\\":\\"Que tal caminhar?\\",\\"ideias\\":[]}"}]}}]}',
          );
        },
      );
      expect(g.configurado, isTrue);
      final r = await g.conversar(ctx());
      expect(r.ok, isTrue);
      expect(r.resposta!.texto, 'Que tal caminhar?');
      expect(urlUsada, 'http://srv:3000/ia/gemini');
      expect(cabUsados!['Authorization'], 'Bearer tok');
      expect(cabUsados!.containsKey('x-goog-api-key'), isFalse);
    });

    test('servidor sem IA ou sem login: não vale', () {
      final semIa = GeminiService(
        chave: '',
        api: ApiClient(baseUrl: 'http://srv')..token = 't',
      );
      expect(semIa.configurado, isFalse);
      final semLogin = GeminiService(
        chave: '',
        api: ApiClient(baseUrl: 'http://srv')..iaNoServidor = true,
      );
      expect(semLogin.configurado, isFalse);
    });

    test('chave direta continua funcionando e usa o endereço do Google', () async {
      String? urlUsada;
      final g = GeminiService(
        chave: 'k',
        api: ApiClient(baseUrl: ''),
        enviar: (url, cab, corpo, limite) async {
          urlUsada = url.toString();
          expect(cab['x-goog-api-key'], 'k');
          return const RespostaHttp(500, '{}');
        },
      );
      final r = await g.conversar(ctx());
      expect(r.ok, isFalse);
      expect(urlUsada, contains('generativelanguage.googleapis.com'));
      expect(urlUsada, contains('gemini-3.8-flash'));
    });

    test('o corpo pede margem para o pensamento do modelo', () {
      final corpo = GeminiService.montarCorpoConversa(ctx());
      final g = corpo['generationConfig'] as Map;
      expect(g['maxOutputTokens'], greaterThanOrEqualTo(8192));
    });
  });

  group('Autorização da IA (guardada)', () {
    test('começa sem resposta, grava e volta a ler', () async {
      final cfg = ConfigService.instance;
      await cfg.carregar();
      expect(cfg.geminiAutorizado, isNull);
      await cfg.definirGeminiAutorizado(true);
      expect(cfg.geminiAutorizado, isTrue);
      await cfg.carregar();
      expect(cfg.geminiAutorizado, isTrue);
      await cfg.definirGeminiAutorizado(false);
      await cfg.carregar();
      expect(cfg.geminiAutorizado, isFalse);
    });

    test('o chat novo já nasce com a IA ligada só se a pessoa autorizou', () async {
      final cfg = ConfigService.instance;
      SharedPreferences.setMockInitialValues({});
      await cfg.carregar();
      await cfg.definirGeminiAutorizado(false);
      final sem = novoChatIkAi(ocasiao: 'livre');
      expect(sem.usarGemini, isFalse);
      sem.dispose();

      await cfg.definirGeminiAutorizado(true);
      final com = novoChatIkAi(ocasiao: 'livre');
      expect(com.usarGemini, isTrue);
      com.dispose();
      await cfg.definirGeminiAutorizado(false);
    });
  });
}
