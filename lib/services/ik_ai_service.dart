import 'dart:convert';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/sem_emoji.dart';
import 'auth_service.dart';
import 'gemini_service.dart';

/// O que a Ik AI guardou, DECLARADO pelo próprio usuário (nada inferido).
class MemoriaIkAi {
  final List<String> vontades;
  final String? categoriaPrincipal;
  final String? detalhePrincipal;

  const MemoriaIkAi({
    this.vontades = const [],
    this.categoriaPrincipal,
    this.detalhePrincipal,
  });

  static const MemoriaIkAi vazia = MemoriaIkAi();

  bool get temDetalhe => (detalhePrincipal ?? '').trim().isNotEmpty;

  String toJson() => jsonEncode({
        'v': vontades,
        'c': categoriaPrincipal,
        'd': detalhePrincipal,
      });

  static MemoriaIkAi tentarLer(String? texto) {
    if (texto == null || texto.isEmpty) return vazia;
    try {
      final m = jsonDecode(texto);
      if (m is! Map) return vazia;
      final v = m['v'];
      final c = m['c'];
      final d = m['d'];
      return MemoriaIkAi(
        vontades: v is List ? v.whereType<String>().toList() : const [],
        categoriaPrincipal: c is String ? c : null,
        detalhePrincipal: d is String ? d : null,
      );
    } catch (_) {
      return vazia;
    }
  }
}

/// Camada de conversa da Ik AI (cadastro e fim da sessão).
///
/// Regras (as mesmas do resto do app):
///  - Só usa o que a pessoa DECLAROU. Sem nome inventado, sem livro padrão.
///  - O Gemini só é chamado com autorização explícita, e nunca recebe nome
///    nem e-mail (o nome é colocado na frase aqui, no aparelho).
///  - Perguntas de cadastro, confirmação e "sugerir outra coisa" são
///    geradas no aparelho: não gastam cota da API.
///  - A memória é gravada por conta e apagada ao sair/excluir a conta.
///  - Sem esperas falsas: a resposta local é imediata.
class IkAiService {
  IkAiService._();

  static const int limiteDetalhe = 300;
  static const String _kMemoria = 'ikai_memoria_v1';

  /// Instância do Gemini. Troque nos testes.
  @visibleForTesting
  static GeminiService gemini = GeminiService.padrao;

  static MemoriaIkAi _memoria = MemoriaIkAi.vazia;
  static String? _emailDaMemoria;

  static MemoriaIkAi get memoria => _memoria;

  // ---------------------------------------------------------------------
  // Memória por conta
  // ---------------------------------------------------------------------

  static Future<void> carregarPara(String email) async {
    _emailDaMemoria = email;
    _memoria = MemoriaIkAi.vazia;
    try {
      final p = await SharedPreferences.getInstance();
      // Se outra conta entrou enquanto lia, não mistura os dados.
      if (_emailDaMemoria != email) return;
      _memoria = MemoriaIkAi.tentarLer(p.getString('${_kMemoria}_$email'));
    } catch (_) {}
  }

  /// Esquece tudo em memória (sair da conta). O gravado permanece.
  static void limpar() {
    _emailDaMemoria = null;
    _memoria = MemoriaIkAi.vazia;
  }

  /// Apaga também o gravado (excluir conta).
  static Future<void> apagarDaConta() async {
    final email = _emailDaMemoria ?? AuthService.instance.usuarioAtual?.email;
    limpar();
    if (email == null) return;
    try {
      final p = await SharedPreferences.getInstance();
      await p.remove('${_kMemoria}_$email');
    } catch (_) {}
  }

  static String exportarJson() => _memoria.toJson();

  static Future<void> _gravar() async {
    final email = _emailDaMemoria ?? AuthService.instance.usuarioAtual?.email;
    if (email == null) return;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString('${_kMemoria}_$email', _memoria.toJson());
    } catch (_) {}
  }

  /// Compatível com a versão anterior. Só aceita dados que existam de
  /// verdade (nada de valores padrão inventados). `null` limpa tudo.
  static void definirUsuarioLogado(Map<String, dynamic>? usuario) {
    if (usuario == null) {
      limpar();
      return;
    }
    final v = usuario['vontades'];
    final c = usuario['categoriaPrincipal'];
    final d = usuario['detalhePrincipal'];
    _memoria = MemoriaIkAi(
      vontades: v is List ? v.whereType<String>().toList() : const [],
      categoriaPrincipal: c is String && c.trim().isNotEmpty ? c : null,
      detalhePrincipal: d is String && d.trim().isNotEmpty ? _limpar(d) : null,
    );
  }

  /// Dados da conta de agora, ou null se ninguém está conectado.
  static Map<String, dynamic>? get usuarioLogado {
    final u = AuthService.instance.usuarioAtual;
    if (u == null) return null;
    return {
      'nome': u.nome,
      'vontades': List<String>.of(_memoria.vontades),
      'categoriaPrincipal': _memoria.categoriaPrincipal,
      'detalhePrincipal': _memoria.detalhePrincipal,
    };
  }

  // ---------------------------------------------------------------------
  // Utilidades
  // ---------------------------------------------------------------------

  /// Texto do usuário: sem emojis, espaços normalizados, tamanho limitado.
  static String _limpar(String s) {
    var t = removerEmojis(s).replaceAll(RegExp(r'\s+'), ' ').trim();
    if (t.length > limiteDetalhe) t = t.substring(0, limiteDetalhe).trimRight();
    return t;
  }

  static String _primeiroNome(String? nome) {
    final n = (nome ?? AuthService.instance.usuarioAtual?.nome ?? '').trim();
    if (n.isEmpty) return '';
    return n.split(RegExp(r'\s+')).first;
  }

  /// "Nome, frase" quando há nome; senão só a frase com inicial maiúscula.
  static String _com(String nome, String frase) {
    if (nome.isNotEmpty) return '$nome, $frase';
    if (frase.isEmpty) return frase;
    return frase[0].toUpperCase() + frase.substring(1);
  }

  static String identificarCategoriaPrincipal(List<String> vontades) {
    if (vontades.contains('Ler mais')) return 'Ler mais';
    if (vontades.contains('Treinar mais')) return 'Treinar mais';
    if (vontades.contains('Estudar mais')) return 'Estudar mais';
    if (vontades.isNotEmpty) return vontades.first;
    return 'Ler mais';
  }

  // ---------------------------------------------------------------------
  // 1. Pergunta do cadastro (local)
  // ---------------------------------------------------------------------

  static Future<String> gerarPerguntaCadastro({
    String? nomeUsuario,
    required List<String> vontades,
  }) async {
    final n = _primeiroNome(nomeUsuario);
    final foco = identificarCategoriaPrincipal(vontades);

    switch (foco) {
      case 'Ler mais':
        return 'Que bom que você quer ler mais! '
            '${_com(n, 'qual livro você está lendo ou quer começar agora?')}';
      case 'Treinar mais':
        return 'Que bom que você quer treinar mais! '
            '${_com(n, 'qual atividade física ou esporte você mais gosta de fazer?')}';
      case 'Estudar mais':
        return 'Que bom que você quer estudar mais! '
            '${_com(n, 'qual matéria ou assunto você está estudando agora?')}';
      default:
        return 'Você quer focar em ${foco.toLowerCase()}. '
            '${_com(n, 'como você gosta de praticar isso no seu dia a dia?')}';
    }
  }

  // ---------------------------------------------------------------------
  // 2. Guarda a resposta de verdade e confirma (local)
  // ---------------------------------------------------------------------

  /// Só diz que guardou se de fato guardou. Resposta vazia não é guardada.
  static Future<String> confirmarMemoriaSalva({
    String? nomeUsuario,
    required String categoriaFoco,
    required String respostaUsuario,
  }) async {
    final n = _primeiroNome(nomeUsuario);
    final detalhe = _limpar(respostaUsuario);

    if (detalhe.isEmpty) {
      return 'Tudo bem, sem pressa. Você pode contar para a Ik AI quando '
          'quiser.';
    }

    final vontades = <String>{..._memoria.vontades, categoriaFoco}.toList();
    _memoria = MemoriaIkAi(
      vontades: vontades,
      categoriaPrincipal: categoriaFoco,
      detalhePrincipal: detalhe,
    );
    await _gravar();

    return 'Anotado${n.isEmpty ? '' : ', $n'}! Guardei "$detalhe" no seu '
        'perfil. Quando seu tempo no Ikai acabar, vou usar isso para sugerir '
        'o que fazer longe da tela.';
  }

  // ---------------------------------------------------------------------
  // 3. Mensagem do fim do tempo
  // ---------------------------------------------------------------------

  /// [permitiuEnvio] é a autorização explícita do usuário para enviar o
  /// detalhe ao Gemini. Sem ela (ou sem chave), a mensagem é local.
  static Future<String> gerarMensagemFimDeTempo({
    bool permitiuEnvio = false,
    int duracaoMinutos = 15,
    String? nomeUsuario,
  }) async {
    final n = _primeiroNome(nomeUsuario);

    if (!_memoria.temDetalhe) {
      // Sem dado declarado, a Ik AI não inventa nada.
      return _com(
        n,
        'seu tempo no Ikai acabou. O que você quer fazer agora, longe da '
        'tela?',
      );
    }

    final categoria = _memoria.categoriaPrincipal ?? 'Ikai';
    final detalhe = _memoria.detalhePrincipal!;

    if (permitiuEnvio && gemini.configurado) {
      final r = await gemini.gerarSugestoes(
        ContextoSessao(
          objetivoTitulo: categoria,
          categoriaTitulo: categoria,
          textoDeclarado: detalhe,
          duracaoMinutos: duracaoMinutos,
          permitiuEnvio: true,
        ),
      );
      if (r.fonte == FonteSugestoes.gemini && r.itens.isNotEmpty) {
        return _com(n, 'seu tempo no Ikai acabou. ${r.itens.first}');
      }
    }

    switch (categoria) {
      case 'Ler mais':
        return _com(n,
            'seu tempo no Ikai acabou. Que tal ler algumas páginas de $detalhe agora?');
      case 'Treinar mais':
        return _com(n,
            'seu tempo no Ikai acabou. Que tal separar uns minutos para o seu treino ($detalhe) agora?');
      case 'Estudar mais':
        return _com(n,
            'seu tempo no Ikai acabou. Que tal dedicar alguns minutos a $detalhe agora?');
      default:
        return _com(n,
            'seu tempo no Ikai acabou. Que tal aproveitar para focar em $detalhe?');
    }
  }

  // ---------------------------------------------------------------------
  // 4. Outra sugestão quando a pessoa recusa (local)
  // ---------------------------------------------------------------------

  /// Escolhe a próxima vontade que a PESSOA declarou e ainda não foi
  /// recusada, e a anota em [historicoSugestoesRecusadas] (sempre, não só
  /// em alguns caminhos). [mensagemDoUsuario] não é enviada a nenhum
  /// serviço.
  static Future<String> sugerirOutraCoisa({
    required String mensagemDoUsuario,
    required List<String> historicoSugestoesRecusadas,
    String? nomeUsuario,
  }) async {
    final n = _primeiroNome(nomeUsuario);
    final principal = _memoria.categoriaPrincipal;

    final candidatas = _memoria.vontades
        .where((v) =>
            v != principal && !historicoSugestoesRecusadas.contains(v))
        .toList();

    if (candidatas.isEmpty) {
      return _com(
        n,
        'o momento é seu. Que tal beber um copo d\'água e descansar a vista '
        'das telas por alguns minutos?',
      );
    }

    final proxima = candidatas.first;
    historicoSugestoesRecusadas.add(proxima);

    switch (proxima) {
      case 'Treinar mais':
        return _com(n,
            'sem problemas, você também quer treinar mais. Que tal um alongamento ou um treino rápido de 15 minutos agora?');
      case 'Estudar mais':
        return _com(n,
            'tudo bem, você também quer estudar mais. Que tal revisar um tópico rápido ou organizar suas metas da semana fora da tela?');
      case 'Dormir melhor':
        return _com(n,
            'tudo bem, que tal preparar o ambiente, baixar as luzes e descansar a mente longe do celular?');
      case 'Meditar':
        return _com(n,
            'tudo bem, que tal 3 minutos de respiração profunda, de olhos fechados?');
      default:
        return _com(n,
            'tudo bem, você também quer "$proxima". Que tal usar este momento fora do app para se dedicar um pouco a isso?');
    }
  }
}
