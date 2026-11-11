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

/// O que a conversa de FIM DO DIA pode fazer no app. O chat só conversa;
/// quem muda o estado do dia é quem implementa isto (veja chat_fabrica.dart).
abstract class AcoesFimDoDia {
  /// A pessoa pediu para encerrar antes de o tempo acabar.
  bool get voluntario;
  bool get podeProrrogar;
  int get prorrogacoesRestantes;
  int get maxProrrogacoes;
  List<int> get opcoesProrrogacao;

  /// Ex.: "45 min de 45 min".
  String get resumoDeUso;

  bool registrarAprendizado(String texto);
  bool prorrogar(int minutos, String motivo);
  bool voltarAoApp();
  void encerrarPorHoje();
}

enum _EtapaFim { nenhuma, aprendi, motivo, tempo }

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
    this.fimDoDia,
  })  : _gemini = gemini ?? GeminiService.padrao,
        _usarGemini = usarGemini;

  static const int limiteTexto = 300;
  static const int limiteChamadasIa = 12;
  static const String chipRepetir = 'Pode repetir as ideias';
  static const String chipDescansar = 'Vou descansar um pouco';

  // Conversa de fim do dia.
  static const String chipAprendi = 'Contar o que aprendi';
  static const String chipContinuar = 'Quero continuar';
  static const String chipVoltar = 'Voltar ao app';
  static const String chipIdeias = 'Ideias longe da tela';
  static const String chipEncerrar = 'Encerrar por hoje';
  static const String chipMudei = 'Mudei de ideia';

  final EstadoConversa estado;
  final String? nome;
  final String objetivoTitulo;
  final String textoDaSessao;
  final String ocasiao;
  final int minutosUsados;
  final int rotacao;
  final AoCombinar? aoCombinar;

  /// Não nulo = esta é a conversa de fim do dia (o tempo acabou ou a pessoa
  /// pediu para encerrar).
  final AcoesFimDoDia? fimDoDia;
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
  _EtapaFim _etapaFim = _EtapaFim.nenhuma;
  String _motivoFim = '';

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
    if (fimDoDia != null) {
      _adicionarIa(_aberturaDoFim());
      _avisar();
      return;
    }
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

  void _adicionarIa(
    RespostaIkAi r, {
    String? texto,
    List<Atividade>? opcoes,
    List<String>? chips,
  }) {
    final ops = opcoes ?? r.opcoes;
    final fala = texto ?? r.texto;
    _mensagens.add(
      Mensagem(Autor.ia, fala, opcoes: ops, chips: chips ?? r.chips),
    );
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

  // ---------- Conversa de fim do dia ----------

  List<String> _chipsFim() => [
        chipAprendi,
        fimDoDia!.voluntario ? chipVoltar : chipContinuar,
        chipIdeias,
        chipEncerrar,
      ];

  /// Chips da conversa de ideias + os caminhos de saída do fim do dia.
  List<String> _comChipsFim(List<String> chips) {
    final f = fimDoDia;
    if (f == null) return chips;
    final saida = <String>[
      f.voluntario ? chipVoltar : chipContinuar,
      chipEncerrar,
    ];
    return [
      ...chips.where((c) => !saida.contains(c)).take(4),
      ...saida,
    ];
  }

  RespostaIkAi _aberturaDoFim() {
    final f = fimDoDia!;
    final quem = (nome == null || nome!.isEmpty) ? '' : '$nome, ';
    final texto = f.voluntario
        ? '${quem}você quer encerrar o dia com ${f.resumoDeUso} de uso. '
            'Antes, quer contar o que levou daqui?'
        : '${quem.isEmpty ? 'Seu' : '${quem}seu'} tempo de hoje no Ikai '
            'acabou: ${f.resumoDeUso}. O que você quer fazer agora?';
    return RespostaIkAi(texto, const [], _chipsFim());
  }

  /// Trata os passos do fim do dia. Devolve true se tratou a mensagem.
  bool _tratarFim(String texto) {
    final f = fimDoDia!;

    if (texto == chipEncerrar) {
      _etapaFim = _EtapaFim.nenhuma;
      _adicionarIa(const RespostaIkAi(
        'Combinado. Seu dia no Ikai fica por aqui. Até amanhã.',
        [],
        [],
      ));
      _encerrada = true;
      f.encerrarPorHoje();
      return true;
    }

    if (texto == chipVoltar && f.voluntario) {
      _etapaFim = _EtapaFim.nenhuma;
      _adicionarIa(const RespostaIkAi('Certo, pode voltar.', [], []));
      _encerrada = true;
      f.voltarAoApp();
      return true;
    }

    if (texto == chipAprendi) {
      _etapaFim = _EtapaFim.aprendi;
      _adicionarIa(const RespostaIkAi(
        'Conte com as suas palavras: o que você aprendeu ou levou daqui hoje?',
        [],
        [],
      ));
      return true;
    }

    if (texto == chipContinuar && !f.voluntario) {
      if (!f.podeProrrogar) {
        _etapaFim = _EtapaFim.nenhuma;
        _adicionarIa(RespostaIkAi(
          'Você já estendeu seu tempo ${f.maxProrrogacoes} vezes '
          'hoje, que é o limite. O que você prefere?',
          const [],
          [chipAprendi, chipIdeias, chipEncerrar],
        ));
        return true;
      }
      _etapaFim = _EtapaFim.motivo;
      _adicionarIa(const RespostaIkAi(
        'Me conte, em uma frase: por que você quer continuar?',
        [],
        [],
      ));
      return true;
    }

    if (texto == chipIdeias) {
      _etapaFim = _EtapaFim.nenhuma;
      final r = MotorIkAi.abertura(
        estado,
        nome: nome,
        ocasiao: 'fim',
        rotacao: rotacao + _turnos.length,
      );
      _adicionarIa(
        r,
        texto: 'Aqui estão ideias para depois daqui. Me conte onde está, '
            'quanto tempo tem e como está a energia, e eu ajusto.',
        chips: _comChipsFim(r.chips),
      );
      return true;
    }

    switch (_etapaFim) {
      case _EtapaFim.aprendi:
        if (!f.registrarAprendizado(texto)) return false;
        _etapaFim = _EtapaFim.nenhuma;
        _adicionarIa(RespostaIkAi(
          'Anotei: "$texto". Isso fica guardado só no seu aparelho.',
          const [],
          _chipsFimSemAprendi(),
        ));
        return true;

      case _EtapaFim.motivo:
        if (texto.length < 3) {
          _adicionarIa(const RespostaIkAi(
            'Pode escrever um pouco mais? Uma frase já basta.',
            [],
            [],
          ));
          return true;
        }
        _motivoFim = texto;
        _etapaFim = _EtapaFim.tempo;
        final restam = f.prorrogacoesRestantes;
        _adicionarIa(RespostaIkAi(
          'Entendi: "$texto". Quanto tempo a mais você quer? Você ainda pode '
          'estender $restam ${restam == 1 ? 'vez' : 'vezes'} hoje.',
          const [],
          [for (final m in f.opcoesProrrogacao) '$m min', chipMudei],
        ));
        return true;

      case _EtapaFim.tempo:
        if (texto == chipMudei) {
          _etapaFim = _EtapaFim.nenhuma;
          _adicionarIa(RespostaIkAi(
            'Tudo bem. O que você prefere?',
            const [],
            _chipsFimSemAprendi(),
          ));
          return true;
        }
        final m = int.tryParse(texto.replaceAll(RegExp(r'[^0-9]'), ''));
        if (m != null && f.prorrogar(m, _motivoFim)) {
          _etapaFim = _EtapaFim.nenhuma;
          _adicionarIa(RespostaIkAi('Combinado: mais $m min.', const [], const []));
          _encerrada = true;
          return true;
        }
        _adicionarIa(RespostaIkAi(
          'Escolha uma das opções de tempo, ou diga que mudou de ideia.',
          const [],
          [for (final m in f.opcoesProrrogacao) '$m min', chipMudei],
        ));
        return true;

      case _EtapaFim.nenhuma:
        return false;
    }
  }

  List<String> _chipsFimSemAprendi() =>
      _chipsFim().where((c) => c != chipAprendi).toList();

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
      _etapaFim = _EtapaFim.nenhuma;
      _adicionarIa(MotorIkAi.cuidado(), chips: fimDoDia == null ? null : _chipsFim());
      _avisar();
      return;
    }

    // 1b) Passos da conversa de fim do dia.
    if (fimDoDia != null && _aguardandoQuando == null && _tratarFim(texto)) {
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
        if (fimDoDia != null) {
          // No fim do dia a conversa continua: ainda falta decidir o resto.
          _adicionarIa(
            MotorIkAi.confirmarCombinado(pendente, texto),
            chips: _chipsFim(),
          );
        } else {
          _adicionarIa(MotorIkAi.confirmarCombinado(pendente, texto));
          _encerrada = true;
        }
        _avisar();
        return;
      }
      _aguardandoQuando = null; // desistiu daquela; segue a conversa
    }

    // 3) Respostas rápidas especiais.
    if (texto == chipDescansar) {
      const fala = 'Boa ideia. Deixe o celular longe, olhe pela janela ou beba '
          'água devagar por alguns minutos.';
      if (fimDoDia != null) {
        _adicionarIa(const RespostaIkAi(fala, [], []), chips: _chipsFim());
      } else {
        _adicionarIa(const RespostaIkAi(
          '$fala Quando voltar, eu pergunto como você está.',
          [],
          [],
        ));
        _encerrada = true;
      }
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
          chips: _comChipsFim(local.chips),
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
    _adicionarIa(local, chips: _comChipsFim(local.chips));
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
