import 'package:flutter/foundation.dart';

import 'api_client.dart';
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

/// Login e conta.
///
/// Dois modos, escolhidos pelo `API_URL` (veja [ApiClient]):
///  - COM `API_URL`: tudo vai para a API (`backend/`): senha com hash no
///    MongoDB, token de login, exclusão de conta de verdade.
///  - SEM `API_URL`: contas de MENTIRA só em memória (lista `usuarios` de
///    `dados_mock.dart`; conta de teste: adm@email.com / 1234). Ao fechar o
///    app, contas criadas somem.
///
/// Os métodos que podem falhar devolvem a mensagem de erro, ou null em caso
/// de sucesso. São assíncronos porque a API é.
class AuthService extends ChangeNotifier {
  AuthService._(this._api);
  static final AuthService instance = AuthService._(ApiClient.instance);

  @visibleForTesting
  AuthService.paraTeste(ApiClient api) : _api = api;

  final ApiClient _api;

  UsuarioApp? _atual;
  UsuarioApp? get usuarioAtual => _atual;
  bool get logado => _atual != null;

  static final RegExp _padraoEmail = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  static const int tamanhoMinimoSenha = 4;

  /// Com a API, o servidor exige 8 (veja backend/src/rotas/auth.js).
  int get senhaMinima => _api.ativo ? 8 : tamanhoMinimoSenha;

  static bool emailValido(String email) => _padraoEmail.hasMatch(email.trim());

  Map<String, String>? _buscar(String email) {
    final e = email.trim().toLowerCase();
    for (final u in usuarios) {
      if ((u['email'] ?? '').toLowerCase() == e) return u;
    }
    return null;
  }

  /// Guarda o token e a pessoa que a API devolveu no login.
  void _aplicarLogin(Object? dados) {
    if (dados is! Map) throw const ErroApi(0, 'Resposta inesperada do servidor.');
    final token = dados['token'];
    final u = dados['usuario'];
    if (token is! String || u is! Map) {
      throw const ErroApi(0, 'Resposta inesperada do servidor.');
    }
    _api.token = token;
    _api.iaNoServidor = dados['ia'] == true;
    _atual = UsuarioApp(
      nome: (u['nome'] ?? '').toString(),
      email: (u['email'] ?? '').toString(),
    );
    notifyListeners();
  }

  Future<String?> entrar(String email, String senha) async {
    if (email.trim().isEmpty || senha.isEmpty) {
      return 'Preencha e-mail e senha.';
    }
    if (!emailValido(email)) return 'Informe um e-mail válido.';
    if (_api.ativo) {
      try {
        _aplicarLogin(await _api.pedir(
          'POST',
          '/auth/login',
          corpo: {'email': email.trim(), 'senha': senha},
        ));
        return null;
      } on ErroApi catch (e) {
        return e.mensagem;
      }
    }
    final u = _buscar(email);
    if (u == null || u['senha'] != senha) {
      return 'E-mail ou senha incorretos.';
    }
    _atual = UsuarioApp(nome: u['nome'] ?? '', email: u['email'] ?? '');
    notifyListeners();
    return null;
  }

  Future<String?> cadastrar({
    required String nome,
    required String email,
    required String senha,
  }) async {
    if (nome.trim().length < 2) return 'Informe seu nome completo.';
    if (!emailValido(email)) return 'Informe um e-mail válido.';
    if (senha.length < senhaMinima) {
      return 'A senha deve ter pelo menos $senhaMinima caracteres.';
    }
    if (_api.ativo) {
      try {
        // Cria a conta; a pessoa entra em seguida, pela tela de login.
        await _api.pedir('POST', '/auth/cadastro', corpo: {
          'nome': nome.trim(),
          'email': email.trim(),
          'senha': senha,
        });
        return null;
      } on ErroApi catch (e) {
        return e.mensagem;
      }
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
  /// Nenhuma mensagem é enviada de verdade ainda (falta um serviço de
  /// e-mail na API).
  String? recuperarSenha(String email) {
    if (!emailValido(email)) return 'Informe um e-mail válido.';
    return null;
  }

  void sair() {
    _atual = null;
    _servidorApagou = false;
    _api.limparSessao();
    notifyListeners();
  }

  Future<String?> atualizarPerfil({
    required String nome,
    required String email,
  }) async {
    final atual = _atual;
    if (atual == null) return 'Você não está conectado.';
    if (nome.trim().length < 2) {
      return 'O nome deve ter pelo menos 2 caracteres.';
    }
    if (!emailValido(email)) return 'Informe um e-mail válido.';
    if (_api.ativo) {
      try {
        // O e-mail identifica a conta e não muda por aqui.
        final d = await _api.pedir('PATCH', '/auth/eu', corpo: {
          'nome': nome.trim(),
        });
        final u = d is Map ? d['usuario'] : null;
        _atual = UsuarioApp(
          nome: u is Map ? (u['nome'] ?? nome.trim()).toString() : nome.trim(),
          email: atual.email,
        );
        notifyListeners();
        return null;
      } on ErroApi catch (e) {
        return e.mensagem;
      }
    }
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

  Future<String?> alterarSenha({
    required String atual,
    required String nova,
  }) async {
    final u = _atual;
    if (u == null) return 'Você não está conectado.';
    if (_api.ativo) {
      if (nova.length < senhaMinima) {
        return 'A nova senha deve ter pelo menos $senhaMinima caracteres.';
      }
      try {
        await _api.pedir('POST', '/auth/senha',
            corpo: {'atual': atual, 'nova': nova});
        return null;
      } on ErroApi catch (e) {
        return e.mensagem;
      }
    }
    final registro = _buscar(u.email);
    if (registro == null || registro['senha'] != atual) {
      return 'A senha atual está incorreta.';
    }
    if (nova.length < senhaMinima) {
      return 'A nova senha deve ter pelo menos $senhaMinima '
          'caracteres.';
    }
    registro['senha'] = nova;
    return null;
  }

  bool _servidorApagou = false;

  /// Com a API, apaga no servidor a conta e tudo o que a pessoa escreveu.
  /// Sem a API não faz nada. Devolve a mensagem de erro, ou null.
  /// Chame ANTES de limpar os dados do aparelho: se falhar, nada é perdido.
  Future<String?> apagarNoServidor() async {
    if (_atual == null || !_api.ativo || _servidorApagou) return null;
    try {
      await _api.pedir('DELETE', '/meus-dados');
      _servidorApagou = true;
      return null;
    } on ErroApi catch (e) {
      return e.mensagem;
    }
  }

  /// Exclui a conta (no servidor, se ainda não foi) e sai.
  /// Devolve a mensagem de erro (e NÃO sai) se o servidor falhar.
  Future<String?> excluirConta() async {
    final u = _atual;
    if (u == null) return null;
    final erro = await apagarNoServidor();
    if (erro != null) return erro;
    if (!_api.ativo) {
      usuarios.removeWhere(
        (r) => (r['email'] ?? '').toLowerCase() == u.email.toLowerCase(),
      );
    }
    sair();
    return null;
  }
}
