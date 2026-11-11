import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Resposta crua da API.
class RespostaApi {
  final int status;
  final String corpo;
  const RespostaApi(this.status, this.corpo);
}

/// Erro da API, com a mensagem pronta para mostrar à pessoa.
class ErroApi implements Exception {
  /// 0 quando nem chegou ao servidor (sem rede, tempo esgotado).
  final int status;
  final String mensagem;
  const ErroApi(this.status, this.mensagem);

  @override
  String toString() => 'ErroApi($status): $mensagem';
}

typedef EnviarApi = Future<RespostaApi> Function(
  String metodo,
  Uri url,
  Map<String, String> cabecalhos,
  String? corpo,
  Duration limite,
);

Future<RespostaApi> _enviarPadrao(
  String metodo,
  Uri url,
  Map<String, String> cabecalhos,
  String? corpo,
  Duration limite,
) async {
  final Future<http.Response> f;
  switch (metodo) {
    case 'GET':
      f = http.get(url, headers: cabecalhos);
    case 'POST':
      f = http.post(url, headers: cabecalhos, body: corpo);
    case 'PATCH':
      f = http.patch(url, headers: cabecalhos, body: corpo);
    case 'DELETE':
      f = http.delete(url, headers: cabecalhos);
    default:
      throw ArgumentError('Método não suportado: $metodo');
  }
  final r = await f.timeout(limite);
  return RespostaApi(r.statusCode, utf8.decode(r.bodyBytes));
}

/// Conversa com a API do Ikai (a pasta `backend/`).
///
/// Para ligar o banco de dados, rode o app com o endereço da API:
///   flutter run -d chrome --dart-define-from-file=env.json
/// com `"API_URL": "http://localhost:3000"` no env.json. Sem API_URL o app
/// funciona como antes: contas de teste e dados só neste aparelho.
class ApiClient {
  ApiClient({String? baseUrl, EnviarApi? enviar, Duration? limite})
      : baseUrl = _semBarraFinal(baseUrl ?? _urlDoAmbiente),
        _enviar = enviar ?? _enviarPadrao,
        _limite = limite ?? const Duration(seconds: 20);

  static const String _urlDoAmbiente = String.fromEnvironment('API_URL');

  static final ApiClient instance = ApiClient();

  static String _semBarraFinal(String s) {
    var t = s.trim();
    while (t.endsWith('/')) {
      t = t.substring(0, t.length - 1);
    }
    return t;
  }

  final String baseUrl;
  final EnviarApi _enviar;
  final Duration _limite;

  /// Token de login (só em memória: fechar o app pede login de novo).
  String? token;

  /// O servidor tem a chave do Gemini (vem na resposta do login).
  bool iaNoServidor = false;

  bool get ativo => baseUrl.isNotEmpty;

  Map<String, String> get cabecalhos => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Uri url(String caminho) => Uri.parse('$baseUrl$caminho');

  void limparSessao() {
    token = null;
    iaNoServidor = false;
  }

  /// Faz a chamada. Devolve o JSON já lido (ou null se não houver corpo).
  /// Lança [ErroApi] com mensagem em português.
  Future<Object?> pedir(String metodo, String caminho, {Object? corpo}) async {
    if (!ativo) throw const ErroApi(0, 'O servidor não está configurado.');
    final RespostaApi r;
    try {
      r = await _enviar(
        metodo,
        url(caminho),
        cabecalhos,
        corpo == null ? null : jsonEncode(corpo),
        _limite,
      );
    } on TimeoutException {
      throw const ErroApi(0, 'O servidor demorou para responder.');
    } catch (_) {
      throw const ErroApi(0, 'Sem conexão com o servidor.');
    }

    Object? dados;
    if (r.corpo.trim().isNotEmpty) {
      try {
        dados = jsonDecode(r.corpo);
      } catch (_) {
        dados = null;
      }
    }
    if (r.status >= 200 && r.status < 300) return dados;

    var msg = 'Algo deu errado (código ${r.status}). Tente de novo.';
    if (dados is Map && dados['erro'] is String) {
      msg = dados['erro'] as String;
    }
    throw ErroApi(r.status, msg);
  }
}
