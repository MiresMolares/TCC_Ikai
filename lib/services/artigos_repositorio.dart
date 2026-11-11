import '../core/texto.dart';
import '../data/artigo.dart';
import '../data/artigos_dados.dart';

/// Quantidade FIXA de conteúdos no feed. Escolher mais categorias NÃO
/// aumenta esse número: o feed é finito por escolha.
const int conteudosPorSessao = 8;

/// Acesso aos artigos. Hoje lê de `artigos_dados.dart` (mais os escritos por
/// usuários); quando o banco de dados existir, só este arquivo precisa mudar. Dart puro.
class ArtigosRepositorio {
  ArtigosRepositorio._();

  /// Fonte extra de artigos (os escritos por usuários). Quem cuida deles
  /// (ConteudoUsuarioService) registra aqui; o acervo do app continua em
  /// `artigosDados`. Com o banco de dados, basta trocar esta fonte.
  static List<Artigo> Function() extras = () => const [];

  static List<Artigo> get todos => [...artigosDados, ...extras()];

  static Artigo? porId(String id) {
    for (final a in todos) {
      if (a.id == id) return a;
    }
    return null;
  }

  /// Artigos que respeitam a escolha do dia (objetivo + UMA OU MAIS
  /// categorias). Conteúdo fora da escolha NUNCA aparece aqui.
  static List<Artigo> doModo(String? objetivoId, Set<String> categoriaIds) {
    if (objetivoId == null || categoriaIds.isEmpty) return const [];
    return todos
        .where((a) =>
            a.objetivoId == objetivoId && categoriaIds.contains(a.categoriaId))
        .toList();
  }

  /// Filtra por nível de dificuldade. 0 (ou valor inválido) devolve [base].
  static List<Artigo> doNivel(List<Artigo> base, int nivel) {
    if (nivel < Artigo.nivelMinimo || nivel > Artigo.nivelMaximo) return base;
    return base.where((a) => a.nivel == nivel).toList();
  }

  /// Intercala as categorias (um de cada, em rodízio), para que nenhuma
  /// domine o feed quando a pessoa escolhe várias. Com uma só categoria, a
  /// ordem original é mantida.
  static List<Artigo> _intercalar(List<Artigo> lista) {
    final porCategoria = <String, List<Artigo>>{};
    for (final a in lista) {
      porCategoria.putIfAbsent(a.categoriaId, () => []).add(a);
    }
    if (porCategoria.length <= 1) return lista;
    final filas = porCategoria.values.toList();
    final saida = <Artigo>[];
    var i = 0;
    while (saida.length < lista.length) {
      for (final f in filas) {
        if (i < f.length) saida.add(f[i]);
      }
      i++;
    }
    return saida;
  }

  /// Feed finito da sessão: no máximo [conteudosPorSessao] artigos.
  ///
  /// [nivel] 0 mostra todos; 1 a 3 mostra só aquele nível de dificuldade.
  static List<Artigo> feedDaSessao(
    String? objetivoId,
    Set<String> categoriaIds, {
    int nivel = 0,
  }) {
    final lista = _intercalar(doNivel(doModo(objetivoId, categoriaIds), nivel));
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
