import 'dart:convert';

/// A escolha do dia (objetivo, categorias, texto da Ik AI), gravada para que
/// fechar o app não obrigue a repetir tudo. Vale só no dia em que foi feita:
/// no dia seguinte a pessoa escolhe de novo (o feed é finito por escolha).
/// Dart puro.
class SelecaoSalva {
  final String objetivoId;
  final List<String> categoriaIds;
  final String texto;
  final bool permitirGemini;
  final int focoMin;

  /// 'aaaa-mm-dd' do dia em que a escolha foi feita.
  final String dia;

  const SelecaoSalva({
    required this.objetivoId,
    required this.categoriaIds,
    required this.texto,
    required this.permitirGemini,
    required this.focoMin,
    required this.dia,
  });

  String toJson() => jsonEncode({
    'o': objetivoId,
    'c': categoriaIds,
    't': texto,
    'g': permitirGemini,
    'f': focoMin,
    'd': dia,
  });

  /// Devolve null se o texto gravado for inválido (nunca lança).
  static SelecaoSalva? tentarLer(String? texto) {
    if (texto == null || texto.isEmpty) return null;
    try {
      final m = jsonDecode(texto);
      if (m is! Map) return null;
      final o = m['o'];
      final c = m['c'];
      final t = m['t'];
      final g = m['g'];
      final f = m['f'];
      final d = m['d'];
      if (o is! String || c is! List || t is! String || g is! bool) {
        return null;
      }
      if (f is! int || d is! String) return null;
      final ids = c.whereType<String>().toList();
      if (ids.isEmpty) return null;
      return SelecaoSalva(
        objetivoId: o,
        categoriaIds: ids,
        texto: t,
        permitirGemini: g,
        focoMin: f,
        dia: d,
      );
    } catch (_) {
      return null;
    }
  }
}
