/// Cronômetro da sessão. Dart puro (sem Flutter), para ser testável.
///
/// Por que dois relógios: o relógio de parede (DateTime) continua contando
/// quando o aparelho dorme, mas o usuário poderia "voltar" a hora do celular
/// para ganhar tempo. O cronômetro monotônico (Stopwatch) não aceita esse
/// truque, mas pode parar durante o sono do aparelho. O tempo decorrido é
/// sempre o MAIOR dos dois, então nenhuma das duas trapaças funciona.
class RelogioSessao {
  RelogioSessao({
    DateTime Function()? agora,
    Duration Function()? monotonico,
  })  : _agora = agora ?? DateTime.now,
        _monotonicoInjetado = monotonico;

  final DateTime Function() _agora;
  final Duration Function()? _monotonicoInjetado;
  final Stopwatch _stopwatch = Stopwatch();

  DateTime? _inicio;
  Duration _total = Duration.zero;

  bool get iniciado => _inicio != null;
  Duration get total => _total;

  void iniciar(Duration total) {
    _total = total;
    _inicio = _agora();
    _stopwatch
      ..reset()
      ..start();
  }

  /// Retoma uma sessão que já tinha [decorridoAnterior] de uso (app fechado
  /// e aberto de novo). O tempo anterior nunca é devolvido.
  void retomar(Duration total, Duration decorridoAnterior) {
    _total = total;
    _inicio = _agora().subtract(
      decorridoAnterior.isNegative ? Duration.zero : decorridoAnterior,
    );
    _stopwatch
      ..reset()
      ..start();
  }

  void parar() {
    _stopwatch.stop();
  }

  void zerar() {
    _stopwatch
      ..stop()
      ..reset();
    _inicio = null;
    _total = Duration.zero;
  }

  /// Tempo decorrido: o maior entre relógio de parede e monotônico,
  /// nunca negativo.
  Duration get decorrido {
    final inicio = _inicio;
    if (inicio == null) return Duration.zero;
    final parede = _agora().difference(inicio);
    final mono = _monotonicoInjetado?.call() ?? _stopwatch.elapsed;
    final maior = parede > mono ? parede : mono;
    return maior.isNegative ? Duration.zero : maior;
  }

  /// Tempo que falta; nunca negativo.
  Duration get restante {
    final r = _total - decorrido;
    return r.isNegative ? Duration.zero : r;
  }

  bool get expirou => iniciado && restante == Duration.zero;

  /// Fração já usada, de 0.0 a 1.0.
  double get fracaoUsada {
    if (_total == Duration.zero) return 0;
    final f = decorrido.inMicroseconds / _total.inMicroseconds;
    return f.clamp(0.0, 1.0);
  }
}
