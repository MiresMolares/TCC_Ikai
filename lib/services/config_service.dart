import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preferências do aparelho que realmente têm efeito no app.
///
/// Notificações começam DESLIGADAS (Pilar 6: low dopamine). O usuário
/// precisa ativá-las de forma consciente.
class ConfigService extends ChangeNotifier {
  ConfigService._();
  static final ConfigService instance = ConfigService._();

  static const _kNotificacoes = 'cfg_notificacoes';
  static const _kTexto = 'cfg_tamanho_texto';
  static const _kNivel = 'cfg_nivel_conteudo';

  static const double textoMinimo = 0.8;
  static const double textoMaximo = 1.4;

  bool _notificacoes = false;
  double _tamanhoTexto = 1.0;
  int _nivelConteudo = 0;

  bool get notificacoes => _notificacoes;
  double get tamanhoTexto => _tamanhoTexto;

  /// Nível de dificuldade que o usuário quer ver: 0 todos, 1 a 3.
  int get nivelConteudo => _nivelConteudo;

  Future<void> carregar() async {
    try {
      final p = await SharedPreferences.getInstance();
      _notificacoes = p.getBool(_kNotificacoes) ?? false;
      final t = p.getDouble(_kTexto) ?? 1.0;
      _tamanhoTexto = t.clamp(textoMinimo, textoMaximo).toDouble();
      final n = p.getInt(_kNivel) ?? 0;
      _nivelConteudo = (n >= 0 && n <= 3) ? n : 0;
    } catch (_) {
      // Sem armazenamento, usa os padrões.
    }
    notifyListeners();
  }

  Future<void> definirNotificacoes(bool valor) async {
    _notificacoes = valor;
    notifyListeners();
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(_kNotificacoes, valor);
    } catch (_) {}
  }

  Future<void> definirTamanhoTexto(double valor) async {
    _tamanhoTexto = valor.clamp(textoMinimo, textoMaximo).toDouble();
    notifyListeners();
    try {
      final p = await SharedPreferences.getInstance();
      await p.setDouble(_kTexto, _tamanhoTexto);
    } catch (_) {}
  }

  Future<void> definirNivelConteudo(int nivel) async {
    if (nivel < 0 || nivel > 3) return;
    _nivelConteudo = nivel;
    notifyListeners();
    try {
      final p = await SharedPreferences.getInstance();
      await p.setInt(_kNivel, nivel);
    } catch (_) {}
  }
}
