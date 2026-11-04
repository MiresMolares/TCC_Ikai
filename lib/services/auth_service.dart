import 'package:flutter/foundation.dart';

import 'dados_mock.dart';

class UsuarioApp {
  final String nome;
  final String email;
  const UsuarioApp({required this.nome, required this.email});

  /// Primeiro nome, para saudações.
  String get primeiroNome {
    final partes = nome.trim().split(RegExp(r'\s+'));
    return partes.isEmpty || partes.first.isEmpty ? nome : partes.first;
  }
}

/// Contas de MENTIRA, só em memória, até existir o back-end.
///
/// Usa a lista `usuarios` de `dados_mock.dart` (conta de teste:
/// adm@email.com / 1234). Ao fechar o app, contas criadas somem.
/// Quando o banco de dados chegar, troque o corpo dos métodos abaixo por
/// chamadas à API; o resto do app continua igual, pois só usa esta classe.
/// Todos os métodos que podem falhar devolvem a mensagem de erro, ou null
/// em caso de sucesso.
class AuthService extends ChangeNotifier {
  AuthService._();
  static final AuthService instance = AuthService._();

  UsuarioApp? _atual;
  UsuarioApp? get usuarioAtual => _atual;
  bool get logado => _atual != null;

  static final RegExp _padraoEmail = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  static const int tamanhoMinimoSenha = 4;

  static bool emailValido(String email) => _padraoEmail.hasMatch(email.trim());

  Map<String, String>? _buscar(String email) {
    final e = email.trim().toLowerCase();
    for (final u in usuarios) {
      if ((u['email'] ?? '').toLowerCase() == e) return u;
    }
    return null;
  }

  String? entrar(String email, String senha) {
    if (email.trim().isEmpty || senha.isEmpty) {
      return 'Preencha e-mail e senha.';
    }
    if (!emailValido(email)) return 'Informe um e-mail válido.';
    final u = _buscar(email);
    if (u == null || u['senha'] != senha) {
      return 'E-mail ou senha incorretos.';
    }
    _atual = UsuarioApp(nome: u['nome'] ?? '', email: u['email'] ?? '');
    notifyListeners();
    return null;
  }

  String? cadastrar({
    required String nome,
    required String email,
    required String senha,
  }) {
    if (nome.trim().length < 2) return 'Informe seu nome completo.';
    if (!emailValido(email)) return 'Informe um e-mail válido.';
    if (senha.length < tamanhoMinimoSenha) {
      return 'A senha deve ter pelo menos $tamanhoMinimoSenha caracteres.';
    }
    if (_buscar(email) != null) return 'Este e-mail já está cadastrado.';
    usuarios.add({
      'nome': nome.trim(),
      'email': email.trim().toLowerCase(),
      'senha': senha,
    });
    return null;
  }

  /// Sempre "funciona" para não revelar quais e-mails existem.
  /// Nenhuma mensagem é enviada de verdade até existir o back-end.
  String? recuperarSenha(String email) {
    if (!emailValido(email)) return 'Informe um e-mail válido.';
    return null;
  }

  void sair() {
    _atual = null;
    notifyListeners();
  }

  String? atualizarPerfil({required String nome, required String email}) {
    final atual = _atual;
    if (atual == null) return 'Você não está conectado.';
    if (nome.trim().length < 2) {
      return 'O nome deve ter pelo menos 2 caracteres.';
    }
    if (!emailValido(email)) return 'Informe um e-mail válido.';
    final registro = _buscar(atual.email);
    final outro = _buscar(email);
    if (outro != null && !identical(outro, registro)) {
      return 'Este e-mail já está em uso.';
    }
    if (registro != null) {
      registro['nome'] = nome.trim();
      registro['email'] = email.trim().toLowerCase();
    }
    _atual = UsuarioApp(
      nome: nome.trim(),
      email: email.trim().toLowerCase(),
    );
    notifyListeners();
    return null;
  }

  String? alterarSenha({required String atual, required String nova}) {
    final u = _atual;
    if (u == null) return 'Você não está conectado.';
    final registro = _buscar(u.email);
    if (registro == null || registro['senha'] != atual) {
      return 'A senha atual está incorreta.';
    }
    if (nova.length < tamanhoMinimoSenha) {
      return 'A nova senha deve ter pelo menos $tamanhoMinimoSenha '
          'caracteres.';
    }
    registro['senha'] = nova;
    return null;
  }

  void excluirConta() {
    final u = _atual;
    if (u != null) {
      usuarios.removeWhere(
        (r) => (r['email'] ?? '').toLowerCase() == u.email.toLowerCase(),
      );
    }
    sair();
  }
}
