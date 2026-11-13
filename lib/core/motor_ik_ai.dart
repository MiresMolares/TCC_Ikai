import 'atividades.dart';
import 'intencao.dart';

/// Memória da conversa, só com o que o usuário declarou.
class EstadoConversa {
  /// Temas declarados na etapa "Ik AI", na memória do perfil ou no chat.
  final Set<Tema> temas;

  final Set<Material> semMaterial;
  int? minutos;
  int? energiaMaxima;
  Local? local;

  /// Atividades que o usuário recusou ou que já foram mostradas.
  final Set<String> recusadas;

  EstadoConversa({
    Set<Tema>? temas,
    Set<Material>? semMaterial,
    this.minutos,
    this.energiaMaxima,
    this.local,
    Set<String>? recusadas,
  })  : temas = temas ?? <Tema>{},
        semMaterial = semMaterial ?? <Material>{},
        recusadas = recusadas ?? <String>{};

  /// Resumo curto do que o usuário contou sobre as condições dele.
  String get resumoDoContexto {
    final partes = <String>[];
    for (final m in semMaterial) {
      switch (m) {
        case Material.livro:
          partes.add('sem o livro');
        case Material.caderno:
          partes.add('sem papel e caneta');
        case Material.instrumento:
          partes.add('sem o instrumento');
      }
    }
    if (minutos != null) partes.add('com $minutos minutos');
    if (energiaMaxima != null && energiaMaxima! <= 1) {
      partes.add('com pouca energia');
    }
    if (local == Local.casa) partes.add('em casa');
    if (local == Local.fora) partes.add('fora de casa');
    return partes.join(', ');
  }
}

class RespostaIkAi {
  final String texto;
  final List<Atividade> opcoes;

  /// Frases prontas que o usuário pode tocar para responder.
  final List<String> chips;

  const RespostaIkAi(this.texto, this.opcoes, this.chips);
}

/// Motor local da Ik AI: funciona sem internet e sem chave. Dart puro.
///
/// Princípios: (1) sempre devolve VÁRIAS opções reais; (2) só usa o que o
/// usuário declarou; (3) reflete o que ele disse em vez de presumir;
/// (4) nunca insiste na mesma sugestão.
class MotorIkAi {
  MotorIkAi._();

  static const int quantidade = 3;

  static const String chipOutra = 'Quero outra ideia';
  static const String chipSemLivro = 'Não tenho meu livro';
  static const String chipSemCaderno = 'Não tenho papel nem caneta';
  static const String chipCansado = 'Estou cansado';
  static const String chipPoucoTempo = 'Tenho 10 minutos';
  static const String chipFora = 'Estou fora de casa';

  /// Escolhe até [quantidade] atividades que cabem nas condições dadas.
  /// [rotacao] muda o ponto de partida, para sessões diferentes não
  /// repetirem sempre as mesmas opções.
  static List<Atividade> selecionar(
    EstadoConversa e, {
    int rotacao = 0,
    int quantidade = MotorIkAi.quantidade,
  }) {
    bool cabe(Atividade a) {
      if (e.recusadas.contains(a.id)) return false;
      if (a.precisa.any(e.semMaterial.contains)) return false;
      if (e.minutos != null && a.minutos > e.minutos!) return false;
      if (e.energiaMaxima != null && a.energia > e.energiaMaxima!) {
        return false;
      }
      if (e.local != null &&
          a.local != Local.qualquer &&
          a.local != e.local) {
        return false;
      }
      return true;
    }

    final candidatas = catalogoDeAtividades.where(cabe).toList();
    if (candidatas.isEmpty) return const [];

    final escolhidas = <Atividade>[];
    final temasUsados = <Tema?>{};

    void pegar(bool Function(Atividade) criterio, {bool diverso = true}) {
      // A rotação gira cada grupo separadamente: assim ela muda a primeira
      // opção de cada critério, e não só a posição no catálogo inteiro.
      final grupo = candidatas.where(criterio).toList();
      if (grupo.isNotEmpty && rotacao != 0) {
        final k = rotacao % grupo.length;
        grupo.addAll(grupo.sublist(0, k));
        grupo.removeRange(0, k);
      }
      for (final a in grupo) {
        if (escolhidas.length >= quantidade) return;
        if (escolhidas.contains(a)) continue;
        if (diverso && temasUsados.contains(a.tema)) continue;
        escolhidas.add(a);
        temasUsados.add(a.tema);
      }
    }

    // 1) o que o usuário declarou, um de cada tema
    pegar((a) => a.tema != null && e.temas.contains(a.tema));
    // 2) mais do mesmo tema, se ainda faltar (sem repetir tema primeiro)
    pegar((a) => a.tema != null && e.temas.contains(a.tema), diverso: false);
    // 3) ideias gerais de baixo esforço, para ninguém ficar sem saída
    pegar((a) =>
        a.tema == Tema.mente ||
        a.tema == Tema.descanso ||
        a.tema == Tema.arLivre);
    // 4) qualquer outra que caiba
    pegar((_) => true);
    pegar((_) => true, diverso: false);

    return escolhidas;
  }

  /// Atualiza o estado com o que o usuário acabou de dizer.
  /// Devolve true se o texto trouxe algo novo.
  static bool absorver(EstadoConversa e, Intencao i) {
    var mudou = false;
    for (final t in i.temas) {
      if (e.temas.add(t)) mudou = true;
    }
    for (final m in i.semMaterial) {
      if (e.semMaterial.add(m)) mudou = true;
    }
    if (i.minutos != null && i.minutos != e.minutos) {
      e.minutos = i.minutos;
      mudou = true;
    }
    if (i.energiaMaxima != null && i.energiaMaxima != e.energiaMaxima) {
      e.energiaMaxima = i.energiaMaxima;
      mudou = true;
    }
    if (i.local != null && i.local != e.local) {
      e.local = i.local;
      mudou = true;
    }
    return mudou;
  }

  static List<String> _chipsPara(EstadoConversa e, List<Atividade> opcoes) {
    final chips = <String>[];
    if (opcoes.any((a) => a.precisa.contains(Material.livro)) ||
        (e.temas.contains(Tema.leitura) &&
            !e.semMaterial.contains(Material.livro))) {
      chips.add(chipSemLivro);
    }
    if (opcoes.any((a) => a.precisa.contains(Material.caderno)) &&
        !e.semMaterial.contains(Material.caderno)) {
      chips.add(chipSemCaderno);
    }
    if (e.energiaMaxima == null) chips.add(chipCansado);
    if (e.minutos == null) chips.add(chipPoucoTempo);
    if (e.local == null) chips.add(chipFora);
    chips.add(chipOutra);
    return chips.take(5).toList();
  }

  /// Primeira mensagem. [ocasiao] é 'fim' (acabou o tempo) ou 'livre'.
  static RespostaIkAi abertura(
    EstadoConversa e, {
    String? nome,
    String ocasiao = 'fim',
    int minutosUsados = 0,
    int rotacao = 0,
  }) {
    final opcoes = selecionar(e, rotacao: rotacao);
    final quem = (nome == null || nome.isEmpty) ? '' : '$nome, ';
    final b = StringBuffer();

    if (ocasiao == 'fim') {
      b.write(minutosUsados > 0
          ? '${quem.isEmpty ? 'Seu' : '${quem}seu'} tempo no Ikai acabou '
              'depois de $minutosUsados minuto${minutosUsados == 1 ? '' : 's'}. '
          : '${quem.isEmpty ? 'Seu' : '${quem}seu'} tempo no Ikai acabou. ');
    } else {
      b.write('${quem.isEmpty ? 'Oi' : 'Oi, $nome'}! ');
    }

    if (e.temas.isEmpty) {
      b.write('Você não me contou o que quer fazer, então separei ideias '
          'simples para agora. Se quiser me dizer o que tem vontade, '
          'ajusto as opções.');
    } else {
      final lista = e.temas.map(nomeDoTema).join(', ');
      b.write('Você me falou de $lista. Separei opções para agora. Me '
          'conte onde está, quanto tempo tem e como está a energia, e eu '
          'ajusto.');
    }
    return RespostaIkAi(b.toString(), opcoes, _chipsPara(e, opcoes));
  }

  /// Resposta a uma mensagem de texto do usuário. Muda [e].
  static RespostaIkAi responder(
    EstadoConversa e,
    String textoUsuario, {
    int rotacao = 0,
    List<Atividade> mostradas = const [],
  }) {
    final i = interpretar(textoUsuario);
    final novoContexto = absorver(e, i);

    if (i.querOutras) {
      for (final a in mostradas) {
        e.recusadas.add(a.id);
      }
    }

    // Só aceitou ("ok", "bora"): pede que escolha uma das opções.
    if (i.aceitou && !i.querOutras && !novoContexto && i.temas.isEmpty) {
      return RespostaIkAi(
        'Ótimo! Qual delas você quer fazer? Toque em "Vou fazer isso" na '
        'opção que combina com você.',
        mostradas,
        const [],
      );
    }

    final opcoes = selecionar(e, rotacao: rotacao);

    if (opcoes.isEmpty) {
      return RespostaIkAi(
        'Passamos por todas as ideias que cabem no que você contou. Quer me '
        'dizer o que você gostaria de fazer, ou prefere só descansar sem '
        'tela por alguns minutos?',
        const [],
        [
          if (e.recusadas.isNotEmpty) 'Pode repetir as ideias',
          'Vou descansar um pouco',
        ],
      );
    }

    final b = StringBuffer();
    if (i.querOutras) {
      b.write('Tudo bem, vamos para outras ideias. ');
    }
    if (novoContexto) {
      final partes = <String>[];
      final resumo = e.resumoDoContexto;
      if (resumo.isNotEmpty) partes.add('Entendi: $resumo.');
      if (i.temas.isNotEmpty) {
        partes.add('Anotei: ${i.temas.map(nomeDoTema).join(', ')}.');
      }
      b.write('${partes.join(' ')} ');
      b.write('Veja estas opções:');
    } else if (i.querOutras) {
      b.write('Veja estas:');
    } else if (i.semIdeia) {
      b.write('Sem problema, escolho por você. Veja estas opções:');
    } else {
      // Não entendi nada de novo: pergunto, sem presumir.
      b.write('Quero acertar a sugestão. O que você tem vontade de fazer '
          'agora, longe da tela? Enquanto isso, veja estas opções:');
    }
    return RespostaIkAi(b.toString().trim(), opcoes, _chipsPara(e, opcoes));
  }

  /// Resposta a um sinal de sofrimento sério: sem ideias, sem conselhos,
  /// só encaminhamento para ajuda humana (Brasil: CVV 188, SAMU 192).
  static RespostaIkAi cuidado() {
    return const RespostaIkAi(
      'Sinto muito que você esteja passando por isso. Eu sou um assistente '
      'do aplicativo e não substituo uma pessoa. Se você está pensando em '
      'se machucar ou em acabar com a própria vida, ligue agora para o CVV '
      'no 188 (gratuito, 24 horas) ou chame o SAMU no 192. Se puder, fale '
      'também com alguém de confiança que esteja perto de você.',
      [],
      [],
    );
  }

  /// Texto da Ik AI quando o usuário escolhe uma atividade ("Vou fazer
  /// isso"): pergunta o QUANDO, que transforma a vontade em um plano
  /// "quando X, então Y" (intenção de implementação).
  static RespostaIkAi perguntarQuando(Atividade a) {
    return RespostaIkAi(
      'Boa escolha: "${a.titulo}". Para sair do papel, combine o '
      'momento. Quando você começa?',
      const [],
      const [
        'Agora mesmo',
        'Em 10 minutos',
        'Depois do jantar',
        'Antes de dormir',
        'Amanhã de manhã',
      ],
    );
  }

  static RespostaIkAi confirmarCombinado(Atividade a, String quando) {
    var q = quando.trim().isEmpty ? 'agora' : quando.trim();
    q = q[0].toLowerCase() + q.substring(1);
    return RespostaIkAi(
      'Combinado: $q, você vai fazer "${a.titulo}". Pode fechar o app e '
      'começar. Quando você voltar, eu pergunto como foi.',
      const [],
      const [],
    );
  }
}
