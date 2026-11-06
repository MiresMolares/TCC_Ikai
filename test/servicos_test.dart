import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ikai/data/artigos_dados.dart';
import 'package:ikai/services/auth_service.dart';
import 'package:ikai/services/biblioteca_service.dart';
import 'package:ikai/services/progresso_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('AuthService (contas de teste em memória)', () {
    final auth = AuthService.instance;
    setUp(() => auth.sair());

    test('conta de teste entra; senha errada não entra', () {
      expect(auth.entrar('adm@email.com', 'errada'), isNotNull);
      expect(auth.logado, isFalse);
      expect(auth.entrar('adm@email.com', '1234'), isNull);
      expect(auth.logado, isTrue);
      expect(auth.usuarioAtual!.primeiroNome, equals('Administrador'));
    });

    test('e-mail ignora maiúsculas e espaços; campos vazios são recusados',
        () {
      expect(auth.entrar('  ADM@Email.com ', '1234'), isNull);
      auth.sair();
      expect(auth.entrar('', ''), isNotNull);
      expect(auth.entrar('semarroba', '1234'), isNotNull);
    });

    test('cadastro valida dados e impede e-mail repetido', () {
      expect(
        auth.cadastrar(nome: 'A', email: 'a@a.com', senha: '1234'),
        isNotNull,
      );
      expect(
        auth.cadastrar(nome: 'Ana Souza', email: 'invalido', senha: '1234'),
        isNotNull,
      );
      expect(
        auth.cadastrar(nome: 'Ana Souza', email: 'ana@a.com', senha: '12'),
        isNotNull,
      );
      expect(
        auth.cadastrar(nome: 'Ana Souza', email: 'ana@a.com', senha: 'abcd'),
        isNull,
      );
      expect(
        auth.cadastrar(nome: 'Outra', email: 'ANA@a.com', senha: 'abcd'),
        isNotNull,
      );
      expect(auth.entrar('ana@a.com', 'abcd'), isNull);
      expect(auth.usuarioAtual!.primeiroNome, equals('Ana'));
    });

    test('atualizar perfil, trocar senha e excluir conta', () {
      auth.cadastrar(nome: 'Bia Lima', email: 'bia@a.com', senha: 'abcd');
      auth.entrar('bia@a.com', 'abcd');

      expect(auth.atualizarPerfil(nome: 'B', email: 'bia@a.com'), isNotNull);
      expect(
        auth.atualizarPerfil(nome: 'Bia Souza', email: 'adm@email.com'),
        isNotNull, // e-mail de outra conta
      );
      expect(
        auth.atualizarPerfil(nome: 'Bia Souza', email: 'bia2@a.com'),
        isNull,
      );
      expect(auth.usuarioAtual!.email, equals('bia2@a.com'));

      expect(auth.alterarSenha(atual: 'x', nova: 'novasenha'), isNotNull);
      expect(auth.alterarSenha(atual: 'abcd', nova: '1'), isNotNull);
      expect(auth.alterarSenha(atual: 'abcd', nova: 'novasenha'), isNull);

      auth.excluirConta();
      expect(auth.logado, isFalse);
      expect(auth.entrar('bia2@a.com', 'novasenha'), isNotNull);
    });
  });

  group('BibliotecaService', () {
    final lib = BibliotecaService.instance;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await lib.carregarPara('a@a.com');
    });

    test('começa com a pasta padrão; todo conteúdo pertence a uma pasta',
        () async {
      expect(lib.pastas.length, equals(1));
      expect(lib.pastas.first.nome, equals('Salvos'));
      await lib.alternar(lib.pastas.first.id, 'a001');
      expect(lib.estaSalvo('a001'), isTrue);
    });

    test('um conteúdo pode estar em várias pastas', () async {
      await lib.criarPasta('Estudos');
      final p1 = lib.pastas[0].id;
      final p2 = lib.pastas[1].id;
      await lib.alternar(p1, 'a001');
      await lib.alternar(p2, 'a001');
      expect(lib.estaNaPasta(p1, 'a001'), isTrue);
      expect(lib.estaNaPasta(p2, 'a001'), isTrue);
      await lib.alternar(p1, 'a001'); // tira de uma
      expect(lib.estaNaPasta(p1, 'a001'), isFalse);
      expect(lib.estaSalvo('a001'), isTrue); // continua na outra
    });

    test('valida nomes: vazio, repetido (sem diferenciar caixa), muito longo',
        () async {
      expect(await lib.criarPasta('  '), isNotNull);
      expect(await lib.criarPasta('salvos'), isNotNull);
      expect(await lib.criarPasta('x' * 41), isNotNull);
      expect(await lib.criarPasta('Leituras'), isNull);
      expect(lib.pastas.length, equals(2));
    });

    test('renomear e excluir pasta', () async {
      await lib.criarPasta('Temp');
      final id = lib.pastas.last.id;
      expect(await lib.renomear(id, 'Salvos'), isNotNull); // repetido
      expect(await lib.renomear(id, 'Provas'), isNull);
      expect(lib.pastaPorId(id)!.nome, equals('Provas'));
      await lib.alternar(id, 'a002');
      await lib.excluir(id);
      expect(lib.pastaPorId(id), isNull);
      expect(lib.estaSalvo('a002'), isFalse);
    });

    test('persiste e recarrega os mesmos dados', () async {
      await lib.criarPasta('Provas');
      await lib.alternar(lib.pastas.last.id, 'a003');
      await lib.carregarPara('a@a.com');
      expect(lib.pastas.map((p) => p.nome), contains('Provas'));
      expect(lib.estaSalvo('a003'), isTrue);
    });

    test('cada usuário tem a própria biblioteca', () async {
      await lib.alternar(lib.pastas.first.id, 'a004');
      await lib.carregarPara('b@b.com');
      expect(lib.estaSalvo('a004'), isFalse);
      await lib.carregarPara('a@a.com');
      expect(lib.estaSalvo('a004'), isTrue);
    });

    test('limpar remove tudo da memória; exportar gera JSON válido', () async {
      await lib.alternar(lib.pastas.first.id, 'a005');
      final json = jsonDecode(lib.exportarJson()) as Map;
      expect((json['pastas'] as List).isNotEmpty, isTrue);
      lib.limpar();
      expect(lib.pastas, isEmpty);
    });
  });

  group('ProgressoService', () {
    final prog = ProgressoService.instance;
    late DateTime hoje;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      hoje = DateTime(2026, 11, 4, 9);
      prog.agora = () => hoje;
      await prog.carregarPara('a@a.com');
    });

    test('contar leitura só na primeira vez', () async {
      expect(await prog.registrarLeitura(artigosDados.first), isTrue);
      expect(await prog.registrarLeitura(artigosDados.first), isFalse);
      expect(prog.totalLidos, equals(1));
      expect(prog.foiLido(artigosDados.first.id), isTrue);
    });

    test('sessões e tempo acumulam, sem aceitar tempo negativo', () async {
      await prog.registrarSessao(600);
      await prog.registrarSessao(-5);
      expect(prog.sessoesConcluidas, equals(2));
      expect(prog.segundosEmSessao, equals(600));
    });

    test('ofensiva conta dias seguidos e perde ao pular um dia', () {
      final dias = {'2026-11-02', '2026-11-03', '2026-11-04'};
      expect(
        ProgressoService.calcularOfensiva(dias, DateTime(2026, 11, 4)),
        equals(3),
      );
      // Hoje ainda sem atividade: continua valendo a partir de ontem.
      expect(
        ProgressoService.calcularOfensiva(
          {'2026-11-02', '2026-11-03'},
          DateTime(2026, 11, 4),
        ),
        equals(2),
      );
      // Pulou um dia: zera.
      expect(
        ProgressoService.calcularOfensiva(
          {'2026-11-01'},
          DateTime(2026, 11, 4),
        ),
        equals(0),
      );
      // Virada de mês e de ano.
      expect(
        ProgressoService.calcularOfensiva(
          {'2026-12-31', '2027-01-01'},
          DateTime(2027, 1, 1),
        ),
        equals(2),
      );
    });

    test('conquistas dependem só dos números do próprio usuário', () async {
      var c = prog.conquistas(totalSalvos: 0);
      expect(c.where((x) => x.desbloqueada), isEmpty);

      await prog.registrarLeitura(artigosDados.first);
      await prog.registrarSessao(60);
      c = prog.conquistas(totalSalvos: 1);
      final ids = c.where((x) => x.desbloqueada).map((x) => x.id).toList();
      expect(ids, contains('primeira_leitura'));
      expect(ids, contains('tempo_bem_escolhido'));
      expect(ids, contains('organizador'));
      expect(ids.contains('leitor_curioso'), isFalse);
    });

    test('persiste por usuário e limpa ao sair', () async {
      await prog.registrarLeitura(artigosDados.first);
      await prog.carregarPara('a@a.com');
      expect(prog.totalLidos, equals(1));
      await prog.carregarPara('b@b.com');
      expect(prog.totalLidos, equals(0));
      prog.limpar();
      expect(prog.totalLidos, equals(0));
    });
  });
}
