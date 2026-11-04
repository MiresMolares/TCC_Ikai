import '../core/sem_emoji.dart';
import '../core/texto.dart';

/// Sugestões geradas no próprio aparelho, sem internet e sem IA externa.
///
/// É o plano B da Ik AI: usado quando não há chave do Gemini, quando o
/// usuário não autorizou o envio do texto, ou quando a chamada falha.
/// Segue a mesma regra da IA: só usa o que o usuário DECLAROU, nunca infere.
/// Dart puro (sem Flutter), para ser testável.
class SugestoesLocais {
  SugestoesLocais._();

  static const int quantidade = 3;

  static List<String> gerar({
    required String texto,
    String? objetivoTitulo,
  }) {
    final resultado = <String>[];

    for (final item in _extrairItens(texto)) {
      if (resultado.length >= quantidade) break;
      resultado.add(removerEmojis(_sugestaoPara(item)));
    }

    for (final generica in _genericas(objetivoTitulo)) {
      if (resultado.length >= quantidade) break;
      resultado.add(generica);
    }
    return resultado;
  }

  // ---------- Extração dos itens declarados ----------

  static List<String> _extrairItens(String texto) {
    final limpo = removerEmojis(texto).trim();
    if (limpo.isEmpty) return const [];

    final partes = limpo
        .split(RegExp(r'[,;\n]+|\s+e\s+'))
        .map(_limparItem)
        .where((p) => p.length >= 3)
        .toList();
    return partes;
  }

  static String _limparItem(String bruto) {
    var s = bruto.trim();
    s = s.replaceAll(RegExp(r'[.!?\s]+$'), '');
    s = s.replaceFirst(
      RegExp(r'^(eu\s+)?(estou|to|tô|ando|venho)\s+', caseSensitive: false),
      '',
    );
    s = s.trim();
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  // ---------- Regras por tipo de interesse ----------

  static String _sugestaoPara(String item) {
    final n = _normalizar(item);

    if (_tem(n, _treino)) {
      return '$item: monte um treino curto de 25 minutos (aquecimento, '
          'três exercícios e alongamento) e faça agora.';
    }
    if (_tem(n, _idioma)) {
      return '$item: reserve 15 minutos de prática ativa, falando em voz '
          'alta ou escrevendo cinco frases novas.';
    }
    if (_tem(n, _escrita)) {
      return '$item: abra um caderno e escreva por 15 minutos, sem se '
          'preocupar com o resultado.';
    }
    if (_tem(n, _estudo)) {
      return '$item: revise a última matéria por 25 minutos e anote '
          'três dúvidas para a próxima vez.';
    }
    if (_tem(n, _leitura)) {
      return '$item: pegue o livro e leia por 20 minutos, longe das telas.';
    }
    return '$item: escolha uma ação pequena e concreta e dedique 15 '
        'minutos a ela agora.';
  }

  static const _treino = [
    'trein', 'academia', 'exerc', 'corrid', 'corre', 'muscula',
    'caminhad', 'esporte', 'fitness', 'yoga', 'pedal',
  ];
  static const _idioma = [
    'fluente', 'idioma', 'ingles', 'frances', 'espanhol', 'japones',
    'alemao', 'italiano', 'lingua',
  ];
  static const _escrita = [
    'escrev', 'letra', 'musica', 'compor', 'redac', 'poema', 'roteiro',
  ];
  static const _estudo = [
    'estud', 'prova', 'vestibular', 'enem', 'curso', 'materia', 'faculdade',
  ];
  static const _leitura = [
    'ler', 'lendo', 'leio', 'livro', 'leitura', 'capitulo',
  ];

  static bool _tem(String normalizado, List<String> chaves) {
    for (final c in chaves) {
      if (RegExp('(^|[^a-z])${RegExp.escape(c)}').hasMatch(normalizado)) {
        return true;
      }
    }
    return false;
  }

  // ---------- Sugestões genéricas (completam até 3) ----------

  static List<String> _genericas(String? objetivoTitulo) {
    final o = _normalizar(objetivoTitulo ?? '');
    final porObjetivo = o.contains('ler')
        ? 'Leia um capítulo de um livro físico, longe das telas.'
        : o.contains('estudar')
            ? 'Faça exercícios no papel sobre o que acabou de estudar.'
            : 'Anote uma ideia do que viu hoje e conte para alguém.';
    return [
      porObjetivo,
      'Levante, beba água e alongue o corpo por cinco minutos.',
      'Dê uma caminhada curta, sem celular, e observe o que está ao redor.',
    ];
  }

  static String _normalizar(String s) => normalizarTexto(s);
}
