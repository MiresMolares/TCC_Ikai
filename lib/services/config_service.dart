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

  static const double textoMinimo = 0.8;
  static const double textoMaximo = 1.4;

  bool _notificacoes = false;
  double _tamanhoTexto = 1.0;

  bool get notificacoes => _notificacoes;
  double get tamanhoTexto => _tamanhoTexto;

  Future<void> carregar() async {
    try {
      final p = await SharedPreferences.getInstance();
      _notificacoes = p.getBool(_kNotificacoes) ?? false;
      final t = p.getDouble(_kTexto) ?? 1.0;
      _tamanhoTexto = t.clamp(textoMinimo, textoMaximo).toDouble();
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
}
