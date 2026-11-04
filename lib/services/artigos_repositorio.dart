import '../core/texto.dart';
import '../data/artigo.dart';
import '../data/artigos_dados.dart';

/// Quantidade FIXA de conteúdos no feed de uma sessão.
/// O feed é finito: ao chegar nesse número, o usuário vê o fim.
const int conteudosPorSessao = 8;

/// Acesso aos artigos. Hoje lê de `artigos_dados.dart`; quando o banco de
/// dados existir, só este arquivo precisa mudar. Dart puro.
class ArtigosRepositorio {
  ArtigosRepositorio._();

  static List<Artigo> get todos => artigosDados;

  static Artigo? porId(String id) {
    for (final a in todos) {
      if (a.id == id) return a;
    }
    return null;
  }

  /// Artigos que respeitam o modo da sessão (objetivo + categoria).
  /// Conteúdo fora do modo NUNCA aparece aqui.
  static List<Artigo> doModo(String? objetivoId, String? categoriaId) {
    if (objetivoId == null || categoriaId == null) return const [];
    return todos
        .where(
            (a) => a.objetivoId == objetivoId && a.categoriaId == categoriaId)
        .toList();
  }

  /// Feed finito da sessão: no máximo [conteudosPorSessao] artigos.
  static List<Artigo> feedDaSessao(String? objetivoId, String? categoriaId) {
    final lista = doModo(objetivoId, categoriaId);
    return lista.length <= conteudosPorSessao
        ? lista
        : lista.sublist(0, conteudosPorSessao);
  }

  /// Artigos de várias categorias (usado pelas comunidades, onde os filtros
  /// pessoais ficam suspensos de forma explícita).
  static List<Artigo> dasCategorias(Set<String> categoriaIds) =>
      todos.where((a) => categoriaIds.contains(a.categoriaId)).toList();

  /// Busca por título, autor ou assunto (ignora acentos e maiúsculas).
  /// Uma consulta vazia devolve a própria [base].
  static List<Artigo> buscar(String consulta, List<Artigo> base) {
    final termos = normalizarTexto(consulta)
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();
    if (termos.isEmpty) return base;

    bool combina(Artigo a) {
      final alvo = normalizarTexto(
        '${a.titulo} ${a.autor} ${a.tags.join(' ')}',
      );
      return termos.every(alvo.contains);
    }

    return base.where(combina).toList();
  }

  /// Assuntos (tags) existentes em [base], sem repetição, em ordem alfabética.
  static List<String> tagsDe(List<Artigo> base) {
    final set = <String>{};
    for (final a in base) {
      set.addAll(a.tags);
    }
    final lista = set.toList()..sort();
    return lista;
  }

  static List<Artigo> comTag(String tag, List<Artigo> base) =>
      base.where((a) => a.tags.contains(tag)).toList();
}
