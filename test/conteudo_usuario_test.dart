import 'package:flutter_test/flutter_test.dart';
import 'package:ikai/data/artigo.dart';
import 'package:ikai/data/comunidade.dart';
import 'package:ikai/data/conteudo_json.dart';
import 'package:ikai/pages_configurar/objetivo_leitura.dart';
import 'package:ikai/services/artigos_repositorio.dart';
import 'package:ikai/services/conteudo_repositorio.dart';
import 'package:ikai/services/conteudo_usuario.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Repositório que falha, para provar que o app não quebra nem guarda lixo.
class _RepoQuebrado extends ConteudoLocal {
  @override
  Future<void> salvarArtigo(Artigo artigo) async => throw Exception('fora');
  @override
  Future<void> salvarPost(PostComunidade post) async => throw Exception('fora');
}

void main() {
  late QuemEscreve usuario;
  late DateTime agora;
  late ConteudoUsuarioService s;

  final cat = objetivoLeitura.categorias.first;
  const corpoOk =
      'Primeiro parágrafo com texto suficiente para passar na validação do '
      'corpo.\n\nSegundo parágrafo, também com bastante conteúdo para valer.';

  Future<Resultado<Artigo>> publicar(
    ConteudoUsuarioService servico, {
    String titulo = 'Um bom título',
    String resumo = 'Um resumo que explica o artigo.',
    String corpo = corpoOk,
    String tags = '',
    int nivel = 1,
  }) => servico.publicarArtigo(
    objetivoId: objetivoLeitura.id,
    categoriaId: cat.id,
    nivel: nivel,
    titulo: titulo,
    resumo: resumo,
    corpo: corpo,
    tagsTexto: tags,
  );

  ConteudoUsuarioService novo([ConteudoRepositorio? repo]) =>
      ConteudoUsuarioService.paraTeste(
        repo ?? ConteudoLocal(),
        quem: () => usuario,
        agora: () => agora,
      );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Future<void>.delayed(const Duration(milliseconds: 10));
    usuario = (email: 'ana@ex.com', nome: 'Ana');
    agora = DateTime(2026, 11, 4, 10);
    s = novo();
  });

  tearDown(() {
    ArtigosRepositorio.extras = () => const [];
  });

  group('Artigos', () {
    test(
      'publica, preenche autoria e aparece no repositório de artigos',
      () async {
        s.registrarNoFeed();
        final r = await publicar(s, tags: 'Distopia, futuro');
        expect(r.ok, isTrue);
        final a = r.valor!;
        expect(a.doUsuario, isTrue);
        expect(a.autor, 'Ana');
        expect(a.autorEmail, 'ana@ex.com');
        expect(a.criadoEm, '2026-11-04');
        expect(a.tags, ['distopia', 'futuro']);
        expect(a.paragrafos.length, 2);
        expect(ArtigosRepositorio.porId(a.id), isNotNull);
        expect(
          ArtigosRepositorio.doModo(objetivoLeitura.id, {cat.id}).contains(a),
          isTrue,
        );
      },
    );

    test('sem assuntos, usa o nome da categoria', () async {
      final r = await publicar(s);
      expect(r.valor!.tags, [cat.titulo.toLowerCase()]);
    });

    test('remove emojis do que a pessoa escreveu', () async {
      final r = await publicar(s, titulo: 'Título \u{1F600} bonito');
      expect(r.ok, isTrue);
      expect(r.valor!.titulo.contains('\u{1F600}'), isFalse);
    });

    test('recusa campos fora dos limites, com mensagem', () async {
      expect((await publicar(s, titulo: 'abc')).erro, isNotNull);
      expect((await publicar(s, titulo: 'a' * 101)).erro, isNotNull);
      expect((await publicar(s, resumo: 'curto')).erro, isNotNull);
      expect((await publicar(s, corpo: 'pouco texto')).erro, isNotNull);
      expect((await publicar(s, corpo: 'a' * 13000)).erro, isNotNull);
      expect((await publicar(s, tags: 'a, b, c, d, e, f')).erro, isNotNull);
      expect((await publicar(s, tags: 'x')).erro, isNotNull);
      expect((await publicar(s, nivel: 0)).erro, isNotNull);
      expect(s.artigos, isEmpty);
    });

    test('recusa categoria que não pertence ao objetivo', () async {
      final r = await s.publicarArtigo(
        objetivoId: 'ler',
        categoriaId: 'estudar_historia',
        nivel: 1,
        titulo: 'Um bom título',
        resumo: 'Um resumo que explica o artigo.',
        corpo: corpoOk,
      );
      expect(r.ok, isFalse);
    });

    test('sem login não publica', () async {
      usuario = null;
      expect((await publicar(s)).ok, isFalse);
    });

    test('só o autor apaga o próprio artigo', () async {
      final a = (await publicar(s)).valor!;
      usuario = (email: 'beto@ex.com', nome: 'Beto');
      expect(await s.apagarArtigo(a.id), isFalse);
      expect(s.artigos.length, 1);
      usuario = (email: 'ana@ex.com', nome: 'Ana');
      expect(await s.apagarArtigo(a.id), isTrue);
      expect(s.artigos, isEmpty);
    });

    test('meusArtigos separa por autor', () async {
      await publicar(s);
      usuario = (email: 'beto@ex.com', nome: 'Beto');
      await publicar(s, titulo: 'Texto do Beto');
      expect(s.meusArtigos.length, 1);
      expect(s.meusArtigos.first.autor, 'Beto');
      expect(s.artigos.length, 2);
    });

    test('persiste e recarrega por outro serviço', () async {
      await publicar(s);
      final outro = novo();
      await outro.carregar();
      expect(outro.artigos.length, 1);
      expect(outro.artigos.first.titulo, 'Um bom título');
    });

    test('falha do repositório não deixa lixo na memória', () async {
      final q = novo(_RepoQuebrado());
      final r = await publicar(q);
      expect(r.ok, isFalse);
      expect(q.artigos, isEmpty);
    });

    test('ida e volta do JSON e leitura tolerante', () {
      final a = Artigo(
        id: 'u1',
        objetivoId: 'ler',
        categoriaId: cat.id,
        titulo: 'T',
        autor: 'Ana',
        resumo: 'r',
        tags: const ['a'],
        paragrafos: const ['p'],
        nivel: 2,
        doUsuario: true,
        autorEmail: 'ana@ex.com',
        criadoEm: '2026-11-04',
      );
      final b = artigoDeMapa(artigoParaMapa(a))!;
      expect(b.id, 'u1');
      expect(b.nivel, 2);
      expect(b.doUsuario, isTrue);
      expect(b.autorEmail, 'ana@ex.com');
      expect(artigoDeMapa('lixo'), isNull);
      expect(artigoDeMapa({'id': 'x'}), isNull);
      expect(artigoDeMapa({...artigoParaMapa(a), 'nivel': 9}), isNull);
    });
  });

  group('Comunidades', () {
    Future<Resultado<Comunidade>> criar(
      ConteudoUsuarioService servico, {
      String nome = 'Leitores da noite',
      String descricao = 'Quem lê depois do jantar.',
      Set<String>? cats,
      String regras = '',
    }) => servico.criarComunidade(
      nome: nome,
      descricao: descricao,
      iconeId: 'livro',
      categoriaIds: cats ?? {cat.id},
      regrasTexto: regras,
    );

    test('cria com a regra base e as regras da pessoa', () async {
      final r = await criar(s, regras: 'Sem spoiler\n\n  Seja gentil  ');
      expect(r.ok, isTrue);
      final c = r.valor!;
      expect(c.doUsuario, isTrue);
      expect(c.criadaPor, 'ana@ex.com');
      expect(c.regras.first, ConteudoUsuarioService.regraBase);
      expect(c.regras.skip(1).toList(), ['Sem spoiler', 'Seja gentil']);
      expect(s.comunidades.contains(c), isTrue);
      expect(s.euCriei(c), isTrue);
    });

    test(
      'recusa nome repetido (inclusive das fixas, sem acento nem caixa)',
      () async {
        expect((await criar(s)).ok, isTrue);
        expect((await criar(s, nome: 'LEITORES DA NOITE')).ok, isFalse);
        expect((await criar(s, nome: 'historia em pauta')).ok, isFalse);
      },
    );

    test('recusa limites e categorias inválidas', () async {
      expect((await criar(s, nome: 'ab')).ok, isFalse);
      expect((await criar(s, descricao: 'curta')).ok, isFalse);
      expect((await criar(s, cats: <String>{})).ok, isFalse);
      expect((await criar(s, cats: {'nao_existe'})).ok, isFalse);
      final muitas = objetivoLeitura.categorias
          .take(6)
          .map((c) => c.id)
          .toSet();
      expect((await criar(s, cats: muitas)).ok, isFalse);
      expect(
        (await criar(s, regras: List.filled(6, 'regra').join('\n'))).ok,
        isFalse,
      );
    });

    test('só o criador apaga, e os posts vão junto', () async {
      final c = (await criar(s)).valor!;
      await s.postar(c.id, 'Olá, pessoal!');
      usuario = (email: 'beto@ex.com', nome: 'Beto');
      expect(await s.apagarComunidade(c.id), isFalse);
      usuario = (email: 'ana@ex.com', nome: 'Ana');
      expect(await s.apagarComunidade(c.id), isTrue);
      expect(s.comunidades.any((x) => x.id == c.id), isFalse);
      expect(await ConteudoLocal().listarPosts(c.id), isEmpty);
    });

    test('comunidades fixas não podem ser apagadas', () async {
      expect(await s.apagarComunidade('historia'), isFalse);
      expect(s.comunidades.any((c) => c.id == 'historia'), isTrue);
    });
  });

  group('Mensagens', () {
    test('posta, lista (mais nova primeiro) e persiste', () async {
      await s.postar('historia', 'Primeira mensagem');
      agora = agora.add(const Duration(minutes: 5));
      await s.postar('historia', 'Segunda mensagem');
      final lista = await novo().postsDe('historia');
      expect(lista.map((p) => p.texto).toList(), [
        'Segunda mensagem',
        'Primeira mensagem',
      ]);
      expect(lista.first.autorNome, 'Ana');
    });

    test('recusa vazio, curto e longo; comunidade inexistente', () async {
      expect((await s.postar('historia', '  ')).ok, isFalse);
      expect((await s.postar('historia', 'oi')).ok, isFalse);
      expect((await s.postar('historia', 'a' * 501)).ok, isFalse);
      expect((await s.postar('nao_existe', 'mensagem ok')).ok, isFalse);
    });

    test('remove emojis da mensagem', () async {
      final r = await s.postar('historia', 'Gostei \u{1F44D} muito');
      expect(r.valor!.texto.contains('\u{1F44D}'), isFalse);
    });

    test('autor ou criador da comunidade apagam; outros não', () async {
      final c = (await s.criarComunidade(
        nome: 'Clube do chá',
        descricao: 'Conversas tranquilas.',
        iconeId: 'conversa',
        categoriaIds: {cat.id},
      )).valor!;
      usuario = (email: 'beto@ex.com', nome: 'Beto');
      final p = (await s.postar(c.id, 'Mensagem do Beto')).valor!;

      usuario = (email: 'caio@ex.com', nome: 'Caio');
      expect(await s.apagarPost(c.id, p.id), isFalse);

      usuario = (email: 'ana@ex.com', nome: 'Ana'); // criadora
      expect(await s.apagarPost(c.id, p.id), isTrue);
      expect(s.postsEmMemoria(c.id), isEmpty);

      usuario = (email: 'beto@ex.com', nome: 'Beto');
      final p2 = (await s.postar(c.id, 'Outra do Beto')).valor!;
      expect(await s.apagarPost(c.id, p2.id), isTrue); // o próprio autor
    });

    test('falha do repositório não deixa a mensagem na memória', () async {
      final q = novo(_RepoQuebrado());
      final r = await q.postar('historia', 'Mensagem');
      expect(r.ok, isFalse);
      expect(q.postsEmMemoria('historia'), isEmpty);
    });

    test('modelo de post tolera lixo', () {
      expect(PostComunidade.tentarLer('x'), isNull);
      expect(PostComunidade.tentarLer({'id': 'p'}), isNull);
      expect(Comunidade.tentarLer({'id': 'c'}), isNull);
    });
  });

  group('Conta', () {
    test('excluir a conta apaga artigos, comunidades e posts dela', () async {
      await publicar(s);
      final c = (await s.criarComunidade(
        nome: 'Minha roda',
        descricao: 'Para conversar sobre livros.',
        iconeId: 'livro',
        categoriaIds: {cat.id},
      )).valor!;
      await s.postar(c.id, 'Mensagem na minha roda');
      await s.postar('historia', 'Mensagem em outra comunidade');

      usuario = (email: 'beto@ex.com', nome: 'Beto');
      await s.postar('historia', 'Mensagem do Beto');

      await s.apagarDaConta('ana@ex.com');

      final outro = novo();
      await outro.carregar();
      expect(outro.artigos, isEmpty);
      expect(outro.comunidades.any((x) => x.id == c.id), isFalse);
      final posts = await outro.postsDe('historia');
      expect(posts.map((p) => p.autorNome).toList(), ['Beto']);
    });

    test('limpar esquece a memória, mas não o gravado', () async {
      await publicar(s);
      s.limpar();
      expect(s.artigos, isEmpty);
      expect(s.carregado, isFalse);
      await s.carregar();
      expect(s.artigos.length, 1);
    });
  });
}
