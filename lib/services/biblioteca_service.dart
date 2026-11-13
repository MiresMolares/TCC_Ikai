import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pasta da biblioteca. Um único nível (sem pastas dentro de pastas).
class Pasta {
  final String id;
  String nome;
  final List<String> artigoIds;

  Pasta({required this.id, required this.nome, List<String>? artigoIds})
      : artigoIds = artigoIds ?? <String>[];

  Map<String, dynamic> toJson() =>
      {'id': id, 'nome': nome, 'artigos': artigoIds};

  static Pasta? deJson(Object? o) {
    if (o is! Map) return null;
    final id = o['id'];
    final nome = o['nome'];
    if (id is! String || nome is! String) return null;
    final artigos = o['artigos'];
    return Pasta(
      id: id,
      nome: nome,
      artigoIds: artigos is List ? artigos.whereType<String>().toList() : [],
    );
  }
}

/// Biblioteca pessoal (Pilar 5), separada do feed.
///
/// - Organizada só por pastas criadas pelo usuário, em um único nível.
/// - Todo conteúdo salvo pertence a pelo menos uma pasta.
/// - Um conteúdo pode estar em várias pastas.
/// - Guarda apenas a REFERÊNCIA (o id do artigo), nunca uma cópia.
/// - Os dados ficam separados por usuário.
class BibliotecaService extends ChangeNotifier {
  BibliotecaService._();
  static final BibliotecaService instance = BibliotecaService._();

  static const String nomePastaPadrao = 'Salvos';
  static const int tamanhoMaximoNome = 40;

  String? _email;
  List<Pasta> _pastas = [];
  int _contador = 0;

  List<Pasta> get pastas => List.unmodifiable(_pastas);

  String _chave(String email) => 'biblioteca_v1_${email.toLowerCase()}';

  Future<void> carregarPara(String email) async {
    _email = email;
    _pastas = [];
    try {
      final p = await SharedPreferences.getInstance();
      final bruto = p.getString(_chave(email));
      if (bruto != null) {
        final dados = jsonDecode(bruto);
        final lista = dados is Map ? dados['pastas'] : null;
        if (lista is List) {
          _pastas = lista.map(Pasta.deJson).whereType<Pasta>().toList();
        }
      }
    } catch (_) {
      _pastas = [];
    }
    if (_pastas.isEmpty) {
      _pastas = [Pasta(id: _novoId(), nome: nomePastaPadrao)];
    }
    notifyListeners();
  }

  /// Chamado ao sair da conta: nada fica na memória para o próximo usuário.
  void limpar() {
    _email = null;
    _pastas = [];
    notifyListeners();
  }

  String _novoId() =>
      '${DateTime.now().microsecondsSinceEpoch}_${_contador++}';

  Future<void> _salvar() async {
    final email = _email;
    if (email == null) return;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_chave(email), jsonEncode(_dadosJson()));
    } catch (_) {
      // Falha ao gravar não derruba o app.
    }
  }

  Map<String, dynamic> _dadosJson() =>
      {'pastas': _pastas.map((p) => p.toJson()).toList()};

  // ---------- Consultas ----------

  bool estaSalvo(String artigoId) =>
      _pastas.any((p) => p.artigoIds.contains(artigoId));

  bool estaNaPasta(String pastaId, String artigoId) {
    for (final p in _pastas) {
      if (p.id == pastaId) return p.artigoIds.contains(artigoId);
    }
    return false;
  }

  /// Ids de todos os artigos salvos, sem repetição.
  Set<String> get todosOsIds => {for (final p in _pastas) ...p.artigoIds};

  Pasta? pastaPorId(String id) {
    for (final p in _pastas) {
      if (p.id == id) return p;
    }
    return null;
  }

  // ---------- Ações ----------

  /// Coloca o artigo na pasta, ou tira se já estiver.
  Future<void> alternar(String pastaId, String artigoId) async {
    final pasta = pastaPorId(pastaId);
    if (pasta == null) return;
    if (!pasta.artigoIds.remove(artigoId)) pasta.artigoIds.add(artigoId);
    notifyListeners();
    await _salvar();
  }

  /// Devolve a mensagem de erro, ou null se deu certo.
  String? validarNome(String nome, {String? ignorarId}) {
    final n = nome.trim();
    if (n.isEmpty) return 'Dê um nome à pasta.';
    if (n.length > tamanhoMaximoNome) {
      return 'Use no máximo $tamanhoMaximoNome caracteres.';
    }
    final repetido = _pastas.any(
      (p) => p.id != ignorarId && p.nome.toLowerCase() == n.toLowerCase(),
    );
    if (repetido) return 'Já existe uma pasta com esse nome.';
    return null;
  }

  Future<String?> criarPasta(String nome) async {
    final erro = validarNome(nome);
    if (erro != null) return erro;
    _pastas.add(Pasta(id: _novoId(), nome: nome.trim()));
    notifyListeners();
    await _salvar();
    return null;
  }

  Future<String?> renomear(String pastaId, String nome) async {
    final erro = validarNome(nome, ignorarId: pastaId);
    if (erro != null) return erro;
    final pasta = pastaPorId(pastaId);
    if (pasta == null) return 'Pasta não encontrada.';
    pasta.nome = nome.trim();
    notifyListeners();
    await _salvar();
    return null;
  }

  /// Excluir uma pasta remove os itens SÓ da biblioteca. Nada é apagado
  /// na fonte original.
  Future<void> excluir(String pastaId) async {
    _pastas.removeWhere((p) => p.id == pastaId);
    notifyListeners();
    await _salvar();
  }

  String exportarJson() => jsonEncode(_dadosJson());
}
