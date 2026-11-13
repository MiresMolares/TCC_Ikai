import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show IconData;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/selecao_salva.dart';
import '../core/uso_diario.dart';
import '../services/auth_service.dart';
import '../services/tempo_diario.dart';
import './objetivo_conteudo.dart';
import './objetivo_estudo.dart';
import './objetivo_leitura.dart';
import './objetivo_oficio.dart';

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
      objetivoOficio,
    ];

Objetivo? buscarObjetivo(String? id) {
  if (id == null) return null;
  for (final o in todosOsObjetivos) {
    if (o.id == id) return o;
  }
  return null;
}

// =====================================================
// CONTROLADOR DA ESCOLHA (OBJETIVO + CATEGORIAS + IK AI)
// =====================================================

/// "ativa" quer dizer: a pessoa já escolheu o que quer ver hoje. Não existe
/// mais relógio aqui: o tempo é da meta diária (veja TempoDiarioService).
enum EstadoSessao { naoIniciada, ativa }

/// Etapas do fluxo. O modo iniciante tem as duas primeiras; o avançado, as
/// quatro.
enum EtapaFluxo { objetivo, categorias, foco, ikai }

/// Fonte de verdade da escolha atual. A escolha do dia é gravada (vale só no
/// dia), e o histórico, usado como SUGESTÃO (nunca aplicado sozinho), fica
/// separado por usuário.
class ControleObjetivos extends ChangeNotifier {
  ControleObjetivos._()
      : _avancado = (() => TempoDiarioService.instance.avancado),
        _agora = DateTime.now;

  /// Para testes: modo e relógio controlados.
  @visibleForTesting
  ControleObjetivos.paraTeste({
    bool Function()? avancado,
    DateTime Function()? agora,
  })  : _avancado = avancado ?? (() => false),
        _agora = agora ?? DateTime.now;

  static final ControleObjetivos instance = ControleObjetivos._();

  static const _kObjetivo = 'hist_objetivo_id';
  static const _kCategorias = 'hist_categoria_id'; // ids separados por vírgula
  static const _kFoco = 'hist_foco_min';
  static const _kTexto = 'hist_texto_ikai';
  static const _kSelecao = 'selecao_v1';

  static const int limiteTextoIkAi = 300;

  /// Mais categorias que isso deixa o feed (fixo em 8) sem foco.
  static const int maxCategorias = 5;

  /// Lembretes de foco do modo avançado (0 = sem lembrete).
  static const List<int> opcoesFoco = [10, 15, 20, 30, 45];

  final bool Function() _avancado;
  final DateTime Function() _agora;

  // ---------- Etapas ----------
  int etapa = 0;

  List<EtapaFluxo> get etapas => _avancado()
      ? const [
          EtapaFluxo.objetivo,
          EtapaFluxo.categorias,
          EtapaFluxo.foco,
          EtapaFluxo.ikai,
        ]
      : const [EtapaFluxo.objetivo, EtapaFluxo.categorias];

  int get ultimaEtapa => etapas.length - 1;

  EtapaFluxo get etapaAtual {
    final e = etapas;
    return e[etapa < 0 ? 0 : (etapa >= e.length ? e.length - 1 : etapa)];
  }

  // ---------- Escolhas (sempre começam vazias) ----------
  Objetivo? objetivo;
  final List<Categoria> _categorias = [];
  int focoMin = 0;
  String textoIkAi = '';
  bool permitirGemini = false;

  List<Categoria> get categorias => List.unmodifiable(_categorias);

  /// Ids na ordem em que a pessoa escolheu.
  Set<String> get categoriaIds => {for (final c in _categorias) c.id};

  bool temCategoria(String id) => _categorias.any((c) => c.id == id);

  /// "Romance, Fantasia" (para telas e para a Ik AI).
  String get titulosDasCategorias => _categorias.map((c) => c.titulo).join(', ');

  // ---------- Histórico (só sugestões) ----------
  bool historicoCarregado = false;
  String? _hObjetivo;
  List<String> _hCategorias = const [];
  int? _hFoco;
  String? _hTexto;

  /// Cada conta tem o próprio histórico.
  String _chave(String base) =>
      '${base}_${AuthService.instance.usuarioAtual?.email ?? 'anonimo'}';

  Future<void> carregarHistorico() async {
    if (historicoCarregado) return;
    try {
      final p = await SharedPreferences.getInstance();
      _hObjetivo = p.getString(_chave(_kObjetivo));
      final cats = p.getString(_chave(_kCategorias));
      _hCategorias = (cats == null || cats.isEmpty)
          ? const []
          : cats.split(',').where((c) => c.isNotEmpty).toList();
      _hFoco = p.getInt(_chave(_kFoco));
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
    _hCategorias = const [];
    _hFoco = null;
    _hTexto = null;
  }

  Future<void> _salvarHistorico() async {
    final o = objetivo;
    if (o == null) return;
    _hObjetivo = o.id;
    _hCategorias = _categorias.map((c) => c.id).toList();
    _hFoco = focoMin;
    _hTexto = textoIkAi.trim();
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_chave(_kObjetivo), o.id);
      await p.setString(_chave(_kCategorias), _hCategorias.join(','));
      await p.setInt(_chave(_kFoco), focoMin);
      await p.setString(_chave(_kTexto), textoIkAi.trim());
    } catch (_) {
      // Falha ao gravar não impede o uso.
    }
  }

  String? get sugestaoObjetivoId => buscarObjetivo(_hObjetivo)?.id;

  /// Só sugere categorias que pertençam ao objetivo escolhido agora.
  Set<String> get sugestaoCategoriaIds {
    final o = objetivo;
    if (o == null) return const {};
    return {
      for (final id in _hCategorias)
        if (o.buscarCategoria(id) != null) id,
    };
  }

  int? get sugestaoFoco {
    final f = _hFoco;
    return (f != null && f > 0 && opcoesFoco.contains(f)) ? f : null;
  }

  String? get sugestaoTexto {
    final t = _hTexto?.trim();
    return (t == null || t.isEmpty) ? null : t;
  }

  // ---------- Ações de escolha (sempre explícitas) ----------
  void selecionarObjetivo(Objetivo o) {
    if (_estado != EstadoSessao.naoIniciada) return;
    if (objetivo?.id != o.id) _categorias.clear(); // categorias do outro objetivo
    objetivo = o;
    notifyListeners();
  }

  /// Marca ou desmarca. Devolve false se bateu no limite de categorias.
  bool alternarCategoria(Categoria c) {
    if (_estado != EstadoSessao.naoIniciada) return true;
    if (objetivo?.buscarCategoria(c.id) == null) return true; // incompatível
    final i = _categorias.indexWhere((x) => x.id == c.id);
    if (i >= 0) {
      _categorias.removeAt(i);
    } else {
      if (_categorias.length >= maxCategorias) return false;
      _categorias.add(c);
    }
    notifyListeners();
    return true;
  }

  /// Chamado só quando o usuário TOCA em "usar sugestão".
  void aplicarSugestaoCategorias() {
    if (_estado != EstadoSessao.naoIniciada) return;
    final o = objetivo;
    if (o == null) return;
    _categorias.clear();
    for (final id in sugestaoCategoriaIds.take(maxCategorias)) {
      final c = o.buscarCategoria(id);
      if (c != null) _categorias.add(c);
    }
    notifyListeners();
  }

  void definirFoco(int minutos) {
    if (_estado != EstadoSessao.naoIniciada) return;
    if (minutos != 0 && !opcoesFoco.contains(minutos)) return;
    focoMin = minutos;
    notifyListeners();
  }

  void aplicarSugestaoFoco() {
    final f = sugestaoFoco;
    if (f != null) definirFoco(f);
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

  bool get _categoriasValidas {
    final o = objetivo;
    if (o == null || _categorias.isEmpty) return false;
    return _categorias.every((c) => o.buscarCategoria(c.id) != null);
  }

  bool get podeAvancar {
    switch (etapaAtual) {
      case EtapaFluxo.objetivo:
        return objetivo != null;
      case EtapaFluxo.categorias:
        return _categoriasValidas;
      case EtapaFluxo.foco:
      case EtapaFluxo.ikai:
        return true; // opcionais
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

  /// Confirmação final explícita. Única porta de entrada.
  Future<bool> confirmar() async {
    if (_confirmando) return false;
    if (_estado != EstadoSessao.naoIniciada ||
        etapa != ultimaEtapa ||
        objetivo == null ||
        !_categoriasValidas) {
      return false;
    }
    _confirmando = true;
    try {
      // No modo iniciante estas opções nem aparecem: ficam vazias.
      if (!_avancado()) {
        focoMin = 0;
        textoIkAi = '';
        permitirGemini = false;
      }
      _estado = EstadoSessao.ativa;
      TempoDiarioService.instance.definirFoco(focoMin);
      unawaited(_gravarSelecao());
      unawaited(_salvarHistorico());
      notifyListeners();
    } finally {
      _confirmando = false;
    }
    return true;
  }

  // ---------- Escolha gravada (vale só no dia) ----------
  EstadoSessao _estado = EstadoSessao.naoIniciada;
  EstadoSessao get estado => _estado;

  Future<void> _gravarSelecao() async {
    final o = objetivo;
    if (o == null || _categorias.isEmpty) return;
    final chave = _chave(_kSelecao); // a chave é da conta de agora
    final s = SelecaoSalva(
      objetivoId: o.id,
      categoriaIds: _categorias.map((c) => c.id).toList(),
      texto: textoIkAi.trim(),
      permitirGemini: permitirGemini,
      focoMin: focoMin,
      dia: chaveDoDia(_agora()),
    );
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(chave, s.toJson());
    } catch (_) {}
  }

  Future<void> _apagarSelecao() async {
    final chave = _chave(_kSelecao);
    try {
      final p = await SharedPreferences.getInstance();
      await p.remove(chave);
    } catch (_) {}
  }

  /// Chamado logo depois do login. Se a pessoa já escolheu o que ver hoje,
  /// a escolha volta; escolha de outro dia é descartada.
  Future<void> restaurarSelecao() async {
    if (_estado != EstadoSessao.naoIniciada) return;
    SelecaoSalva? s;
    final chave = _chave(_kSelecao);
    try {
      final p = await SharedPreferences.getInstance();
      s = SelecaoSalva.tentarLer(p.getString(chave));
    } catch (_) {
      return;
    }
    if (s == null) return;

    final o = buscarObjetivo(s.objetivoId);
    final cats = <Categoria>[];
    if (o != null) {
      for (final id in s.categoriaIds) {
        final c = o.buscarCategoria(id);
        if (c != null) cats.add(c);
      }
    }
    if (o == null || cats.isEmpty || s.dia != chaveDoDia(_agora())) {
      await _apagarSelecao();
      return;
    }

    objetivo = o;
    _categorias
      ..clear()
      ..addAll(cats);
    textoIkAi = s.texto;
    permitirGemini = s.permitirGemini;
    focoMin = s.focoMin;
    _estado = EstadoSessao.ativa;
    notifyListeners();
  }

  /// A pessoa quer escolher outra coisa (ou a conta foi excluída): apaga
  /// também a escolha gravada.
  void reiniciarSessao() {
    descartarSessaoEmMemoria();
    unawaited(_apagarSelecao());
  }

  /// Limpa só a memória (troca de conta). A escolha gravada permanece.
  void descartarSessaoEmMemoria() {
    _estado = EstadoSessao.naoIniciada;
    _confirmando = false;
    etapa = 0;
    objetivo = null;
    _categorias.clear();
    focoMin = 0;
    textoIkAi = '';
    permitirGemini = false;
    notifyListeners();
  }
}
