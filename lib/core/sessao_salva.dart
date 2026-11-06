import 'dart:convert';

import 'duracao.dart';

/// Foto da sessão gravada no aparelho. Dart puro, para ser testável.
///
/// Serve para o limite de tempo continuar valendo mesmo se o app for
/// fechado e aberto de novo: o relógio de parede (início gravado) segue
/// contando, e o "último momento visto" impede ganhar tempo voltando a hora.
class SessaoSalva {
  final String objetivoId;
  final String categoriaId;
  final String texto;
  final bool permitirGemini;
  final int totalSegundos;

  /// Milissegundos desde 1970 (relógio de parede).
  final int inicioMs;
  final int vistoMs;

  final bool encerrada;
  final int usadoSegundos;
  final bool peloUsuario;

  const SessaoSalva({
    required this.objetivoId,
    required this.categoriaId,
    required this.texto,
    required this.permitirGemini,
    required this.totalSegundos,
    required this.inicioMs,
    required this.vistoMs,
    this.encerrada = false,
    this.usadoSegundos = 0,
    this.peloUsuario = false,
  });

  /// Tempo decorrido em [agoraMs]. Usa o maior entre "agora" e o último
  /// momento visto: voltar a hora do celular não devolve tempo.
  Duration decorridoEm(int agoraMs) {
    final fim = agoraMs > vistoMs ? agoraMs : vistoMs;
    final ms = fim - inicioMs;
    return ms <= 0 ? Duration.zero : Duration(milliseconds: ms);
  }

  SessaoSalva comVisto(int agoraMs) => SessaoSalva(
        objetivoId: objetivoId,
        categoriaId: categoriaId,
        texto: texto,
        permitirGemini: permitirGemini,
        totalSegundos: totalSegundos,
        inicioMs: inicioMs,
        vistoMs: agoraMs > vistoMs ? agoraMs : vistoMs,
        encerrada: encerrada,
        usadoSegundos: usadoSegundos,
        peloUsuario: peloUsuario,
      );

  SessaoSalva comoEncerrada({
    required int usadoSegundos,
    required bool peloUsuario,
  }) =>
      SessaoSalva(
        objetivoId: objetivoId,
        categoriaId: categoriaId,
        texto: texto,
        permitirGemini: permitirGemini,
        totalSegundos: totalSegundos,
        inicioMs: inicioMs,
        vistoMs: vistoMs,
        encerrada: true,
        usadoSegundos: usadoSegundos,
        peloUsuario: peloUsuario,
      );

  String toJson() => jsonEncode({
        'o': objetivoId,
        'c': categoriaId,
        't': texto,
        'g': permitirGemini,
        'tot': totalSegundos,
        'ini': inicioMs,
        'vis': vistoMs,
        'enc': encerrada,
        'uso': usadoSegundos,
        'usr': peloUsuario,
      });

  /// Devolve null se o texto gravado for inválido (nunca lança).
  static SessaoSalva? tentarLer(String? texto) {
    if (texto == null || texto.isEmpty) return null;
    try {
      final m = jsonDecode(texto);
      if (m is! Map) return null;
      final o = m['o'];
      final c = m['c'];
      final t = m['t'];
      final g = m['g'];
      final tot = m['tot'];
      final ini = m['ini'];
      final vis = m['vis'];
      final enc = m['enc'];
      final uso = m['uso'];
      final usr = m['usr'];
      if (o is! String ||
          c is! String ||
          t is! String ||
          g is! bool ||
          tot is! int ||
          ini is! int ||
          vis is! int ||
          enc is! bool ||
          uso is! int ||
          usr is! bool) {
        return null;
      }
      if (!duracaoValida(tot) || uso < 0 || uso > tot) return null;
      return SessaoSalva(
        objetivoId: o,
        categoriaId: c,
        texto: t,
        permitirGemini: g,
        totalSegundos: tot,
        inicioMs: ini,
        vistoMs: vis,
        encerrada: enc,
        usadoSegundos: uso,
        peloUsuario: usr,
      );
    } catch (_) {
      return null;
    }
  }
}
