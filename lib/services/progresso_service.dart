import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/artigo.dart';
import 'artigos_repositorio.dart';

class Conquista {
  final String id;
  final String titulo;
  final String descricao;
  final bool desbloqueada;
  const Conquista({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.desbloqueada,
  });
}

/// Progresso individual (Pilar 4): conquistas e ofensiva comparadas apenas
/// com o PRÓPRIO histórico do usuário. Sem ranking, sem comparação social.
/// Os dados ficam separados por usuário.
class ProgressoService extends ChangeNotifier {
  ProgressoService._();
  static final ProgressoService instance = ProgressoService._();

  /// Relógio injetável (para testes).
  DateTime Function() agora = DateTime.now;

  String? _email;
  final Map<String, int> _lidos = {}; // idDoArtigo -> instante (ms)
  final Set<String> _dias = {}; // dias com atividade, 'aaaa-mm-dd'
  int _sessoes = 0;
  int _segundos = 0;

  String _chave(String email) => 'progresso_v1_${email.toLowerCase()}';

  Future<void> carregarPara(String email) async {
    _zerar();
    _email = email;
    try {
      final p = await SharedPreferences.getInstance();
      final bruto = p.getString(_chave(email));
      if (bruto != null) {
        final d = jsonDecode(bruto);
        if (d is Map) {
          final lidos = d['lidos'];
          if (lidos is Map) {
            lidos.forEach((k, v) {
              if (k is String && v is int) _lidos[k] = v;
            });
          }
          final dias = d['dias'];
          if (dias is List) _dias.addAll(dias.whereType<String>());
          if (d['sessoes'] is int) _sessoes = d['sessoes'] as int;
          if (d['segundos'] is int) _segundos = d['segundos'] as int;
        }
      }
    } catch (_) {
      _zerar();
      _email = email;
    }
    notifyListeners();
  }

  void limpar() {
    _zerar();
    _email = null;
    notifyListeners();
  }

  void _zerar() {
    _lidos.clear();
    _dias.clear();
    _sessoes = 0;
    _segundos = 0;
  }

  Future<void> _salvar() async {
    final email = _email;
    if (email == null) return;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(
        _chave(email),
        jsonEncode({
          'lidos': _lidos,
          'dias': _dias.toList(),
          'sessoes': _sessoes,
          'segundos': _segundos,
        }),
      );
    } catch (_) {}
  }

  // ---------- Consultas ----------

  bool foiLido(String artigoId) => _lidos.containsKey(artigoId);
  int get totalLidos => _lidos.length;
  int get sessoesConcluidas => _sessoes;
  int get segundosEmSessao => _segundos;
  int get ofensiva => calcularOfensiva(_dias, agora());

  /// Quantidade de artigos lidos por objetivo ('ler', 'estudar', ...).
  Map<String, int> lidosPorObjetivo() {
    final r = <String, int>{};
    for (final id in _lidos.keys) {
      final a = ArtigosRepositorio.porId(id);
      if (a == null) continue;
      r[a.objetivoId] = (r[a.objetivoId] ?? 0) + 1;
    }
    return r;
  }

  // ---------- Registros ----------

  /// Marca o artigo como lido. Devolve true se era a primeira vez.
  Future<bool> registrarLeitura(Artigo artigo) async {
    final hoje = agora();
    _dias.add(chaveDia(hoje));
    final primeira = !_lidos.containsKey(artigo.id);
    if (primeira) _lidos[artigo.id] = hoje.millisecondsSinceEpoch;
    notifyListeners();
    await _salvar();
    return primeira;
  }

  Future<void> registrarSessao(int segundosUsados) async {
    _sessoes++;
    _segundos += segundosUsados < 0 ? 0 : segundosUsados;
    _dias.add(chaveDia(agora()));
    notifyListeners();
    await _salvar();
  }

  String exportarJson() => jsonEncode({
        'lidos': _lidos,
        'dias': _dias.toList()..sort(),
        'sessoes': _sessoes,
        'segundos': _segundos,
      });

  // ---------- Conquistas (derivadas dos próprios números) ----------

  List<Conquista> conquistas({required int totalSalvos}) {
    final porObjetivo = lidosPorObjetivo();
    final tresCaminhos = ['ver_conteudo', 'ler', 'estudar']
        .every((o) => (porObjetivo[o] ?? 0) >= 1);
    return [
      Conquista(
        id: 'primeira_leitura',
        titulo: 'Primeira leitura',
        descricao: 'Leia seu primeiro artigo.',
        desbloqueada: totalLidos >= 1,
      ),
      Conquista(
        id: 'leitor_curioso',
        titulo: 'Leitor curioso',
        descricao: 'Leia 5 artigos.',
        desbloqueada: totalLidos >= 5,
      ),
      Conquista(
        id: 'tres_caminhos',
        titulo: 'Três caminhos',
        descricao: 'Leia ao menos um artigo em cada modo.',
        desbloqueada: tresCaminhos,
      ),
      Conquista(
        id: 'tempo_bem_escolhido',
        titulo: 'Tempo bem escolhido',
        descricao: 'Termine uma sessão no tempo que você definiu.',
        desbloqueada: sessoesConcluidas >= 1,
      ),
      Conquista(
        id: 'tres_dias',
        titulo: 'Três dias seguidos',
        descricao: 'Use o Ikai em 3 dias seguidos, quando fizer sentido.',
        desbloqueada: ofensiva >= 3,
      ),
      Conquista(
        id: 'organizador',
        titulo: 'Organizador',
        descricao: 'Salve um artigo na sua biblioteca.',
        desbloqueada: totalSalvos >= 1,
      ),
    ];
  }

  // ---------- Funções puras (testáveis) ----------

  static String chaveDia(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// Dias seguidos com atividade, contando até hoje. Se hoje ainda não teve
  /// atividade, a contagem continua valendo a partir de ontem.
  static int calcularOfensiva(Set<String> dias, DateTime hoje) {
    var d = DateTime(hoje.year, hoje.month, hoje.day);
    if (!dias.contains(chaveDia(d))) {
      d = DateTime(d.year, d.month, d.day - 1);
    }
    var n = 0;
    while (dias.contains(chaveDia(d))) {
      n++;
      d = DateTime(d.year, d.month, d.day - 1);
    }
    return n;
  }
}
