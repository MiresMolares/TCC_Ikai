import 'atividades.dart';
import 'sem_emoji.dart';
import 'texto.dart';

/// O que o usuário DISSE em uma mensagem. Dart puro.
///
/// É um leitor de palavras-chave, não uma "dedução": só marca o que está
/// escrito. Nada é inferido além do texto.
class Intencao {
  final Set<Tema> temas;
  final Set<Material> semMaterial;
  final int? minutos;

  /// Teto de energia pedido pelo usuário (1 = pouca energia).
  final int? energiaMaxima;
  final Local? local;

  /// Pediu outra ideia, recusou ou disse que não quer o que foi sugerido.
  final bool querOutras;
  final bool aceitou;
  final bool semIdeia;

  const Intencao({
    this.temas = const {},
    this.semMaterial = const {},
    this.minutos,
    this.energiaMaxima,
    this.local,
    this.querOutras = false,
    this.aceitou = false,
    this.semIdeia = false,
  });

  /// Disse algo sobre as condições dele (material, tempo, energia, lugar).
  bool get mudaContexto =>
      semMaterial.isNotEmpty ||
      minutos != null ||
      energiaMaxima != null ||
      local != null;

  bool get vazia =>
      temas.isEmpty &&
      !mudaContexto &&
      !querOutras &&
      !aceitou &&
      !semIdeia;
}

const _chavesTema = <Tema, List<String>>{
  Tema.treino: [
    'trein', 'academia', 'exerc', 'corrid', 'correr', 'muscula', 'caminhad',
    'esporte', 'fitness', 'yoga', 'pedal', 'alongar', 'malhar',
  ],
  Tema.idioma: [
    'fluente', 'idioma', 'ingles', 'frances', 'espanhol', 'japones',
    'alemao', 'italiano', 'lingua', 'coreano', 'mandarim',
  ],
  Tema.escrita: [
    'escrev', 'letra', 'musica', 'compor', 'redac', 'poema', 'roteiro',
    'rimas', 'diario',
  ],
  Tema.estudo: [
    'estud', 'prova', 'vestibular', 'enem', 'curso', 'materia', 'faculdade',
    'tcc', 'trabalho da escola',
  ],
  Tema.leitura: [
    'ler', 'lendo', 'leio', 'livro', 'leitura', 'capitulo', 'romance',
  ],
  Tema.mente: [
    'medit', 'respir', 'ansios', 'estress', 'calma', 'relax', 'mindful',
  ],
  Tema.criativo: [
    'desenh', 'pintar', 'pintura', 'violao', 'violino', 'guitarr', 'teclado', 'tocar', 'cozinh',
    'cantar', 'artesanato',
  ],
  Tema.social: [
    'amigo', 'amiga', 'famili', 'conversar', 'ligar para', 'visitar',
  ],
};

bool _tem(String n, List<String> chaves) {
  for (final c in chaves) {
    if (RegExp('(^|[^a-z])${RegExp.escape(c)}').hasMatch(n)) return true;
  }
  return false;
}

/// Temas citados em [texto] (livre ou da etapa "Ik AI").
Set<Tema> temasDoTexto(String texto) {
  final n = normalizarTexto(removerEmojis(texto));
  final r = <Tema>{};
  _chavesTema.forEach((tema, chaves) {
    if (_tem(n, chaves)) r.add(tema);
  });
  return r;
}

Intencao interpretar(String texto) {
  final n = normalizarTexto(removerEmojis(texto)).trim();
  if (n.isEmpty) return const Intencao();

  // ---- material que falta ----
  final semMaterial = <Material>{};
  const falta = r'(sem|nao tenho|nao estou com|nao to com|nao ta comigo|'
      r'esqueci|perdi|nao achei|nao encontro)';
  if (RegExp('$falta\\s+(o\\s+|a\\s+|meu\\s+|minha\\s+|um\\s+|uma\\s+)?'
          '(livro|kindle|e-?book)')
      .hasMatch(n)) {
    semMaterial.add(Material.livro);
  }
  if (RegExp('$falta\\s+(o\\s+|a\\s+|meu\\s+|minha\\s+|um\\s+|uma\\s+)?'
          '(caderno|papel|caneta|lapis|anotac)')
      .hasMatch(n)) {
    semMaterial.add(Material.caderno);
  }
  if (RegExp('$falta\\s+(o\\s+|a\\s+|meu\\s+|minha\\s+|um\\s+|uma\\s+)?'
          '(violao|instrumento|teclado|guitarra|baixo)')
      .hasMatch(n)) {
    semMaterial.add(Material.instrumento);
  }

  // ---- tempo disponível ----
  int? minutos;
  final m = RegExp(r'(\d{1,3})\s*(min|minuto|minutos)\b').firstMatch(n);
  if (m != null) {
    minutos = int.parse(m.group(1)!);
  } else {
    final h = RegExp(r'(\d{1,2})\s*(h|hora|horas)\b').firstMatch(n);
    if (h != null) {
      minutos = int.parse(h.group(1)!) * 60;
    } else if (n.contains('meia hora')) {
      minutos = 30;
    } else if (RegExp(r'(pouco tempo|minutinhos|uns minutos|so um pouco)')
        .hasMatch(n)) {
      minutos = 10;
    }
  }
  if (minutos != null && (minutos < 1 || minutos > 240)) minutos = null;

  // ---- energia ----
  int? energia;
  if (RegExp(r'(cansad|exaust|sem energia|esgotad|sono|preguic|'
          r'desanimad|sem forcas|pregad)')
      .hasMatch(n)) {
    energia = 1;
  }

  // ---- lugar ----
  Local? local;
  if (RegExp(r'(fora de casa|na rua|no onibus|no metro|no trabalho|'
          r'na escola|na faculdade|no carro|saindo|na fila)')
      .hasMatch(n)) {
    local = Local.fora;
  } else if (RegExp(r'(em casa|no quarto|na sala|na cama|no sofa)')
      .hasMatch(n)) {
    local = Local.casa;
  }

  // ---- recusa, pedido de mais, aceite ----
  final querOutras = RegExp(
    r'(outra coisa|outra opcao|outras opcoes|outra ideia|outras ideias|'
    r'mais opcoes|mais ideias|mais sugest|outras sugest|algo diferente|'
    r'nao quero|nao curti|nao gostei|nao rola|nao da pra|nao posso|'
    r'nao consigo|nao to afim|nao estou afim|de novo nao|nao e isso)',
  ).hasMatch(n);

  final aceitou =
      RegExp(r'^(sim|ok|beleza|bora|vamos|combinado|fechado|pode ser|topo|'
              r'vou fazer|vou sim|claro)\b')
          .hasMatch(n);

  final semIdeia = RegExp(
    r'(nao sei|sem ideia|nao faco ideia|qualquer coisa|me ajuda|me ajude|'
    r'surpreend|entedi|nada pra fazer|nada para fazer)',
  ).hasMatch(n);

  return Intencao(
    temas: temasDoTexto(texto),
    semMaterial: semMaterial,
    minutos: minutos,
    energiaMaxima: energia,
    local: local,
    querOutras: querOutras,
    aceitou: aceitou,
    semIdeia: semIdeia,
  );
}


/// Sinais de que a pessoa pode estar em sofrimento sério. Quando aparecem,
/// a Ik AI não sugere atividades nem manda nada para a IA externa: encaminha
/// para ajuda humana. Lista curta e deliberadamente cautelosa.
bool sinalDeCrise(String texto) {
  final n = normalizarTexto(removerEmojis(texto));
  return RegExp(
    r'(me matar|quero morrer|vou morrer|suicid|tirar (a )?minha vida|'
    r'acabar com (tudo|minha vida|a minha vida)|nao quero mais viver|'
    r'queria (nao existir|sumir pra sempre)|me machucar|me cortar|'
    r'automutila)',
  ).hasMatch(n);
}
