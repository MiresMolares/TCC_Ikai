/// Uso do Ikai por dia e resumo da semana. Dart puro (testável).
///
/// O tempo é contado em segundos de uso REAL com o app aberto. Só os dias
/// ficam guardados (nada de horários), e só no aparelho.

DateTime _soDia(DateTime d) => DateTime(d.year, d.month, d.day);

/// 'aaaa-mm-dd' no calendário local.
String chaveDoDia(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

DateTime? diaDeChave(String chave) {
  final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(chave);
  if (m == null) return null;
  final a = int.parse(m.group(1)!);
  final me = int.parse(m.group(2)!);
  final di = int.parse(m.group(3)!);
  if (me < 1 || me > 12 || di < 1 || di > 31) return null;
  return DateTime(a, me, di);
}

/// Dia [n] dias antes de [d] (n pode ser 0).
DateTime diasAntes(DateTime d, int n) => DateTime(d.year, d.month, d.day - n);

/// Chave da semana: a segunda-feira que a abre. Usada para perguntar o
/// balanço uma vez por semana.
String chaveDaSemana(DateTime d) {
  final dia = _soDia(d);
  return chaveDoDia(diasAntes(dia, dia.weekday - 1));
}

/// 338 min -> "5h38". 45 min -> "45 min". Menos de 30 s -> "menos de 1 min".
String formatarHm(int segundos) {
  if (segundos <= 0) return '0 min';
  final totalMin = (segundos / 60).round();
  if (totalMin < 1) return 'menos de 1 min';
  if (totalMin < 60) return '$totalMin min';
  final h = totalMin ~/ 60;
  final m = totalMin % 60;
  return '${h}h${m.toString().padLeft(2, '0')}';
}

/// Os números da janela dos últimos 7 dias.
class ResumoSemanal {
  /// Total na janela, em segundos.
  final int totalSeg;

  /// Dias contados na média: do primeiro dia de uso da janela até hoje
  /// (de 1 a 7). Dias sem uso entre eles contam como zero.
  final int dias;

  final int mediaSeg;
  final int diasComUso;
  final int diasDentroDaMeta;
  final int metaSeg;

  /// Segundos de cada um dos 7 dias, do mais antigo para hoje.
  final List<int> porDia;

  const ResumoSemanal({
    required this.totalSeg,
    required this.dias,
    required this.mediaSeg,
    required this.diasComUso,
    required this.diasDentroDaMeta,
    required this.metaSeg,
    required this.porDia,
  });

  bool get mediaDentroDaMeta => mediaSeg <= metaSeg;
  int get diferencaSeg => mediaSeg - metaSeg;
  int get maiorDiaSeg => porDia.fold(0, (a, b) => b > a ? b : a);

  /// Frase para a pessoa: só números e a comparação com a meta dela.
  String get texto {
    final meta = formatarHm(metaSeg);
    if (dias <= 1) {
      final hoje = porDia.isEmpty ? 0 : porDia.last;
      return 'Hoje você usou o Ikai por ${formatarHm(hoje)}. '
          'Sua meta é $meta por dia.';
    }
    final comparacao = mediaDentroDaMeta
        ? 'Sua média está dentro da meta de $meta por dia.'
        : 'Sua média está ${formatarHm(diferencaSeg)} acima da meta de '
              '$meta por dia.';
    return 'Nos últimos $dias dias você usou o Ikai por '
        '${formatarHm(totalSeg)}, uma média de ${formatarHm(mediaSeg)} por '
        'dia. $comparacao';
  }
}

/// Segundos de uso por dia. Mutável, serializável.
class UsoDiario {
  final Map<String, int> _dias = {};

  int doDia(DateTime d) => _dias[chaveDoDia(d)] ?? 0;

  /// Quantidade de dias (de todo o histórico) com algum uso.
  int get diasComUsoNoTotal => _dias.values.where((s) => s > 0).length;

  bool get vazio => _dias.isEmpty;

  void somar(DateTime d, int segundos) {
    if (segundos <= 0) return;
    final k = chaveDoDia(d);
    _dias[k] = (_dias[k] ?? 0) + segundos;
  }

  /// Segundos dos últimos [n] dias, do mais antigo para [hoje].
  List<int> ultimosDias(DateTime hoje, int n) => [
    for (var i = n - 1; i >= 0; i--) doDia(diasAntes(hoje, i)),
  ];

  /// Uso recorrente: ao menos [minimoDias] dias com uso, sendo um deles
  /// dentro da última semana. É isso que troca o "primeiro contato" pelos
  /// dados de uso na tela inicial.
  bool recorrente(DateTime hoje, {int minimoDias = 2}) {
    if (diasComUsoNoTotal < minimoDias) return false;
    return ultimosDias(hoje, 7).any((s) => s > 0);
  }

  ResumoSemanal resumo(DateTime hoje, int metaSeg) {
    final porDia = ultimosDias(hoje, 7);
    var primeiro = -1;
    for (var i = 0; i < porDia.length; i++) {
      if (porDia[i] > 0) {
        primeiro = i;
        break;
      }
    }
    final total = porDia.fold<int>(0, (a, b) => a + b);
    final dias = primeiro < 0 ? 1 : 7 - primeiro;
    final comUso = porDia.where((s) => s > 0).length;
    final dentro = porDia.where((s) => s > 0 && s <= metaSeg).length;
    return ResumoSemanal(
      totalSeg: total,
      dias: dias,
      mediaSeg: (total / dias).round(),
      diasComUso: comUso,
      diasDentroDaMeta: dentro,
      metaSeg: metaSeg,
      porDia: porDia,
    );
  }

  /// Dias (de todo o histórico) em que o uso ficou dentro da meta atual.
  int diasDentroDaMeta(int metaSeg) =>
      _dias.values.where((s) => s > 0 && s <= metaSeg).length;

  /// Descarta dias muito antigos para o armazenamento não crescer sem fim.
  void podar(DateTime hoje, {int manterDias = 120}) {
    final limite = chaveDoDia(diasAntes(hoje, manterDias));
    _dias.removeWhere((k, _) => k.compareTo(limite) < 0);
  }

  Map<String, int> toMap() => Map<String, int>.from(_dias);

  /// Aceita qualquer coisa: dado corrompido vira histórico vazio.
  static UsoDiario fromMap(Object? bruto) {
    final u = UsoDiario();
    if (bruto is Map) {
      bruto.forEach((k, v) {
        if (k is String && v is int && v > 0 && diaDeChave(k) != null) {
          u._dias[k] = v;
        }
      });
    }
    return u;
  }
}
