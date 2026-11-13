import 'artigo.dart';

/// Conversão de [Artigo] de e para mapas simples (JSON). Serve ao
/// armazenamento local de hoje e ao banco de dados de amanhã. Dart puro.
Map<String, dynamic> artigoParaMapa(Artigo a) => {
  'id': a.id,
  'objetivo': a.objetivoId,
  'categoria': a.categoriaId,
  'titulo': a.titulo,
  'autor': a.autor,
  'resumo': a.resumo,
  'nivel': a.nivel,
  'tags': a.tags,
  'paragrafos': a.paragrafos,
  'usuario': a.doUsuario,
  'email': a.autorEmail,
  'em': a.criadoEm,
};

/// Devolve null se o mapa estiver incompleto ou corrompido (nunca lança).
Artigo? artigoDeMapa(Object? m) {
  if (m is! Map) return null;
  final id = m['id'], obj = m['objetivo'], cat = m['categoria'];
  final titulo = m['titulo'], autor = m['autor'], resumo = m['resumo'];
  final nivel = m['nivel'], tags = m['tags'], pars = m['paragrafos'];
  if (id is! String || id.isEmpty) return null;
  if (obj is! String || cat is! String) return null;
  if (titulo is! String || titulo.trim().isEmpty) return null;
  if (autor is! String || resumo is! String) return null;
  if (nivel is! int ||
      nivel < Artigo.nivelMinimo ||
      nivel > Artigo.nivelMaximo) {
    return null;
  }
  if (tags is! List || pars is! List) return null;
  final paragrafos = pars.whereType<String>().toList();
  if (paragrafos.isEmpty) return null;
  final email = m['email'], em = m['em'];
  return Artigo(
    id: id,
    objetivoId: obj,
    categoriaId: cat,
    titulo: titulo,
    autor: autor,
    resumo: resumo,
    nivel: nivel,
    tags: tags.whereType<String>().toList(),
    paragrafos: paragrafos,
    doUsuario: m['usuario'] == true,
    autorEmail: email is String ? email : null,
    criadoEm: em is String ? em : null,
  );
}
