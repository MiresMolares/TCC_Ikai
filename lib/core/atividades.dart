/// Catálogo de atividades fora da tela. Dart puro.
///
/// A Ik AI nunca depende de uma única sugestão: o catálogo tem opções para
/// quem está sem o livro, sem caderno, cansado, com pouco tempo, em casa ou
/// na rua. Cada atividade é concreta (o que fazer, por quanto tempo).

enum Tema {
  leitura,
  treino,
  idioma,
  escrita,
  estudo,
  mente,
  criativo,
  social,
  casa,
  descanso,
  arLivre,
}

String nomeDoTema(Tema t) {
  switch (t) {
    case Tema.leitura:
      return 'leitura';
    case Tema.treino:
      return 'treino';
    case Tema.idioma:
      return 'idiomas';
    case Tema.escrita:
      return 'escrita';
    case Tema.estudo:
      return 'estudo';
    case Tema.mente:
      return 'calma mental';
    case Tema.criativo:
      return 'criatividade';
    case Tema.social:
      return 'estar com pessoas';
    case Tema.casa:
      return 'organização da casa';
    case Tema.descanso:
      return 'descanso';
    case Tema.arLivre:
      return 'ar livre';
  }
}

enum Local { casa, fora, qualquer }

/// O que a atividade exige. Lista vazia significa: não precisa de nada.
enum Material { livro, caderno, instrumento }

class Atividade {
  final String id;
  final String titulo;

  /// O que fazer, em 1 a 3 frases curtas.
  final String passos;
  final Tema? tema;
  final int minutos;

  /// 1 pouca energia, 2 média, 3 alta.
  final int energia;
  final Local local;
  final Set<Material> precisa;

  /// Veio de uma resposta do Gemini (e não do catálogo do app).
  final bool deIa;

  const Atividade({
    required this.id,
    required this.titulo,
    required this.passos,
    required this.tema,
    required this.minutos,
    required this.energia,
    this.local = Local.qualquer,
    this.precisa = const {},
    this.deIa = false,
  });

  String get rotuloEnergia =>
      energia <= 1 ? 'calma' : (energia == 2 ? 'moderada' : 'intensa');
}

const List<Atividade> catalogoDeAtividades = [
  // ---------------- Leitura ----------------
  Atividade(
    id: 'lei_livro',
    titulo: 'Ler 20 minutos do seu livro',
    passos: 'Pegue o livro, sente-se num lugar confortável e leia sem '
        'interrupções por 20 minutos. Deixe o celular em outro cômodo.',
    tema: Tema.leitura,
    minutos: 20,
    energia: 1,
    precisa: {Material.livro},
  ),
  Atividade(
    id: 'lei_releia',
    titulo: 'Reler sua passagem favorita',
    passos: 'Abra o livro na página que você mais gostou e releia devagar. '
        'Pense no que ela diz sobre você hoje.',
    tema: Tema.leitura,
    minutos: 10,
    energia: 1,
    precisa: {Material.livro},
  ),
  Atividade(
    id: 'lei_contar',
    titulo: 'Contar a história do livro, de memória',
    passos: 'Sem o livro, conte em voz alta o que você já leu, como se '
        'estivesse contando a um amigo. O que lembrar primeiro mostra o que '
        'mais marcou.',
    tema: Tema.leitura,
    minutos: 10,
    energia: 1,
  ),
  Atividade(
    id: 'lei_resumo',
    titulo: 'Escrever de memória o resumo do último capítulo',
    passos: 'Pegue papel e caneta e escreva, sem consultar nada, o que '
        'aconteceu no último capítulo que você leu.',
    tema: Tema.leitura,
    minutos: 15,
    energia: 1,
    precisa: {Material.caderno},
  ),
  Atividade(
    id: 'lei_perguntas',
    titulo: 'Escrever três perguntas para o autor',
    passos: 'Anote três perguntas que você faria ao autor sobre o que leu. '
        'Elas ajudam a descobrir o que você quer entender melhor.',
    tema: Tema.leitura,
    minutos: 10,
    energia: 1,
    precisa: {Material.caderno},
  ),
  Atividade(
    id: 'lei_qualquer',
    titulo: 'Ler qualquer coisa impressa que esteja por perto',
    passos: 'Procure em casa uma revista, um jornal, uma receita, uma '
        'embalagem ou um livro de alguém e leia por 10 minutos.',
    tema: Tema.leitura,
    minutos: 10,
    energia: 1,
    local: Local.casa,
  ),
  Atividade(
    id: 'lei_emprestimo',
    titulo: 'Pedir um livro emprestado a alguém da casa',
    passos: 'Pergunte a quem mora com você se tem um livro para emprestar e '
        'leia as primeiras páginas ainda hoje.',
    tema: Tema.leitura,
    minutos: 15,
    energia: 1,
    local: Local.casa,
  ),

  // ---------------- Treino ----------------
  Atividade(
    id: 'tre_sem_equip',
    titulo: 'Treino de 15 minutos sem equipamento',
    passos: 'Faça 3 rodadas de: 10 agachamentos, 10 flexões (pode ser com os '
        'joelhos no chão) e 20 segundos de prancha. Descanse 1 minuto entre '
        'as rodadas.',
    tema: Tema.treino,
    minutos: 15,
    energia: 3,
    local: Local.casa,
  ),
  Atividade(
    id: 'tre_caminhada',
    titulo: 'Caminhar 15 minutos sem o celular',
    passos: 'Saia, deixe o celular em casa e caminhe em ritmo confortável. '
        'Preste atenção no caminho.',
    tema: Tema.treino,
    minutos: 15,
    energia: 2,
    local: Local.fora,
  ),
  Atividade(
    id: 'tre_alongar',
    titulo: 'Alongar por 10 minutos',
    passos: 'Alongue pescoço, ombros, costas e pernas, segurando cada '
        'posição por cerca de 20 segundos, sem dor.',
    tema: Tema.treino,
    minutos: 10,
    energia: 1,
  ),
  Atividade(
    id: 'tre_mobilidade',
    titulo: 'Mobilidade de ombros e quadril',
    passos: 'Faça círculos lentos com os ombros, os braços e o quadril, '
        'dez para cada lado, respirando fundo.',
    tema: Tema.treino,
    minutos: 8,
    energia: 1,
  ),

  // ---------------- Idiomas ----------------
  Atividade(
    id: 'idi_descrever',
    titulo: 'Descrever o ambiente em voz alta no idioma',
    passos: 'Olhe ao redor e descreva o que vê, em voz alta, no idioma que '
        'você está aprendendo. Onde faltar palavra, anote para pesquisar '
        'depois.',
    tema: Tema.idioma,
    minutos: 10,
    energia: 1,
  ),
  Atividade(
    id: 'idi_frases',
    titulo: 'Escrever cinco frases novas e ler em voz alta',
    passos: 'Escreva cinco frases sobre o seu dia no idioma e leia cada uma '
        'em voz alta, prestando atenção na pronúncia.',
    tema: Tema.idioma,
    minutos: 15,
    energia: 1,
    precisa: {Material.caderno},
  ),
  Atividade(
    id: 'idi_cantar',
    titulo: 'Cantar uma música no idioma',
    passos: 'Cante de memória uma música que você conheça no idioma. Onde '
        'esquecer, invente ou anote o trecho para descobrir depois.',
    tema: Tema.idioma,
    minutos: 10,
    energia: 2,
  ),
  Atividade(
    id: 'idi_etiquetas',
    titulo: 'Etiquetar dez objetos da casa com o nome no idioma',
    passos: 'Escreva em papéis o nome de dez objetos no idioma e cole em '
        'cada um. Cada vez que passar por eles, leia em voz alta.',
    tema: Tema.idioma,
    minutos: 15,
    energia: 2,
    local: Local.casa,
    precisa: {Material.caderno},
  ),
  Atividade(
    id: 'idi_conversa',
    titulo: 'Contar seu dia no idioma, falando sozinho',
    passos: 'Fale por 5 minutos sobre como foi o seu dia, no idioma. Não '
        'pare para corrigir: o objetivo é soltar a fala.',
    tema: Tema.idioma,
    minutos: 5,
    energia: 1,
  ),

  // ---------------- Escrita ----------------
  Atividade(
    id: 'esc_livre',
    titulo: 'Escrever livremente por 10 minutos',
    passos: 'Marque 10 minutos e escreva sem parar e sem apagar. Se não '
        'souber o que escrever, escreva isso.',
    tema: Tema.escrita,
    minutos: 10,
    energia: 1,
    precisa: {Material.caderno},
  ),
  Atividade(
    id: 'esc_letra',
    titulo: 'Escrever oito linhas de uma letra ou poema',
    passos: 'Escolha um assunto, uma imagem ou um sentimento e escreva oito '
        'linhas. Corrigir fica para outro dia.',
    tema: Tema.escrita,
    minutos: 20,
    energia: 2,
    precisa: {Material.caderno},
  ),
  Atividade(
    id: 'esc_ideias',
    titulo: 'Anotar três ideias para a próxima letra',
    passos: 'Anote três ideias curtas: uma imagem, uma frase, um tema. Elas '
        'viram ponto de partida na próxima vez.',
    tema: Tema.escrita,
    minutos: 5,
    energia: 1,
    precisa: {Material.caderno},
  ),
  Atividade(
    id: 'esc_rimas',
    titulo: 'Pensar rimas e ritmo de cabeça',
    passos: 'Sem papel, escolha uma palavra e pense em dez que rimam com '
        'ela. Bata o ritmo com a mão enquanto fala.',
    tema: Tema.escrita,
    minutos: 10,
    energia: 1,
  ),

  // ---------------- Estudo ----------------
  Atividade(
    id: 'est_revisar',
    titulo: 'Revisar a última matéria por 25 minutos',
    passos: 'Releia suas anotações da última matéria e marque o que não '
        'ficou claro.',
    tema: Tema.estudo,
    minutos: 25,
    energia: 2,
    precisa: {Material.caderno},
  ),
  Atividade(
    id: 'est_explicar',
    titulo: 'Explicar o assunto em voz alta, como numa aula',
    passos: 'Escolha um tópico que você estudou e explique em voz alta, com '
        'palavras simples. Onde travar, é o que precisa rever.',
    tema: Tema.estudo,
    minutos: 10,
    energia: 2,
  ),
  Atividade(
    id: 'est_duvidas',
    titulo: 'Listar três dúvidas para a próxima vez',
    passos: 'Escreva as três coisas que você ainda não entendeu bem. A lista '
        'já organiza o próximo estudo.',
    tema: Tema.estudo,
    minutos: 5,
    energia: 1,
    precisa: {Material.caderno},
  ),
  Atividade(
    id: 'est_exercicios',
    titulo: 'Resolver cinco exercícios no papel',
    passos: 'Escolha cinco exercícios do assunto atual e resolva no papel, '
        'sem consultar. Depois confira.',
    tema: Tema.estudo,
    minutos: 20,
    energia: 2,
    precisa: {Material.caderno},
  ),

  // ---------------- Calma mental ----------------
  Atividade(
    id: 'men_respirar',
    titulo: 'Respirar devagar por 2 minutos',
    passos: 'Sentado, inspire contando até 4 e solte o ar contando até 6. '
        'Repita por cerca de seis respirações.',
    tema: Tema.mente,
    minutos: 2,
    energia: 1,
  ),
  Atividade(
    id: 'men_corpo',
    titulo: 'Percorrer o corpo com a atenção',
    passos: 'Sentado ou deitado, leve a atenção dos pés até a cabeça, uma '
        'parte de cada vez, notando o que sente sem tentar mudar.',
    tema: Tema.mente,
    minutos: 5,
    energia: 1,
  ),
  Atividade(
    id: 'men_janela',
    titulo: 'Olhar pela janela por 3 minutos',
    passos: 'Fique em frente a uma janela sem fazer nada além de observar. '
        'Quando a mente puxar para o celular, volte a olhar para fora.',
    tema: Tema.mente,
    minutos: 3,
    energia: 1,
  ),
  Atividade(
    id: 'men_sentir',
    titulo: 'Anotar em uma frase como você está',
    passos: 'Escreva uma frase sobre como você se sente agora. Só isso: '
        'nomear ajuda a perceber o que pedia a tela.',
    tema: Tema.mente,
    minutos: 3,
    energia: 1,
    precisa: {Material.caderno},
  ),

  // ---------------- Criatividade ----------------
  Atividade(
    id: 'cri_desenhar',
    titulo: 'Desenhar o objeto que está à sua frente',
    passos: 'Escolha um objeto e desenhe como você o vê, sem se preocupar '
        'com o resultado.',
    tema: Tema.criativo,
    minutos: 10,
    energia: 1,
    precisa: {Material.caderno},
  ),
  Atividade(
    id: 'cri_tocar',
    titulo: 'Tocar ou praticar um instrumento por 15 minutos',
    passos: 'Escolha uma música ou um trecho e repita devagar até ficar '
        'limpo.',
    tema: Tema.criativo,
    minutos: 15,
    energia: 2,
    precisa: {Material.instrumento},
  ),
  Atividade(
    id: 'cri_cantar',
    titulo: 'Cantar ou batucar o ritmo de uma música',
    passos: 'Sem instrumento, cante uma música que você gosta ou batuque o '
        'ritmo na mesa.',
    tema: Tema.criativo,
    minutos: 10,
    energia: 2,
  ),
  Atividade(
    id: 'cri_cozinhar',
    titulo: 'Preparar algo simples para comer',
    passos: 'Escolha uma receita curta com o que tem em casa e prepare, sem '
        'pressa.',
    tema: Tema.criativo,
    minutos: 30,
    energia: 2,
    local: Local.casa,
  ),

  // ---------------- Estar com pessoas ----------------
  Atividade(
    id: 'soc_conversar',
    titulo: 'Conversar 10 minutos com alguém',
    passos: 'Chame alguém da casa, ou ligue para um amigo, e converse sem '
        'olhar para telas.',
    tema: Tema.social,
    minutos: 10,
    energia: 1,
  ),
  Atividade(
    id: 'soc_convite',
    titulo: 'Convidar alguém para um passeio curto',
    passos: 'Chame alguém para dar uma volta ou tomar um café.',
    tema: Tema.social,
    minutos: 20,
    energia: 2,
    local: Local.fora,
  ),

  // ---------------- Casa ----------------
  Atividade(
    id: 'cas_canto',
    titulo: 'Arrumar um canto: mesa ou gaveta',
    passos: 'Escolha um único canto e deixe-o em ordem. Um espaço arrumado '
        'ajuda a começar o que você quer fazer.',
    tema: Tema.casa,
    minutos: 10,
    energia: 2,
    local: Local.casa,
  ),
  Atividade(
    id: 'cas_mochila',
    titulo: 'Preparar o que você vai usar amanhã',
    passos: 'Separe roupa, mochila, material e o que mais precisar. Amanhã '
        'começa mais leve.',
    tema: Tema.casa,
    minutos: 10,
    energia: 1,
    local: Local.casa,
  ),

  // ---------------- Descanso ----------------
  Atividade(
    id: 'des_deitar',
    titulo: 'Deitar sem tela por 10 minutos',
    passos: 'Deite, feche os olhos e deixe a mente vagar. Se dormir, era o '
        'que o corpo pedia.',
    tema: Tema.descanso,
    minutos: 10,
    energia: 1,
    local: Local.casa,
  ),
  Atividade(
    id: 'des_vista',
    titulo: 'Descansar a vista',
    passos: 'Olhe para algo distante por 20 segundos, depois feche os olhos '
        'por um minuto. Beba um copo de água.',
    tema: Tema.descanso,
    minutos: 2,
    energia: 1,
  ),

  // ---------------- Ar livre ----------------
  Atividade(
    id: 'ar_sol',
    titulo: 'Ficar 5 minutos ao ar livre',
    passos: 'Vá à janela, à varanda ou à calçada e fique alguns minutos '
        'sentindo o ar e a luz do dia.',
    tema: Tema.arLivre,
    minutos: 5,
    energia: 1,
  ),
  Atividade(
    id: 'ar_esquina',
    titulo: 'Caminhar até a esquina e voltar',
    passos: 'Uma volta curta, sem destino e sem celular na mão.',
    tema: Tema.arLivre,
    minutos: 10,
    energia: 2,
    local: Local.fora,
  ),
];

Atividade? atividadePorId(String id) {
  for (final a in catalogoDeAtividades) {
    if (a.id == id) return a;
  }
  return null;
}
