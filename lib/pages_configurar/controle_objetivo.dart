import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show IconData;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/duracao.dart';
import '../core/relogio_sessao.dart';
import '../services/auth_service.dart';
import '../services/progresso_service.dart';
import './objetivo_conteudo.dart';
import './objetivo_estudo.dart';
import './objetivo_leitura.dart';

export '../core/duracao.dart';

// =====================================================
// MODELOS E CATÁLOGO
// =====================================================

class Categoria {
  final String id;
  final String titulo;
  final IconData icone;
  const Categoria({
    required this.id,
    required this.titulo,
    required this.icone,
  });
}

class Objetivo {
  final String id;
  final String titulo;
  final IconData icone;
  final List<Categoria> categorias;

  const Objetivo({
    required this.id,
    required this.titulo,
    required this.icone,
    required this.categorias,
  });

  Categoria? buscarCategoria(String? categoriaId) {
    if (categoriaId == null) return null;
    for (final c in categorias) {
      if (c.id == categoriaId) return c;
    }
    return null;
  }
}

/// Única lista de objetivos. Para criar um objetivo novo:
/// crie o arquivo dele (veja objetivo_leitura.dart) e inclua-o aqui.
List<Objetivo> get todosOsObjetivos => [
      objetivoConteudo,
      objetivoLeitura,
      objetivoEstudo,
    ];

Objetivo? buscarObjetivo(String? id) {
  if (id == null) return null;
  for (final o in todosOsObjetivos) {
    if (o.id == id) return o;
  }
  return null;
}

// =====================================================
// CONTROLADOR CENTRAL (ESCOLHAS + HISTÓRICO + SESSÃO + TEMPO)
// =====================================================

enum EstadoSessao { naoIniciada, ativa, expirada }

/// Foto da sessão que acabou. A tela final e a Ik AI leem daqui, porque o
/// controlador é reiniciado só quando o usuário começa uma nova sessão.
class ResumoSessao {
  final String objetivoTitulo;
  final String categoriaTitulo;
  final String textoIkAi;
  final bool permitiuEnvioGemini;
  final int duracaoPlanejadaSegundos;
  final int usadoSegundos;
  final bool encerradaPeloUsuario;

  const ResumoSessao({
    required this.objetivoTitulo,
    required this.categoriaTitulo,
    required this.textoIkAi,
    required this.permitiuEnvioGemini,
    required this.duracaoPlanejadaSegundos,
    required this.usadoSegundos,
    required this.encerradaPeloUsuario,
  });
}

/// Fonte de verdade de tudo. As escolhas e a sessão ficam só em memória;
/// apenas o histórico (usado como SUGESTÃO, nunca aplicado sozinho) é
/// gravado no aparelho, separado por usuário.
class ControleObjetivos extends ChangeNotifier {
  ControleObjetivos._() : _relogio = RelogioSessao();

  /// Para testes: relógios controlados.
  @visibleForTesting
  ControleObjetivos.paraTeste({
    DateTime Function()? agora,
    Duration Function()? monotonico,
  }) : _relogio = RelogioSessao(agora: agora, monotonico: monotonico);

  static final ControleObjetivos instance = ControleObjetivos._();

  static const _kObjetivo = 'hist_objetivo_id';
  static const _kCategoria = 'hist_categoria_id';
  static const _kDuracao = 'hist_duracao_s';
  static const _kTexto = 'hist_texto_ikai';

  /// Etapas: 0 objetivo, 1 categoria, 2 duração, 3 Ik AI (opcional).
  static const int ultimaEtapa = 3;
  static const int limiteTextoIkAi = 300;

  final RelogioSessao _relogio;

  // ---------- Escolhas do ciclo atual (sempre começam vazias) ----------
  int etapa = 0;
  Objetivo? objetivo;
  Categoria? categoria;
  int horas = 0;
  int minutos = 0;
  int segundos = 0;
  String textoIkAi = '';
  bool permitirGemini = false;

  int get duracaoSegundos => horas * 3600 + minutos * 60 + segundos;

  // ---------- Histórico (só sugestões) ----------
  bool historicoCarregado = false;
  String? _hObjetivo;
  String? _hCategoria;
  int? _hDuracao;
  String? _hTexto;

  /// Cada conta tem o próprio histórico.
  String _chave(String base) =>
      '${base}_${AuthService.instance.usuarioAtual?.email ?? 'anonimo'}';

  Future<void> carregarHistorico() async {
    if (historicoCarregado) return;
    try {
      final p = await SharedPreferences.getInstance();
      _hObjetivo = p.getString(_chave(_kObjetivo));
      _hCategoria = p.getString(_chave(_kCategoria));
      _hDuracao = p.getInt(_chave(_kDuracao));
      _hTexto = p.getString(_chave(_kTexto));
    } catch (_) {
      // Falha de leitura nunca impede o uso.
    }
    historicoCarregado = true;
    notifyListeners();
  }

  /// Esquece o histórico em memória (ao trocar de conta).
  void descartarHistoricoEmMemoria() {
    historicoCarregado = false;
    _hObjetivo = null;
    _hCategoria = null;
    _hDuracao = null;
    _hTexto = null;
  }

  Future<void> _salvarHistorico(String o, String c, int s, String t) async {
    _hObjetivo = o;
    _hCategoria = c;
    _hDuracao = s;
    _hTexto = t;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_chave(_kObjetivo), o);
      await p.setString(_chave(_kCategoria), c);
      await p.setInt(_chave(_kDuracao), s);
      await p.setString(_chave(_kTexto), t);
    } catch (_) {
      // Falha ao gravar não impede o uso.
    }
  }

  String? get sugestaoObjetivoId => buscarObjetivo(_hObjetivo)?.id;

  /// Só sugere categoria que pertença ao objetivo escolhido agora.
  String? get sugestaoCategoriaId =>
      objetivo?.buscarCategoria(_hCategoria)?.id;

  int? get sugestaoDuracao {
    final d = _hDuracao;
    return (d != null && duracaoValida(d)) ? d : null;
  }

  String? get sugestaoTexto {
    final t = _hTexto?.trim();
    return (t == null || t.isEmpty) ? null : t;
  }

  // ---------- Ações de escolha (sempre explícitas) ----------
  void selecionarObjetivo(Objetivo o) {
    if (_estado != EstadoSessao.naoIniciada) return;
    if (objetivo?.id != o.id) categoria = null; // invalida categoria incompatível
    objetivo = o;
    notifyListeners();
  }

  void selecionarCategoria(Categoria c) {
    if (_estado != EstadoSessao.naoIniciada) return;
    if (objetivo?.buscarCategoria(c.id) == null) return; // incompatível
    categoria = c;
    notifyListeners();
  }

  void definirDuracao(int h, int m, int s) {
    if (_estado != EstadoSessao.naoIniciada) return;
    horas = h;
    minutos = m;
    segundos = s;
    notifyListeners();
  }

  /// Atalho para as opções rápidas (5 min, 10 min, 1 h...).
  void definirDuracaoTotal(int totalSegundos) {
    if (totalSegundos < 0) return;
    definirDuracao(
      totalSegundos ~/ 3600,
      (totalSegundos % 3600) ~/ 60,
      totalSegundos % 60,
    );
  }

  /// Chamado só quando o usuário TOCA na sugestão de duração.
  void aplicarSugestaoDuracao() {
    final d = sugestaoDuracao;
    if (d == null) return;
    definirDuracaoTotal(d);
  }

  void definirTextoIkAi(String texto) {
    if (_estado != EstadoSessao.naoIniciada) return;
    textoIkAi = texto.length > limiteTextoIkAi
        ? texto.substring(0, limiteTextoIkAi)
        : texto;
    if (textoIkAi.trim().isEmpty) permitirGemini = false;
    notifyListeners();
  }

  /// Chamado só quando o usuário TOCA na sugestão de texto.
  void aplicarSugestaoTexto() {
    final t = sugestaoTexto;
    if (t != null) definirTextoIkAi(t);
  }

  /// O envio do texto ao Gemini só vale com autorização explícita e texto.
  void definirPermissaoGemini(bool valor) {
    if (_estado != EstadoSessao.naoIniciada) return;
    permitirGemini = valor && textoIkAi.trim().isNotEmpty;
    notifyListeners();
  }

  bool get podeAvancar {
    switch (etapa) {
      case 0:
        return objetivo != null;
      case 1:
        return objetivo != null &&
            categoria != null &&
            objetivo!.buscarCategoria(categoria!.id) != null;
      case 2:
        return duracaoValida(duracaoSegundos);
      default:
        return true; // Ik AI é opcional
    }
  }

  void avancar() {
    if (!podeAvancar || etapa >= ultimaEtapa) return;
    etapa++;
    notifyListeners();
  }

  void voltar() {
    if (etapa == 0) return;
    etapa--;
    notifyListeners();
  }

  bool _confirmando = false;

  /// Confirmação final explícita. Única porta de entrada da sessão.
  Future<bool> confirmar() async {
    if (_confirmando) return false;
    if (_estado != EstadoSessao.naoIniciada ||
        etapa != ultimaEtapa ||
        !_escolhasCompletas) {
      return false;
    }
    final o = objetivo!;
    final c = categoria!;
    final s = duracaoSegundos;

    _confirmando = true;
    try {
      // A sessão começa JÁ. Gravar o histórico não atrasa nem pausa o relógio.
      _iniciar(s);
      unawaited(_salvarHistorico(o.id, c.id, s, textoIkAi.trim()));
    } finally {
      _confirmando = false;
    }
    return true;
  }

  bool get _escolhasCompletas {
    final o = objetivo;
    final c = categoria;
    return o != null &&
        c != null &&
        o.buscarCategoria(c.id) != null &&
        duracaoValida(duracaoSegundos);
  }

  // ---------- Sessão e cronômetro ----------
  EstadoSessao _estado = EstadoSessao.naoIniciada;
  Timer? _timer;
  ResumoSessao? _ultimoResumo;

  /// Tempo restante, atualizado a cada segundo (para exibir na UI).
  final ValueNotifier<Duration> restante = ValueNotifier(Duration.zero);

  EstadoSessao get estado => _estado;
  ResumoSessao? get ultimoResumo => _ultimoResumo;
  Duration get duracaoTotal => _relogio.total;
  double get fracaoUsada => _relogio.fracaoUsada;

  void _iniciar(int segundosTotais) {
    if (_estado != EstadoSessao.naoIniciada) return; // nunca 2 sessões
    _relogio.iniciar(Duration(seconds: segundosTotais));
    restante.value = _relogio.restante;
    _estado = EstadoSessao.ativa;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => verificar());
    notifyListeners();
  }

  /// Recalcula o restante. Também é chamado ao voltar do segundo plano.
  void verificar() {
    if (_estado != EstadoSessao.ativa) return;
    if (_relogio.expirou) {
      _encerrar(peloUsuario: false);
    } else {
      restante.value = _relogio.restante;
    }
  }

  /// O usuário decide terminar antes do tempo.
  void encerrarAgora() => _encerrar(peloUsuario: true);

  void _encerrar({required bool peloUsuario}) {
    if (_estado != EstadoSessao.ativa) return; // processa uma única vez
    final usado = _relogio.decorrido;
    final total = _relogio.total;
    _timer?.cancel();
    _timer = null;
    _relogio.parar();

    final usadoFinal = usado > total ? total : usado;
    _ultimoResumo = ResumoSessao(
      objetivoTitulo: objetivo?.titulo ?? '',
      categoriaTitulo: categoria?.titulo ?? '',
      textoIkAi: textoIkAi.trim(),
      permitiuEnvioGemini: permitirGemini,
      duracaoPlanejadaSegundos: total.inSeconds,
      usadoSegundos: usadoFinal.inSeconds,
      encerradaPeloUsuario: peloUsuario,
    );
    _estado = EstadoSessao.expirada; // estado terminal: não há volta
    restante.value = Duration.zero;
    unawaited(ProgressoService.instance.registrarSessao(usadoFinal.inSeconds));
    notifyListeners();
  }

  /// Reinicia o controlador para permitir a criação de uma nova sessão.
  void reiniciarSessao() {
    _timer?.cancel();
    _timer = null;
    _relogio.zerar();
    _estado = EstadoSessao.naoIniciada;
    _confirmando = false;
    _ultimoResumo = null;
    etapa = 0;
    objetivo = null;
    categoria = null;
    horas = 0;
    minutos = 0;
    segundos = 0;
    textoIkAi = '';
    permitirGemini = false;
    restante.value = Duration.zero;
    notifyListeners();
  }
}
