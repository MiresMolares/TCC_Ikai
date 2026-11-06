import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/atividades.dart';
import '../core/sem_emoji.dart';
import 'auth_service.dart';

/// Resposta do usuário ao check-in.
enum RespostaCombinado { fiz, fizUmPouco, naoFiz }

String nomeDaResposta(RespostaCombinado r) {
  switch (r) {
    case RespostaCombinado.fiz:
      return 'Fiz';
    case RespostaCombinado.fizUmPouco:
      return 'Fiz um pouco';
    case RespostaCombinado.naoFiz:
      return 'Não consegui';
  }
}

/// "Quando [momento], eu vou [atividade]": o combinado que o usuário fez com
/// a Ik AI ao escolher uma ideia. Planos com "quando" e "o quê" definidos
/// aumentam a chance de a pessoa cumprir (intenções de implementação).
class Combinado {
  final String id;
  final String atividadeId;
  final String titulo;
  final String quando;
  final int criadoMs;
  final RespostaCombinado? resposta;
  final int? respondidoMs;

  const Combinado({
    required this.id,
    required this.atividadeId,
    required this.titulo,
    required this.quando,
    required this.criadoMs,
    this.resposta,
    this.respondidoMs,
  });

  bool get pendente => resposta == null;

  Combinado comResposta(RespostaCombinado r, int agoraMs) => Combinado(
        id: id,
        atividadeId: atividadeId,
        titulo: titulo,
        quando: quando,
        criadoMs: criadoMs,
        resposta: r,
        respondidoMs: agoraMs,
      );

  Map<String, dynamic> toMap() => {
        'i': id,
        'a': atividadeId,
        't': titulo,
        'q': quando,
        'c': criadoMs,
        'r': resposta?.index,
        'm': respondidoMs,
      };

  static Combinado? tentarLer(Object? m) {
    if (m is! Map) return null;
    final i = m['i'], a = m['a'], t = m['t'], q = m['q'], c = m['c'];
    if (i is! String || a is! String || t is! String) return null;
    if (q is! String || c is! int) return null;
    final r = m['r'];
    final resp = (r is int && r >= 0 && r < RespostaCombinado.values.length)
        ? RespostaCombinado.values[r]
        : null;
    final rm = m['m'];
    return Combinado(
      id: i,
      atividadeId: a,
      titulo: t,
      quando: q,
      criadoMs: c,
      resposta: resp,
      respondidoMs: rm is int ? rm : null,
    );
  }
}

/// Combinados do usuário com a Ik AI, gravados por conta (só no aparelho).
/// Tudo é declarado pelo usuário; nada é enviado para fora.
class CompromissoService extends ChangeNotifier {
  CompromissoService._();
  static final CompromissoService instance = CompromissoService._();

  /// Relógio injetável (para testes).
  DateTime Function() agora = DateTime.now;

  static const int limiteGuardado = 100;
  static const int limiteQuando = 40;

  String? _email;
  final List<Combinado> _itens = [];

  String _chave(String email) => 'combinados_v1_${email.toLowerCase()}';

  /// Mais recentes primeiro.
  List<Combinado> get todos => List.unmodifiable(_itens);

  /// O combinado mais recente que ainda espera resposta.
  Combinado? get pendente {
    for (final c in _itens) {
      if (c.pendente) return c;
    }
    return null;
  }

  int _contar(RespostaCombinado r) =>
      _itens.where((c) => c.resposta == r).length;

  int get feitos => _contar(RespostaCombinado.fiz);
  int get parciais => _contar(RespostaCombinado.fizUmPouco);
  int get naoFeitos => _contar(RespostaCombinado.naoFiz);
  int get respondidos => feitos + parciais + naoFeitos;

  Future<void> carregarPara(String email) async {
    _itens.clear();
    _email = email;
    try {
      final p = await SharedPreferences.getInstance();
      if (_email != email) return;
      final bruto = p.getString(_chave(email));
      if (bruto != null) {
        final d = jsonDecode(bruto);
        if (d is List) {
          for (final m in d) {
            final c = Combinado.tentarLer(m);
            if (c != null) _itens.add(c);
          }
        }
      }
    } catch (_) {
      _itens.clear();
    }
    notifyListeners();
  }

  /// Esquece o que está em memória (sair da conta). O gravado permanece.
  void limpar() {
    _itens.clear();
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

  /// Registra o combinado. Se já havia um sem resposta, ele é encerrado como
  /// "não consegui": a conta sempre tem no máximo um check-in pendente.
  Combinado adicionar(Atividade a, String quando) {
    final agoraMs = agora().millisecondsSinceEpoch;
    for (var k = 0; k < _itens.length; k++) {
      if (_itens[k].pendente) {
        _itens[k] = _itens[k].comResposta(RespostaCombinado.naoFiz, agoraMs);
      }
    }
    var q = removerEmojis(quando).replaceAll(RegExp(r'\s+'), ' ').trim();
    if (q.isEmpty) q = 'agora';
    if (q.length > limiteQuando) q = q.substring(0, limiteQuando).trimRight();
    final c = Combinado(
      id: '$agoraMs-${_itens.length}',
      atividadeId: a.id,
      titulo: a.titulo,
      quando: q,
      criadoMs: agoraMs,
    );
    _itens.insert(0, c);
    if (_itens.length > limiteGuardado) {
      _itens.removeRange(limiteGuardado, _itens.length);
    }
    _gravar();
    notifyListeners();
    return c;
  }

  void responder(String id, RespostaCombinado r) {
    final k = _itens.indexWhere((c) => c.id == id);
    if (k < 0 || !_itens[k].pendente) return;
    _itens[k] = _itens[k].comResposta(r, agora().millisecondsSinceEpoch);
    _gravar();
    notifyListeners();
  }

  /// Dispensa o check-in sem registrar como feito nem como falha.
  void descartarPendente() {
    final p = pendente;
    if (p == null) return;
    _itens.removeWhere((c) => c.id == p.id);
    _gravar();
    notifyListeners();
  }

  String exportarJson() => jsonEncode([for (final c in _itens) c.toMap()]);

  Future<void> _gravar() async {
    final email = _email ?? AuthService.instance.usuarioAtual?.email;
    if (email == null) return;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_chave(email), exportarJson());
    } catch (_) {}
  }
}
