/// Regras de duração da sessão. Dart puro (sem Flutter), para ser testável.

/// Limite máximo escolhido pelo usuário: 3 horas.
const int duracaoMaximaSegundos = 10800;

/// A validação fica na lógica, não só na interface.
bool duracaoValida(int totalSegundos) =>
    totalSegundos > 0 && totalSegundos <= duracaoMaximaSegundos;

/// Ex.: 3725 -> "1h 2min 5s".
String formatarDuracao(int s) {
  final h = s ~/ 3600;
  final m = (s % 3600) ~/ 60;
  final sec = s % 60;
  final partes = <String>[];
  if (h > 0) partes.add('${h}h');
  if (m > 0) partes.add('${m}min');
  if (sec > 0 || partes.isEmpty) partes.add('${sec}s');
  return partes.join(' ');
}

/// Ex.: Duration(minutes: 5, seconds: 3) -> "00:05:03".
String formatarRelogio(Duration d) {
  String dois(int n) => n.toString().padLeft(2, '0');
  return '${dois(d.inHours)}:${dois(d.inMinutes % 60)}:${dois(d.inSeconds % 60)}';
}
