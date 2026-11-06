/// Um artigo do Ikai. Dart puro.
///
/// Todos os campos são escritos pelo autor (a Ikai nunca infere assunto,
/// idioma ou formato). Veja `artigos_dados.dart` para preencher novos.
class Artigo {
  /// Único em todo o app. Ex.: 'a031'.
  final String id;

  /// Id do objetivo: 'ver_conteudo', 'ler' ou 'estudar'.
  final String objetivoId;

  /// Id da categoria dentro do objetivo. Ex.: 'ler_romance'.
  final String categoriaId;

  final String titulo;
  final String autor;

  /// Uma ou duas frases que aparecem no cartão.
  final String resumo;

  /// Nível de dificuldade: 1 iniciante, 2 intermediário, 3 avançado.
  /// Quem escolhe o nível que quer ver é o usuário, nunca o app.
  final int nivel;

  /// Assuntos curtos, em minúsculas. Usados na busca e nos filtros.
  final List<String> tags;

  /// Cada item é um parágrafo do texto.
  final List<String> paragrafos;

  const Artigo({
    required this.id,
    required this.objetivoId,
    required this.categoriaId,
    required this.titulo,
    required this.autor,
    required this.resumo,
    required this.tags,
    required this.paragrafos,
    this.nivel = 1,
  });

  static const int nivelMinimo = 1;
  static const int nivelMaximo = 3;

  /// 0 não é um nível: significa "todos" nos filtros.
  static String nomeDoNivel(int nivel) {
    switch (nivel) {
      case 1:
        return 'Iniciante';
      case 2:
        return 'Intermediário';
      case 3:
        return 'Avançado';
      default:
        return 'Todos';
    }
  }

  /// Tempo de leitura estimado (180 palavras por minuto), mínimo 1.
  int get minutosLeitura {
    final palavras = paragrafos
        .join(' ')
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .length;
    final m = (palavras / 180).ceil();
    return m < 1 ? 1 : m;
  }
}
