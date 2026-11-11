/// Uma comunidade: grupo pequeno por assunto. Dart puro.
///
/// O ícone é guardado como TEXTO ([iconeId]) para que o modelo continue
/// servindo ao banco de dados; quem desenha troca o id pelo ícone.
class Comunidade {
  /// Único em todo o app. Fixas usam ids curtos ('historia'); as criadas por
  /// usuários começam com 'c'.
  final String id;
  final String nome;
  final String descricao;
  final String iconeId;

  /// Categorias que a comunidade reúne (ids de `objetivo_*.dart`).
  final Set<String> categoriaIds;
  final List<String> regras;

  /// true quando foi criada por um usuário (não é uma das fixas do app).
  final bool doUsuario;

  /// E-mail de quem criou (só para conferir a autoria; nunca é exibido).
  final String? criadaPor;

  /// 'aaaa-mm-dd'.
  final String? criadaEm;

  const Comunidade({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.iconeId,
    required this.categoriaIds,
    required this.regras,
    this.doUsuario = false,
    this.criadaPor,
    this.criadaEm,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'nome': nome,
    'descricao': descricao,
    'icone': iconeId,
    'categorias': categoriaIds.toList(),
    'regras': regras,
    'usuario': doUsuario,
    'por': criadaPor,
    'em': criadaEm,
  };

  /// Devolve null se o mapa estiver incompleto ou corrompido (nunca lança).
  static Comunidade? tentarLer(Object? m) {
    if (m is! Map) return null;
    final id = m['id'], nome = m['nome'], desc = m['descricao'];
    final icone = m['icone'], cats = m['categorias'], regras = m['regras'];
    if (id is! String || id.isEmpty) return null;
    if (nome is! String || nome.trim().isEmpty) return null;
    if (desc is! String || icone is! String) return null;
    if (cats is! List || regras is! List) return null;
    final ids = cats.whereType<String>().toSet();
    if (ids.isEmpty) return null;
    final por = m['por'], em = m['em'];
    return Comunidade(
      id: id,
      nome: nome,
      descricao: desc,
      iconeId: icone,
      categoriaIds: ids,
      regras: regras.whereType<String>().toList(),
      doUsuario: m['usuario'] == true,
      criadaPor: por is String ? por : null,
      criadaEm: em is String ? em : null,
    );
  }
}

/// Uma mensagem dentro de uma comunidade. Sem curtidas e sem respostas
/// em cadeia: é um mural simples.
class PostComunidade {
  final String id;
  final String comunidadeId;

  /// Só o primeiro nome (é o que os outros veem).
  final String autorNome;

  /// E-mail de quem escreveu (só para conferir a autoria; nunca é exibido).
  final String autorEmail;
  final String texto;

  /// Milissegundos desde 1970.
  final int criadoMs;

  const PostComunidade({
    required this.id,
    required this.comunidadeId,
    required this.autorNome,
    required this.autorEmail,
    required this.texto,
    required this.criadoMs,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'comunidade': comunidadeId,
    'nome': autorNome,
    'email': autorEmail,
    'texto': texto,
    'ms': criadoMs,
  };

  static PostComunidade? tentarLer(Object? m) {
    if (m is! Map) return null;
    final id = m['id'], com = m['comunidade'], nome = m['nome'];
    final email = m['email'], texto = m['texto'], ms = m['ms'];
    if (id is! String || id.isEmpty) return null;
    if (com is! String || com.isEmpty) return null;
    if (nome is! String || email is! String) return null;
    if (texto is! String || texto.trim().isEmpty) return null;
    if (ms is! int) return null;
    return PostComunidade(
      id: id,
      comunidadeId: com,
      autorNome: nome,
      autorEmail: email,
      texto: texto,
      criadoMs: ms,
    );
  }
}
