import 'package:flutter/foundation.dart';

import '../core/atividades.dart';
import '../core/intencao.dart';
import '../core/motor_ik_ai.dart';
import '../core/sem_emoji.dart';
import 'gemini_service.dart';

enum Autor { ia, usuario }

class Mensagem {
  final Autor autor;
  final String texto;

  /// Cartões de atividade que acompanham a fala da Ik AI.
  final List<Atividade> opcoes;

  /// Respostas rápidas (só a última mensagem da IA as mostra).
  final List<String> chips;

  const Mensagem(
    this.autor,
    this.texto, {
    this.opcoes = const [],
    this.chips = const [],
  });
}

typedef AoCombinar = void Function(Atividade atividade, String quando);

/// Controlador da conversa com a Ik AI (sem widgets, testável).
///
/// Garantias:
///  - Toda resposta do usuário recebe do app várias opções reais, mesmo sem
///    internet, sem chave ou sem autorização para o Gemini.
///  - O Gemini só entra se [usarGemini] estiver ligado (autorização do
///    usuário). Se falhar, o motor local responde, sem travar.
///  - Sinais de sofrimento sério nunca vão para a IA externa.
///  - Nome e e-mail nunca saem do aparelho.
class ChatIkAi extends ChangeNotifier {
  ChatIkAi({
    required this.estado,
    GeminiService? gemini,
    this.nome,
    this.objetivoTitulo = '',
    this.textoDaSessao = '',
    this.ocasiao = 'fim',
    this.minutosUsados = 0,
    this.rotacao = 0,
    bool usarGemini = false,
    this.aoCombinar,
  })  : _gemini = gemini ?? GeminiService.padrao,
        _usarGemini = usarGemini;

  static const int limiteTexto = 300;
  static const int limiteChamadasIa = 12;
  static const String chipRepetir = 'Pode repetir as ideias';
  static const String chipDescansar = 'Vou descansar um pouco';

  final EstadoConversa estado;
  final String? nome;
  final String objetivoTitulo;
  final String textoDaSessao;
  final String ocasiao;
  final int minutosUsados;
  final int rotacao;
  final AoCombinar? aoCombinar;
  final GeminiService _gemini;

  final List<Mensagem> _mensagens = [];
  final List<TurnoConversa> _turnos = [];
  List<Atividade> _ultimasOpcoes = const [];
  final Set<String> _titulosMostrados = {};
  Atividade? _aguardandoQuando;
  bool _pensando = false;
  bool _usarGemini;
  int _chamadasIa = 0;
  bool _iniciada = false;
  bool _fechado = false;

  /// Motivo de a última resposta ter vindo do motor local (para depuração).
  String? motivoLocal;

  /// Se a última resposta foi gerada pelo Gemini.
  bool ultimaViaGemini = false;

  List<Mensagem> get mensagens => List.unmodifiable(_mensagens);
  bool get pensando => _pensando;
  bool get usarGemini => _usarGemini;
  bool get aguardandoQuando => _aguardandoQuando != null;
  bool get geminiDisponivel => _gemini.configurado;

  /// A conversa já terminou em um combinado ou em descanso.
  bool get encerrada => _encerrada;
  bool _encerrada = false;

  set usarGemini(bool v) {
    if (_usarGemini == v) return;
    _usarGemini = v;
    notifyListeners();
  }

  @override
  void dispose() {
    _fechado = true;
    super.dispose();
  }

  void _avisar() {
    if (!_fechado) notifyListeners();
  }

  void iniciar() {
    if (_iniciada) return;
    _iniciada = true;
    final r = MotorIkAi.abertura(
      estado,
      nome: nome,
      ocasiao: ocasiao,
      minutosUsados: minutosUsados,
      rotacao: rotacao,
    );
    _adicionarIa(r);
    _avisar();
  }

  void _adicionarIa(RespostaIkAi r, {String? texto, List<Atividade>? opcoes}) {
    final ops = opcoes ?? r.opcoes;
    final fala = texto ?? r.texto;
    _mensagens.add(Mensagem(Autor.ia, fala, opcoes: ops, chips: r.chips));
    _turnos.add(TurnoConversa(daIa: true, texto: fala));
    if (ops.isNotEmpty) {
      _ultimasOpcoes = ops;
      for (final a in ops) {
        _titulosMostrados.add(a.titulo);
      }
    }
  }

  void _adicionarUsuario(String texto) {
    _mensagens.add(Mensagem(Autor.usuario, texto));
    _turnos.add(TurnoConversa(daIa: false, texto: texto));
  }

  /// O usuário tocou em "Vou fazer isso".
  void escolher(Atividade a) {
    if (_pensando || _encerrada) return;
    _adicionarUsuario('Vou fazer isso: ${a.titulo}');
    _aguardandoQuando = a;
    _adicionarIa(MotorIkAi.perguntarQuando(a));
    _avisar();
  }

  /// O usuário tocou em "Outra ideia" num cartão ou digitou algo.
  Future<void> enviar(String bruto) async {
    if (_pensando || _encerrada) return;
    var texto = removerEmojis(bruto).replaceAll(RegExp(r'\s+'), ' ').trim();
    if (texto.isEmpty) return;
    if (texto.length > limiteTexto) {
      texto = texto.substring(0, limiteTexto).trimRight();
    }
    _adicionarUsuario(texto);

    // 1) Sofrimento sério: encaminha para ajuda humana, sem IA externa.
    if (sinalDeCrise(texto)) {
      _aguardandoQuando = null;
      _adicionarIa(MotorIkAi.cuidado());
      _avisar();
      return;
    }

    // 2) Estamos combinando o "quando" de uma atividade.
    final pendente = _aguardandoQuando;
    if (pendente != null) {
      final i = interpretar(texto);
      if (!i.querOutras && !i.semIdeia) {
        _aguardandoQuando = null;
        aoCombinar?.call(pendente, texto);
        _adicionarIa(MotorIkAi.confirmarCombinado(pendente, texto));
        _encerrada = true;
        _avisar();
        return;
      }
      _aguardandoQuando = null; // desistiu daquela; segue a conversa
    }

    // 3) Respostas rápidas especiais.
    if (texto == chipDescansar) {
      _adicionarIa(const RespostaIkAi(
        'Boa ideia. Deixe o celular longe, olhe pela janela ou beba água '
        'devagar por alguns minutos. Quando voltar, eu pergunto como você '
        'está.',
        [],
        [],
      ));
      _encerrada = true;
      _avisar();
      return;
    }
    if (texto == chipRepetir) {
      estado.recusadas.clear();
    }

    // 4) O motor local sempre responde (e atualiza o estado).
    final local = MotorIkAi.responder(
      estado,
      texto == chipRepetir ? 'quero ver as ideias' : texto,
      rotacao: rotacao + _turnos.length,
      mostradas: _ultimasOpcoes,
    );

    // 5) Gemini, só se autorizado; falhou, vale o local.
    if (_usarGemini &&
        _gemini.configurado &&
        _chamadasIa < limiteChamadasIa &&
        local.opcoes.isNotEmpty) {
      _pensando = true;
      _avisar();
      _chamadasIa++;
      ResultadoConversa r;
      try {
        r = await _gemini.conversar(_contexto());
      } catch (e) {
        r = ResultadoConversa.falha('erro inesperado: ${e.runtimeType}');
      }
      _pensando = false;
      if (_fechado) return;
      if (r.ok) {
        final ia = r.resposta!;
        final ideias = ia.ideias.take(3).toList();
        // Completa com opções do app: sempre há pelo menos 2 caminhos.
        final completas = <Atividade>[...ideias];
        for (final a in local.opcoes) {
          if (completas.length >= 3) break;
          if (completas.length >= 2 && ideias.isNotEmpty) break;
          if (!completas.any((x) => x.titulo == a.titulo)) completas.add(a);
        }
        ultimaViaGemini = true;
        motivoLocal = null;
        _adicionarIa(
          local,
          texto: ia.texto.isNotEmpty ? ia.texto : local.texto,
          opcoes: completas,
        );
        _avisar();
        return;
      }
      motivoLocal = r.motivo;
    } else {
      motivoLocal = !_usarGemini
          ? 'Gemini desligado nesta conversa'
          : (!_gemini.configurado ? 'sem chave do Gemini' : null);
    }

    ultimaViaGemini = false;
    _adicionarIa(local);
    _avisar();
  }

  ContextoConversa _contexto() {
    return ContextoConversa(
      objetivoTitulo: objetivoTitulo,
      temasDeclarados: estado.temas.map(nomeDoTema).toList(),
      condicoes: estado.resumoDoContexto,
      textoDaSessao: textoDaSessao,
      turnos: List.of(_turnos),
      ideiasJaMostradas: _titulosMostrados.toList(),
      permitiuEnvio: _usarGemini,
    );
  }
}
