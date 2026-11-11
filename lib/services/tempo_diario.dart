import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/sem_emoji.dart';
import '../core/uso_diario.dart';
import 'auth_service.dart';
import 'progresso_service.dart';

/// Em que ponto do dia a pessoa está em relação à meta dela.
enum FaseDoDia {
  /// Ainda não escolheu quanto quer usar por dia (primeiro uso).
  semMeta,

  /// Dentro do tempo do dia.
  dentro,

  /// O tempo acabou (ou ela pediu para encerrar): a Ik AI abre a conversa.
  fimDeTempo,

  /// A pessoa encerrou o dia. O app só volta amanhã.
  encerrado,
}

enum TipoAviso { metade, foco }

/// Mensagem da Ik AI que aparece sobre o app, sem bloquear nada.
class AvisoIk {
  final TipoAviso tipo;
  final String texto;
  const AvisoIk(this.tipo, this.texto);
}

enum RespostaBalanco { ganhando, perdendo, maisOuMenos }

String nomeDoBalanco(RespostaBalanco r) {
  switch (r) {
    case RespostaBalanco.ganhando:
      return 'Estou ganhando tempo';
    case RespostaBalanco.perdendo:
      return 'Estou perdendo tempo';
    case RespostaBalanco.maisOuMenos:
      return 'Mais ou menos';
  }
}

/// O que acontece em um dia. Muda de dia, zera.
class EstadoDoDia {
  final String dia;
  int extraSeg;
  int prorrogacoes;
  bool metadeAvisada;
  bool fimAberto;
  bool fimVoluntario;
  bool encerrado;
  bool diaMarcado;

  EstadoDoDia(
    this.dia, {
    this.extraSeg = 0,
    this.prorrogacoes = 0,
    this.metadeAvisada = false,
    this.fimAberto = false,
    this.fimVoluntario = false,
    this.encerrado = false,
    this.diaMarcado = false,
  });

  Map<String, dynamic> toMap() => {
    'd': dia,
    'x': extraSeg,
    'p': prorrogacoes,
    'm': metadeAvisada,
    'f': fimAberto,
    'v': fimVoluntario,
    'e': encerrado,
    'k': diaMarcado,
  };

  static EstadoDoDia? tentarLer(Object? m) {
    if (m is! Map) return null;
    final d = m['d'];
    if (d is! String || diaDeChave(d) == null) return null;
    int inteiro(Object? v) => (v is int && v >= 0) ? v : 0;
    bool b(Object? v) => v == true;
    return EstadoDoDia(
      d,
      extraSeg: inteiro(m['x']),
      prorrogacoes: inteiro(m['p']),
      metadeAvisada: b(m['m']),
      fimAberto: b(m['f']),
      fimVoluntario: b(m['v']),
      encerrado: b(m['e']),
      diaMarcado: b(m['k']),
    );
  }
}

/// O que a pessoa contou à Ik AI ("aprendi", "quero continuar porque...").
class Reflexao {
  final String dia;

  /// 'aprendi' ou 'continuar'.
  final String tipo;
  final String texto;
  final int criadoMs;

  const Reflexao(this.dia, this.tipo, this.texto, this.criadoMs);

  Map<String, dynamic> toMap() => {
    'd': dia,
    't': tipo,
    'x': texto,
    'm': criadoMs,
  };

  static Reflexao? tentarLer(Object? m) {
    if (m is! Map) return null;
    final d = m['d'], t = m['t'], x = m['x'], c = m['m'];
    if (d is! String || t is! String || x is! String || c is! int) return null;
    return Reflexao(d, t, x, c);
  }
}

/// Resposta semanal: a pessoa sente que está ganhando tempo?
class Balanco {
  final String semana;
  final RespostaBalanco resposta;
  final String texto;
  final int criadoMs;

  const Balanco(this.semana, this.resposta, this.texto, this.criadoMs);

  Map<String, dynamic> toMap() => {
    's': semana,
    'r': resposta.index,
    'x': texto,
    'm': criadoMs,
  };

  static Balanco? tentarLer(Object? m) {
    if (m is! Map) return null;
    final s = m['s'], r = m['r'], x = m['x'], c = m['m'];
    if (s is! String || r is! int || x is! String || c is! int) return null;
    if (r < 0 || r >= RespostaBalanco.values.length) return null;
    return Balanco(s, RespostaBalanco.values[r], x, c);
  }
}

enum ResultadoMeta { aplicadaAgora, aPartirDeAmanha, invalida }

/// O tempo da pessoa no Ikai, em vez de "sessões de duração fixa".
///
/// - No primeiro uso a pessoa diz quanto quer usar por dia (a meta).
/// - O app conta o tempo de uso real do dia (só com o app aberto).
/// - Na METADE da meta, a Ik AI avisa. No FIM, abre uma conversa: a pessoa
///   pode contar o que aprendeu, justificar mais um pouco de tempo (no máximo
///   [maxProrrogacoes] vezes por dia) ou encerrar o dia.
/// - Uma vez por semana a pessoa responde se está ganhando tempo.
///
/// Tudo fica só no aparelho, separado por conta.
class TempoDiarioService extends ChangeNotifier {
  TempoDiarioService._();
  static final TempoDiarioService instance = TempoDiarioService._();

  /// Relógio injetável (para testes).
  DateTime Function() agora = DateTime.now;

  static const int metaMinima = 10;
  static const int metaMaxima = 240;
  static const int metaPadrao = 45;
  static const List<int> opcoesDeMeta = [15, 30, 45, 60, 90, 120];

  static const int maxProrrogacoes = 2;
  static const List<int> opcoesProrrogacao = [10, 15, 30];

  static const int limiteTexto = 300;
  static const int limiteGuardado = 200;

  String? _email;
  int? _metaMin;
  int? _metaAmanhaMin;
  bool _avancado = false;
  UsoDiario _uso = UsoDiario();
  late EstadoDoDia _dia = EstadoDoDia(chaveDoDia(DateTime.now()));
  final List<Reflexao> _reflexoes = [];
  final List<Balanco> _balancos = [];
  AvisoIk? _aviso;

  // Foco da leitura atual (modo avançado). Só em memória.
  int _focoSeg = 0;
  int _usoNoInicioDoFoco = 0;
  bool _focoAvisado = false;

  int _ultimaGravacaoMs = 0;

  /// Segundos de uso de hoje, para a UI (atualiza todo segundo sem
  /// reconstruir o app inteiro).
  final ValueNotifier<int> usadoHoje = ValueNotifier(0);

  // ---------- Consultas ----------

  bool get metaDefinida => _metaMin != null;
  int get metaMin => _metaMin ?? metaPadrao;
  int get metaSeg => metaMin * 60;
  int? get metaDeAmanhaMin => _metaAmanhaMin;
  bool get avancado => _avancado;
  AvisoIk? get aviso => _aviso;
  List<Reflexao> get reflexoes => List.unmodifiable(_reflexoes);
  List<Balanco> get balancos => List.unmodifiable(_balancos);

  DateTime get _hoje {
    final c = chaveDoDia(agora());
    // Relógio voltado para trás não troca o dia.
    final k = c.compareTo(_dia.dia) >= 0 ? c : _dia.dia;
    return diaDeChave(k)!;
  }

  int get usadoHojeSeg => _uso.doDia(_hoje);
  int get limiteHojeSeg => metaSeg + _dia.extraSeg;
  int get restanteSeg {
    final r = limiteHojeSeg - usadoHojeSeg;
    return r < 0 ? 0 : r;
  }

  double get fracaoUsada {
    final l = limiteHojeSeg;
    if (l <= 0) return 1;
    final f = usadoHojeSeg / l;
    return f > 1 ? 1 : f;
  }

  int get prorrogacoesFeitas => _dia.prorrogacoes;
  int get prorrogacoesRestantes => maxProrrogacoes - _dia.prorrogacoes;
  bool get podeProrrogar => prorrogacoesRestantes > 0;
  bool get fimVoluntario => _dia.fimVoluntario;
  int get extraHojeSeg => _dia.extraSeg;

  FaseDoDia get fase {
    if (!metaDefinida) return FaseDoDia.semMeta;
    if (_dia.encerrado) return FaseDoDia.encerrado;
    if (_dia.fimAberto) return FaseDoDia.fimDeTempo;
    return FaseDoDia.dentro;
  }

  ResumoSemanal get resumoSemanal => _uso.resumo(_hoje, metaSeg);
  bool get usoRecorrente => _uso.recorrente(_hoje);
  int get diasNaMeta => _uso.diasDentroDaMeta(metaSeg);

  /// Pergunta semanal pendente: só para quem já usa de forma recorrente e
  /// ainda não respondeu nesta semana.
  bool get balancoPendente {
    if (!metaDefinida || !usoRecorrente) return false;
    final semana = chaveDaSemana(_hoje);
    return !_balancos.any((b) => b.semana == semana);
  }

  Balanco? get balancoDestaSemana {
    final semana = chaveDaSemana(_hoje);
    for (final b in _balancos.reversed) {
      if (b.semana == semana) return b;
    }
    return null;
  }

  // ---------- Meta ----------

  /// Primeiro uso: define a meta e o modo. Depois: diminuir vale na hora,
  /// aumentar vale a partir de amanhã (para não esticar o limite no calor
  /// do momento).
  ResultadoMeta definirMeta(int minutos, {bool? avancado}) {
    if (minutos < metaMinima || minutos > metaMaxima) {
      return ResultadoMeta.invalida;
    }
    if (avancado != null) _avancado = avancado;
    ResultadoMeta r;
    if (_metaMin == null || minutos <= _metaMin!) {
      _metaMin = minutos;
      _metaAmanhaMin = null;
      r = ResultadoMeta.aplicadaAgora;
    } else {
      _metaAmanhaMin = minutos;
      r = ResultadoMeta.aPartirDeAmanha;
    }
    unawaited(_gravar());
    notifyListeners();
    return r;
  }

  void definirModoAvancado(bool valor) {
    if (_avancado == valor) return;
    _avancado = valor;
    unawaited(_gravar());
    notifyListeners();
  }

  // ---------- Foco da leitura (modo avançado) ----------

  /// [minutos] 0 desliga. O aviso vem da Ik AI, sem bloquear.
  void definirFoco(int minutos) {
    _focoSeg = minutos > 0 ? minutos * 60 : 0;
    _usoNoInicioDoFoco = usadoHojeSeg;
    _focoAvisado = false;
  }

  // ---------- Contagem ----------

  void _rolarDia() {
    final c = chaveDoDia(agora());
    if (c.compareTo(_dia.dia) <= 0) return;
    // Virou o dia (só para frente).
    if (_metaAmanhaMin != null) {
      _metaMin = _metaAmanhaMin;
      _metaAmanhaMin = null;
    }
    _dia = EstadoDoDia(c);
    _aviso = null;
    _focoAvisado = false;
    _focoSeg = 0;
    usadoHoje.value = _uso.doDia(_hoje);
    unawaited(_gravar());
    notifyListeners();
  }

  /// Soma [segundos] de uso real. Chamado a cada segundo pelo relógio
  /// interno e, nos testes, diretamente.
  void tick(int segundos) {
    if (!metaDefinida || segundos <= 0) return;
    _rolarDia();
    if (_dia.encerrado || _dia.fimAberto) return; // sem contar enquanto trava
    final hoje = _hoje;
    _uso.somar(hoje, segundos);
    final usado = _uso.doDia(hoje);
    usadoHoje.value = usado;

    var mudou = false;

    if (!_dia.diaMarcado && usado >= 60) {
      _dia.diaMarcado = true;
      unawaited(ProgressoService.instance.marcarDia());
    }

    if (!_dia.metadeAvisada && usado >= metaSeg ~/ 2) {
      _dia.metadeAvisada = true;
      _aviso = AvisoIk(TipoAviso.metade, textoDaMetade());
      mudou = true;
    }

    if (_focoSeg > 0 &&
        !_focoAvisado &&
        usado - _usoNoInicioDoFoco >= _focoSeg) {
      _focoAvisado = true;
      _aviso ??= AvisoIk(TipoAviso.foco, textoDoFoco(_focoSeg ~/ 60));
      mudou = true;
    }

    if (usado >= limiteHojeSeg) {
      _dia.fimAberto = true;
      _dia.fimVoluntario = false;
      _aviso = null;
      mudou = true;
      unawaited(_gravar());
    } else {
      final ms = agora().millisecondsSinceEpoch;
      if (ms - _ultimaGravacaoMs >= 15000) unawaited(_gravar());
    }

    if (mudou) notifyListeners();
  }

  // ---------- Textos da Ik AI ----------

  String textoDaMetade() =>
      'Você chegou à metade do seu tempo de hoje: '
      '${formatarHm(usadoHojeSeg)} de ${formatarHm(limiteHojeSeg)}. '
      'Dá para aproveitar o resto com calma.';

  static String textoDoFoco(int minutos) =>
      'Você planejou $minutos min para esta leitura e eles passaram. '
      'Quer fazer uma pausa?';

  void consumirAviso() {
    if (_aviso == null) return;
    _aviso = null;
    notifyListeners();
  }

  // ---------- Fim do dia ----------

  /// A pessoa pede para encerrar antes do tempo: abre a conversa de fim.
  void abrirFimVoluntario() {
    if (fase != FaseDoDia.dentro) return;
    _dia.fimAberto = true;
    _dia.fimVoluntario = true;
    _aviso = null;
    unawaited(_gravar());
    notifyListeners();
  }

  /// Só vale no fim voluntário: a pessoa mudou de ideia e volta ao app.
  bool voltarAoApp() {
    if (fase != FaseDoDia.fimDeTempo || !_dia.fimVoluntario) return false;
    _dia.fimAberto = false;
    _dia.fimVoluntario = false;
    unawaited(_gravar());
    notifyListeners();
    return true;
  }

  /// Continuar depois do fim exige uma justificativa e tem limite diário.
  /// Devolve false se não for possível.
  bool prorrogar(int minutos, String motivo) {
    if (fase != FaseDoDia.fimDeTempo || _dia.fimVoluntario) return false;
    if (!podeProrrogar || !opcoesProrrogacao.contains(minutos)) return false;
    final m = _limpar(motivo);
    if (m.length < 3) return false;
    _dia.extraSeg += minutos * 60;
    _dia.prorrogacoes++;
    _dia.fimAberto = false;
    _adicionarReflexao('continuar', m);
    unawaited(_gravar());
    notifyListeners();
    return true;
  }

  void encerrarPorHoje() {
    if (!metaDefinida) return;
    _dia.encerrado = true;
    _dia.fimAberto = false;
    _dia.fimVoluntario = false;
    _aviso = null;
    unawaited(_gravar());
    notifyListeners();
  }

  /// O que a pessoa contou que aprendeu. Devolve false se vazio.
  bool registrarAprendizado(String texto) {
    final t = _limpar(texto);
    if (t.isEmpty) return false;
    _adicionarReflexao('aprendi', t);
    unawaited(_gravar());
    notifyListeners();
    return true;
  }

  // ---------- Balanço semanal ----------

  void registrarBalanco(RespostaBalanco r, {String texto = ''}) {
    final semana = chaveDaSemana(_hoje);
    _balancos.removeWhere((b) => b.semana == semana);
    _balancos.add(
      Balanco(semana, r, _limpar(texto), agora().millisecondsSinceEpoch),
    );
    if (_balancos.length > limiteGuardado) {
      _balancos.removeRange(0, _balancos.length - limiteGuardado);
    }
    unawaited(_gravar());
    notifyListeners();
  }

  // ---------- Internos ----------

  String _limpar(String bruto) {
    var t = removerEmojis(bruto).replaceAll(RegExp(r'\s+'), ' ').trim();
    if (t.length > limiteTexto) t = t.substring(0, limiteTexto).trimRight();
    return t;
  }

  void _adicionarReflexao(String tipo, String texto) {
    _reflexoes.add(
      Reflexao(_dia.dia, tipo, texto, agora().millisecondsSinceEpoch),
    );
    if (_reflexoes.length > limiteGuardado) {
      _reflexoes.removeRange(0, _reflexoes.length - limiteGuardado);
    }
  }

  // ---------- Relógio interno (uso real com o app aberto) ----------

  Timer? _timer;
  final Stopwatch _sw = Stopwatch();
  Duration _ultimoSw = Duration.zero;
  int _restoMs = 0;

  void _aoTique() {
    final t = _sw.elapsed;
    var d = t - _ultimoSw;
    _ultimoSw = t;
    // Se o app ficou suspenso, não conta o intervalo todo.
    if (d > const Duration(seconds: 5)) d = const Duration(seconds: 5);
    if (d.isNegative) return;
    _restoMs += d.inMilliseconds;
    final s = _restoMs ~/ 1000;
    _restoMs %= 1000;
    if (s > 0) tick(s);
  }

  /// Começa (ou retoma) a contagem. Chame com o app visível.
  void iniciarContagem() {
    if (_timer != null) return;
    _sw.start();
    _ultimoSw = _sw.elapsed;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _aoTique());
  }

  /// Para a contagem (app em segundo plano ou conta saindo).
  void pausarContagem() {
    if (_timer == null) return;
    _aoTique();
    _timer?.cancel();
    _timer = null;
    _sw.stop();
    unawaited(_gravar());
  }

  // ---------- Persistência ----------

  String _chave(String email) => 'tempo_v1_${email.toLowerCase()}';

  Future<void> carregarPara(String email) async {
    _zerar();
    _email = email;
    try {
      final p = await SharedPreferences.getInstance();
      if (_email != email) return;
      final bruto = p.getString(_chave(email));
      if (bruto != null) {
        final d = jsonDecode(bruto);
        if (d is Map) {
          final meta = d['meta'];
          if (meta is int && meta >= metaMinima && meta <= metaMaxima) {
            _metaMin = meta;
          }
          final amanha = d['amanha'];
          if (amanha is int && amanha >= metaMinima && amanha <= metaMaxima) {
            _metaAmanhaMin = amanha;
          }
          _avancado = d['adv'] == true;
          _uso = UsoDiario.fromMap(d['uso']);
          final dia = EstadoDoDia.tentarLer(d['dia']);
          if (dia != null) _dia = dia;
          final refl = d['refl'];
          if (refl is List) {
            for (final m in refl) {
              final r = Reflexao.tentarLer(m);
              if (r != null) _reflexoes.add(r);
            }
          }
          final bal = d['bal'];
          if (bal is List) {
            for (final m in bal) {
              final b = Balanco.tentarLer(m);
              if (b != null) _balancos.add(b);
            }
          }
        }
      }
    } catch (_) {
      _zerar();
      _email = email;
    }
    _uso.podar(_hoje);
    _rolarDia();
    usadoHoje.value = _uso.doDia(_hoje);
    notifyListeners();
  }

  void _zerar() {
    _metaMin = null;
    _metaAmanhaMin = null;
    _avancado = false;
    _uso = UsoDiario();
    _dia = EstadoDoDia(chaveDoDia(agora()));
    _reflexoes.clear();
    _balancos.clear();
    _aviso = null;
    _focoSeg = 0;
    _focoAvisado = false;
    _usoNoInicioDoFoco = 0;
    _restoMs = 0;
    usadoHoje.value = 0;
  }

  /// Esquece a memória (sair da conta). O gravado permanece.
  void limpar() {
    pausarContagem();
    _zerar();
    _email = null;
    notifyListeners();
  }

  /// Apaga também o gravado (excluir conta).
  Future<void> apagarDaConta() async {
    final email = _email ?? AuthService.instance.usuarioAtual?.email;
    limpar();
    if (email == null) return;
    try {
      final p = await SharedPreferences.getInstance();
      await p.remove(_chave(email));
    } catch (_) {}
  }

  /// Grava agora (ao ir para segundo plano, por exemplo).
  Future<void> salvarAgora() => _gravar();

  String exportarJson() => jsonEncode(_paraMapa());

  Map<String, dynamic> _paraMapa() => {
    'meta': _metaMin,
    'amanha': _metaAmanhaMin,
    'adv': _avancado,
    'uso': _uso.toMap(),
    'dia': _dia.toMap(),
    'refl': [for (final r in _reflexoes) r.toMap()],
    'bal': [for (final b in _balancos) b.toMap()],
  };

  Future<void> _gravar() async {
    final email = _email ?? AuthService.instance.usuarioAtual?.email;
    if (email == null) return;
    _ultimaGravacaoMs = agora().millisecondsSinceEpoch;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_chave(email), exportarJson());
    } catch (_) {}
  }
}
