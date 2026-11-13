import 'package:flutter/foundation.dart';

import '../core/sem_emoji.dart';
import '../core/texto.dart';
import '../core/uso_diario.dart';
import '../data/artigo.dart';
import '../data/comunidade.dart';
import '../data/comunidades_dados.dart';
import '../pages_configurar/controle_objetivo.dart';
import 'api_client.dart';
import 'artigos_repositorio.dart';
import 'auth_service.dart';
import 'conteudo_remoto.dart';
import 'conteudo_repositorio.dart';

/// Resultado de uma ação que pode ser recusada: ou traz o [valor], ou o
/// [erro] em português para mostrar à pessoa.
class Resultado<T> {
  final T? valor;
  final String? erro;

  const Resultado.ok(T this.valor) : erro = null;
  const Resultado.erro(String this.erro) : valor = null;

  bool get ok => erro == null;
}

/// Quem está escrevendo (o primeiro nome é o que os outros veem).
typedef QuemEscreve = ({String email, String nome})?;

/// Artigos, comunidades e posts criados pelos usuários.
///
/// Conversa com um [ConteudoRepositorio]: hoje o local, depois o banco de
/// dados. As regras de validação ficam AQUI (e o servidor deve repeti-las:
/// nunca confie só no app).
///
/// Enquanto o repositório for o local, o conteúdo existe só neste aparelho.
class ConteudoUsuarioService extends ChangeNotifier {
  ConteudoUsuarioService._(this._repo)
    : _quem = _quemDaConta,
      _agora = DateTime.now;

  @visibleForTesting
  ConteudoUsuarioService.paraTeste(
    this._repo, {
    QuemEscreve Function()? quem,
    DateTime Function()? agora,
  }) : _quem = quem ?? _quemDaConta,
       _agora = agora ?? DateTime.now;

  /// Com `API_URL` (veja api_client.dart) o conteúdo mora no banco de dados;
  /// sem ela, só neste aparelho.
  static final ConteudoUsuarioService instance = ConteudoUsuarioService._(
    ApiClient.instance.ativo
        ? ConteudoRemoto(ApiClient.instance)
        : ConteudoLocal(),
  );

  /// A mensagem do servidor, se houver; senão, a padrão.
  static String _motivo(Object e, String padrao) =>
      e is ErroDeConteudo ? e.mensagem : padrao;

  static QuemEscreve _quemDaConta() {
    final u = AuthService.instance.usuarioAtual;
    if (u == null) return null;
    return (email: u.email, nome: u.primeiroNome);
  }

  // ---------- Limites (a interface usa os mesmos números) ----------
  static const int tituloMin = 5, tituloMax = 100;
  static const int resumoMin = 10, resumoMax = 200;
  static const int corpoMin = 80, corpoMax = 12000, paragrafoMax = 2000;
  static const int maxTags = 5, tagMin = 2, tagMax = 24;
  static const int nomeMin = 3, nomeMax = 40;
  static const int descricaoMin = 10, descricaoMax = 140;
  static const int maxCategoriasComunidade = 5;
  static const int maxRegras = 5, regraMax = 120;
  static const int postMin = 3, postMax = 500;

  /// Regra que toda comunidade criada ganha (as outras são da pessoa).
  static const String regraBase = 'Respeite as pessoas; debata ideias.';

  final ConteudoRepositorio _repo;
  final QuemEscreve Function() _quem;
  final DateTime Function() _agora;

  final List<Artigo> _artigos = [];
  final List<Comunidade> _comunidades = [];
  final Map<String, List<PostComunidade>> _posts = {};
  int _contador = 0;
  bool _carregado = false;

  bool get carregado => _carregado;

  /// Liga os artigos dos usuários ao feed e à busca.
  void registrarNoFeed() {
    ArtigosRepositorio.extras = () => List.unmodifiable(_artigos);
  }

  List<Artigo> get artigos => List.unmodifiable(_artigos);

  List<Artigo> get meusArtigos {
    final e = _quem()?.email.toLowerCase();
    if (e == null) return const [];
    return [
      for (final a in _artigos)
        if ((a.autorEmail ?? '').toLowerCase() == e) a,
    ];
  }

  /// As fixas do app e as criadas por usuários.
  List<Comunidade> get comunidades => [...comunidadesFixas, ..._comunidades];

  bool euCriei(Comunidade c) =>
      c.doUsuario &&
      _quem() != null &&
      (c.criadaPor ?? '').toLowerCase() == _quem()!.email.toLowerCase();

  bool euEscrevi(PostComunidade p) =>
      _quem() != null &&
      p.autorEmail.toLowerCase() == _quem()!.email.toLowerCase();

  Future<void> carregar() async {
    try {
      final a = await _repo.listarArtigos();
      final c = await _repo.listarComunidades();
      _artigos
        ..clear()
        ..addAll(a);
      _comunidades
        ..clear()
        ..addAll(c);
    } catch (_) {
      // Sem repositório (ou sem rede, no futuro), o app segue só com o fixo.
    }
    _carregado = true;
    registrarNoFeed();
    notifyListeners();
  }

  /// Esquece a memória (sair da conta). O gravado permanece.
  void limpar() {
    _artigos.clear();
    _comunidades.clear();
    _posts.clear();
    _carregado = false;
    notifyListeners();
  }

  /// Exclusão de conta: apaga tudo o que a pessoa escreveu.
  Future<void> apagarDaConta(String email) async {
    try {
      await _repo.apagarDoAutor(email);
    } catch (_) {}
    limpar();
  }

  String _novoId(String prefixo) =>
      '$prefixo${_agora().millisecondsSinceEpoch}${_contador++}';

  static String _limpo(String bruto) =>
      removerEmojis(bruto).replaceAll(RegExp(r'[ \t]+'), ' ').trim();

  // ---------- Artigos ----------

  /// Parágrafos separados por linha em branco.
  static List<String> paragrafosDe(String corpo) => [
    for (final p in removerEmojis(corpo).split(RegExp(r'\n\s*\n')))
      if (p.replaceAll(RegExp(r'\s+'), ' ').trim().isNotEmpty)
        p.replaceAll(RegExp(r'\s+'), ' ').trim(),
  ];

  /// Assuntos separados por vírgula ou ponto e vírgula, em minúsculas e sem
  /// repetição.
  static List<String> tagsDe(String texto) {
    final vistos = <String>{};
    final saida = <String>[];
    for (final bruto in texto.split(RegExp(r'[,;]'))) {
      final t = _limpo(bruto).toLowerCase();
      if (t.isEmpty || !vistos.add(t)) continue;
      saida.add(t);
    }
    return saida;
  }

  Future<Resultado<Artigo>> publicarArtigo({
    required String objetivoId,
    required String categoriaId,
    required int nivel,
    required String titulo,
    required String resumo,
    required String corpo,
    String tagsTexto = '',
  }) async {
    final quem = _quem();
    if (quem == null) return const Resultado.erro('Entre na sua conta.');

    final objetivo = buscarObjetivo(objetivoId);
    final categoria = objetivo?.buscarCategoria(categoriaId);
    if (objetivo == null || categoria == null) {
      return const Resultado.erro('Escolha o objetivo e a categoria.');
    }
    if (nivel < Artigo.nivelMinimo || nivel > Artigo.nivelMaximo) {
      return const Resultado.erro('Escolha o nível de dificuldade.');
    }

    final t = _limpo(titulo);
    if (t.length < tituloMin || t.length > tituloMax) {
      return const Resultado.erro(
        'O título precisa ter de $tituloMin a $tituloMax caracteres.',
      );
    }
    final r = _limpo(resumo);
    if (r.length < resumoMin || r.length > resumoMax) {
      return const Resultado.erro(
        'O resumo precisa ter de $resumoMin a $resumoMax caracteres.',
      );
    }
    final pars = paragrafosDe(corpo);
    final total = pars.fold<int>(0, (a, p) => a + p.length);
    if (total < corpoMin) {
      return const Resultado.erro(
        'O texto está curto: escreva pelo menos $corpoMin caracteres.',
      );
    }
    if (total > corpoMax || pars.any((p) => p.length > paragrafoMax)) {
      return const Resultado.erro(
        'O texto está longo demais. Separe em parágrafos (linha em branco) '
        'de até $paragrafoMax caracteres, no máximo $corpoMax no total.',
      );
    }

    var tags = tagsDe(tagsTexto);
    if (tags.any((x) => x.length < tagMin || x.length > tagMax)) {
      return const Resultado.erro(
        'Cada assunto precisa ter de $tagMin a $tagMax caracteres.',
      );
    }
    if (tags.length > maxTags) {
      return const Resultado.erro('Use no máximo $maxTags assuntos.');
    }
    if (tags.isEmpty) tags = [categoria.titulo.toLowerCase()];

    final artigo = Artigo(
      id: _novoId('u'),
      objetivoId: objetivoId,
      categoriaId: categoriaId,
      titulo: t,
      autor: quem.nome.isEmpty ? 'Leitor' : quem.nome,
      resumo: r,
      nivel: nivel,
      tags: tags,
      paragrafos: pars,
      doUsuario: true,
      autorEmail: quem.email,
      criadoEm: chaveDoDia(_agora()),
    );
    try {
      await _repo.salvarArtigo(artigo);
    } catch (e) {
      return Resultado.erro(
        _motivo(e, 'Não foi possível salvar agora. Tente de novo.'),
      );
    }
    _artigos.add(artigo);
    notifyListeners();
    return Resultado.ok(artigo);
  }

  /// Só quem escreveu pode apagar.
  Future<bool> apagarArtigo(String id) async {
    final i = _artigos.indexWhere((a) => a.id == id);
    if (i < 0) return false;
    final e = _quem()?.email.toLowerCase();
    if (e == null || (_artigos[i].autorEmail ?? '').toLowerCase() != e) {
      return false;
    }
    try {
      await _repo.apagarArtigo(id);
    } catch (_) {
      return false;
    }
    _artigos.removeAt(i);
    notifyListeners();
    return true;
  }

  // ---------- Comunidades ----------

  static List<String> regrasDe(String texto) => [
    for (final l in texto.split('\n'))
      if (_limpo(l).isNotEmpty) _limpo(l),
  ];

  Future<Resultado<Comunidade>> criarComunidade({
    required String nome,
    required String descricao,
    required String iconeId,
    required Set<String> categoriaIds,
    String regrasTexto = '',
  }) async {
    final quem = _quem();
    if (quem == null) return const Resultado.erro('Entre na sua conta.');

    final n = _limpo(nome);
    if (n.length < nomeMin || n.length > nomeMax) {
      return const Resultado.erro(
        'O nome precisa ter de $nomeMin a $nomeMax caracteres.',
      );
    }
    final chave = normalizarTexto(n);
    if (comunidades.any((c) => normalizarTexto(c.nome) == chave)) {
      return const Resultado.erro('Já existe uma comunidade com esse nome.');
    }
    final d = _limpo(descricao);
    if (d.length < descricaoMin || d.length > descricaoMax) {
      return const Resultado.erro(
        'A descrição precisa ter de $descricaoMin a $descricaoMax '
        'caracteres.',
      );
    }
    if (categoriaIds.isEmpty || categoriaIds.length > maxCategoriasComunidade) {
      return const Resultado.erro(
        'Escolha de 1 a $maxCategoriasComunidade categorias.',
      );
    }
    final validas = {
      for (final o in todosOsObjetivos)
        for (final c in o.categorias) c.id,
    };
    if (!categoriaIds.every(validas.contains)) {
      return const Resultado.erro('Há uma categoria inválida.');
    }

    final regras = regrasDe(regrasTexto);
    if (regras.length > maxRegras || regras.any((r) => r.length > regraMax)) {
      return const Resultado.erro(
        'Use no máximo $maxRegras regras, de até $regraMax caracteres.',
      );
    }

    final c = Comunidade(
      id: _novoId('c'),
      nome: n,
      descricao: d,
      iconeId: iconeId,
      categoriaIds: categoriaIds,
      regras: [regraBase, ...regras],
      doUsuario: true,
      criadaPor: quem.email,
      criadaEm: chaveDoDia(_agora()),
    );
    try {
      await _repo.salvarComunidade(c);
    } catch (e) {
      return Resultado.erro(
        _motivo(e, 'Não foi possível salvar agora. Tente de novo.'),
      );
    }
    _comunidades.add(c);
    notifyListeners();
    return Resultado.ok(c);
  }

  /// Só quem criou pode apagar (e os posts vão junto).
  Future<bool> apagarComunidade(String id) async {
    final i = _comunidades.indexWhere((c) => c.id == id);
    if (i < 0 || !euCriei(_comunidades[i])) return false;
    try {
      await _repo.apagarComunidade(id);
    } catch (_) {
      return false;
    }
    _comunidades.removeAt(i);
    _posts.remove(id);
    notifyListeners();
    return true;
  }

  // ---------- Posts ----------

  Future<List<PostComunidade>> postsDe(String comunidadeId) async {
    try {
      final l = await _repo.listarPosts(comunidadeId);
      _posts[comunidadeId] = List.of(l);
    } catch (_) {
      _posts.putIfAbsent(comunidadeId, () => []);
    }
    return List.unmodifiable(_posts[comunidadeId]!);
  }

  /// Posts já carregados (para a tela atualizar sem nova leitura).
  List<PostComunidade> postsEmMemoria(String comunidadeId) =>
      List.unmodifiable(_posts[comunidadeId] ?? const []);

  Future<Resultado<PostComunidade>> postar(
    String comunidadeId,
    String texto,
  ) async {
    final quem = _quem();
    if (quem == null) return const Resultado.erro('Entre na sua conta.');
    if (!comunidades.any((c) => c.id == comunidadeId)) {
      return const Resultado.erro('Comunidade não encontrada.');
    }
    final t = removerEmojis(texto).replaceAll(RegExp(r'[ \t]+'), ' ').trim();
    if (t.length < postMin || t.length > postMax) {
      return const Resultado.erro(
        'A mensagem precisa ter de $postMin a $postMax caracteres.',
      );
    }
    final p = PostComunidade(
      id: _novoId('p'),
      comunidadeId: comunidadeId,
      autorNome: quem.nome.isEmpty ? 'Leitor' : quem.nome,
      autorEmail: quem.email,
      texto: t,
      criadoMs: _agora().millisecondsSinceEpoch,
    );
    try {
      await _repo.salvarPost(p);
    } catch (e) {
      return Resultado.erro(
        _motivo(e, 'Não foi possível enviar agora. Tente de novo.'),
      );
    }
    (_posts[comunidadeId] ??= []).insert(0, p);
    notifyListeners();
    return Resultado.ok(p);
  }

  /// Só quem escreveu (ou quem criou a comunidade) pode apagar o post.
  Future<bool> apagarPost(String comunidadeId, String postId) async {
    final lista = _posts[comunidadeId];
    if (lista == null) return false;
    final i = lista.indexWhere((p) => p.id == postId);
    if (i < 0) return false;
    final dono = comunidades.any((c) => c.id == comunidadeId && euCriei(c));
    if (!euEscrevi(lista[i]) && !dono) return false;
    try {
      await _repo.apagarPost(comunidadeId, postId);
    } catch (_) {
      return false;
    }
    lista.removeAt(i);
    notifyListeners();
    return true;
  }
}
