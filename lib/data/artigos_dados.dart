import 'artigo.dart';

/// ============================================================
/// BANCO DE ARTIGOS (TEMPORÁRIO, até existir o banco de dados)
/// ============================================================
///
/// Para adicionar um artigo, copie o modelo abaixo, cole no FIM da lista
/// `artigosDados` e preencha. Não precisa mexer em mais nenhum arquivo.
///
///   Artigo(
///     id: 'a031',                      // único; continue a numeração
///     objetivoId: 'ler',               // 'ver_conteudo' | 'ler' | 'estudar' | 'oficio'
///     categoriaId: 'ler_romance',      // id de uma categoria do objetivo
///     nivel: 1,                        // 1 iniciante | 2 intermediário | 3 avançado
///     titulo: 'Título do artigo',
///     autor: 'Nome do autor',
///     resumo: 'Uma ou duas frases para o cartão.',
///     tags: ['assunto um', 'assunto dois'],
///     paragrafos: [
///       'Primeiro parágrafo.',
///       'Segundo parágrafo.',
///     ],
///   ),
///
/// Os ids válidos de objetivo e categoria estão em
/// lib/pages_configurar/objetivo_conteudo.dart, objetivo_leitura.dart,
/// objetivo_estudo.dart e objetivo_oficio.dart. O teste `flutter test` avisa se algum id estiver
/// errado ou repetido.
///
/// Todos os textos abaixo foram escritos para o Ikai.

const List<Artigo> artigosDados = [
  // ------------------------------------------------------------
  // VER CONTEÚDO
  // ------------------------------------------------------------
  Artigo(
    id: 'a001',
    objetivoId: 'ver_conteudo',
    categoriaId: 'ver_cientifico',
    nivel: 1,
    titulo: 'Por que o céu é azul',
    autor: 'Equipe Ikai',
    resumo:
        'A luz do Sol parece branca, mas carrega todas as cores. O que '
        'acontece com ela na atmosfera explica o azul que vemos.',
    tags: ['física', 'luz', 'atmosfera'],
    paragrafos: [
      'A luz do Sol é a mistura de todas as cores. Ao entrar na atmosfera, '
          'ela encontra moléculas de gases, como nitrogênio e oxigênio, que '
          'espalham a luz em todas as direções. Esse fenômeno se chama '
          'espalhamento de Rayleigh.',
      'As cores de comprimento de onda curto, como o azul, são espalhadas '
          'com muito mais intensidade do que as de comprimento longo, como o '
          'vermelho. Por isso, para onde quer que você olhe no céu, chega '
          'até você luz azul espalhada.',
      'No pôr do sol, a luz atravessa um caminho muito maior na atmosfera. '
          'Quase todo o azul é espalhado para longe da sua linha de visão e '
          'sobram os tons de laranja e vermelho.',
    ],
  ),
  Artigo(
    id: 'a002',
    objetivoId: 'ver_conteudo',
    categoriaId: 'ver_cultura',
    nivel: 1,
    titulo: 'Capoeira: luta, dança e resistência',
    autor: 'Equipe Ikai',
    resumo:
        'Nascida no Brasil entre pessoas escravizadas, a capoeira é hoje '
        'reconhecida como patrimônio cultural.',
    tags: ['cultura brasileira', 'patrimônio', 'música'],
    paragrafos: [
      'A capoeira é uma manifestação cultural brasileira que reúne luta, '
          'dança, música e jogo. Ela se formou entre africanos escravizados '
          'e seus descendentes, e durante muito tempo foi perseguida.',
      'A roda de capoeira é organizada em torno de instrumentos como o '
          'berimbau e o pandeiro, e das cantigas que os jogadores respondem '
          'em coro. O ofício dos mestres de capoeira foi registrado como '
          'patrimônio cultural imaterial do Brasil em 2008, e a roda de '
          'capoeira foi reconhecida pela Unesco em 2014.',
    ],
  ),
  Artigo(
    id: 'a003',
    objetivoId: 'ver_conteudo',
    categoriaId: 'ver_jogos',
    nivel: 2,
    titulo: 'O que o xadrez ensina sobre decisões',
    autor: 'Equipe Ikai',
    resumo:
        'Um jogo com mais de mil anos que treina a habilidade de prever '
        'consequências antes de agir.',
    tags: ['xadrez', 'estratégia', 'raciocínio'],
    paragrafos: [
      'O xadrez descende do chaturanga, um jogo surgido na Índia por volta '
          'do século VI. Séculos depois, chegou à Europa e ganhou as regras '
          'que conhecemos hoje.',
      'Cada lance muda as opções de quem joga e de quem enfrenta. Por isso, '
          'jogar bem exige imaginar a resposta do outro antes de mexer uma '
          'peça. Esse hábito de pensar na consequência de uma decisão, e não '
          'só no ganho imediato, é útil bem fora do tabuleiro.',
    ],
  ),
  Artigo(
    id: 'a004',
    objetivoId: 'ver_conteudo',
    categoriaId: 'ver_noticia',
    nivel: 2,
    titulo: 'Três perguntas antes de compartilhar uma notícia',
    autor: 'Equipe Ikai',
    resumo:
        'Um roteiro simples para não espalhar informação falsa sem querer.',
    tags: ['educação midiática', 'checagem', 'informação'],
    paragrafos: [
      'Antes de compartilhar uma notícia, faça três perguntas. Quem '
          'publicou? Veja se o veículo ou a pessoa tem histórico e se '
          'assina o que escreve.',
      'Qual é a fonte? Uma boa notícia diz de onde veio a informação: um '
          'documento, um especialista, um dado oficial. E outros veículos '
          'independentes confirmam o mesmo fato?',
      'Por fim, confira a data. Textos antigos circulam como se fossem '
          'novos e causam confusão. Se alguma resposta ficar em aberto, '
          'espere antes de repassar.',
    ],
  ),
  Artigo(
    id: 'a005',
    objetivoId: 'ver_conteudo',
    categoriaId: 'ver_esporte',
    nivel: 1,
    titulo: 'A primeira Copa do Mundo',
    autor: 'Equipe Ikai',
    resumo:
        'Em 1930, no Uruguai, treze seleções disputaram o primeiro mundial '
        'de futebol.',
    tags: ['futebol', 'história do esporte', 'copa do mundo'],
    paragrafos: [
      'A primeira Copa do Mundo de futebol aconteceu em 1930, no Uruguai. '
          'Foram treze seleções, e muitas das europeias enfrentaram uma '
          'longa viagem de navio para participar.',
      'O Uruguai, país-sede, venceu a final contra a Argentina por 4 a 2 e '
          'ficou com o primeiro título. O Brasil também esteve lá, mas foi '
          'eliminado ainda na primeira fase.',
    ],
  ),
  Artigo(
    id: 'a006',
    objetivoId: 'ver_conteudo',
    categoriaId: 'ver_curiosidades',
    nivel: 1,
    titulo: 'O mel que quase não estraga',
    autor: 'Equipe Ikai',
    resumo:
        'Pouca água, acidez e uma substância produzida pelas abelhas ajudam '
        'o mel a durar muito tempo.',
    tags: ['alimentos', 'química', 'curiosidade'],
    paragrafos: [
      'O mel guardado de forma correta pode durar muito tempo sem estragar. '
          'Isso acontece por alguns motivos juntos. Ele tem pouquíssima água, '
          'e a maioria das bactérias e fungos precisa de água para crescer.',
      'Além disso, o mel é ácido e as abelhas adicionam a ele uma enzima que '
          'produz pequenas quantidades de peróxido de hidrogênio, o que '
          'dificulta a vida dos microrganismos.',
      'Com o tempo, o mel pode cristalizar. Isso não significa que estragou: '
          'basta aquecê-lo suavemente em banho-maria para ele voltar ao '
          'estado líquido.',
    ],
  ),

  // ------------------------------------------------------------
  // LER
  // ------------------------------------------------------------
  Artigo(
    id: 'a007',
    objetivoId: 'ler',
    categoriaId: 'ler_romance',
    nivel: 2,
    titulo: 'Dom Casmurro e a dúvida que atravessa gerações',
    autor: 'Equipe Ikai',
    resumo:
        'No romance de Machado de Assis, a dúvida sobre Capitu é mais '
        'importante do que a resposta.',
    tags: ['machado de assis', 'literatura brasileira', 'realismo'],
    paragrafos: [
      'Publicado em 1899, Dom Casmurro é narrado por Bentinho, que anos '
          'depois conta a própria história e tenta convencer o leitor de que '
          'foi traído por Capitu, a amiga de infância com quem se casou.',
      'O truque de Machado de Assis é que tudo chega até nós pelo ponto de '
          'vista de um narrador interessado. Não há prova definitiva, e é '
          'essa dúvida que mantém o livro vivo: cada leitor precisa decidir '
          'em quem confiar.',
    ],
  ),
  Artigo(
    id: 'a008',
    objetivoId: 'ler',
    categoriaId: 'ler_fantasia',
    nivel: 1,
    titulo: 'O que faz um mundo de fantasia parecer real',
    autor: 'Equipe Ikai',
    resumo:
        'Regras claras, história e detalhes fazem um mundo inventado '
        'parecer um lugar de verdade.',
    tags: ['worldbuilding', 'tolkien', 'fantasia'],
    paragrafos: [
      'Um mundo de fantasia convence quando segue regras. Se a magia pode '
          'tudo, nada tem peso. Se ela tem limites e custos, cada escolha dos '
          'personagens importa.',
      'J. R. R. Tolkien, autor de O Senhor dos Anéis, era filólogo, '
          'especialista em línguas. Ele criou idiomas inteiros antes de '
          'escrever as histórias, e isso deu à Terra Média uma sensação de '
          'passado e de cultura que poucos mundos inventados alcançam.',
    ],
  ),
  Artigo(
    id: 'a009',
    objetivoId: 'ler',
    categoriaId: 'ler_suspense',
    nivel: 1,
    titulo: 'Como o suspense prende o leitor',
    autor: 'Equipe Ikai',
    resumo:
        'O segredo está menos no que acontece e mais no que o autor decide '
        'não contar ainda.',
    tags: ['narrativa', 'mistério', 'técnica'],
    paragrafos: [
      'O suspense nasce de uma lacuna de informação. O leitor sabe que '
          'falta algo, e a vontade de preencher essa lacuna faz com que ele '
          'vire a página.',
      'Autores de romances policiais, como Agatha Christie, constroem '
          'pistas que parecem inocentes e só ganham sentido no final. Outro '
          'recurso comum é encerrar um capítulo com uma pergunta aberta. '
          'Quando você notar essas técnicas, vai ler com ainda mais prazer.',
    ],
  ),
  Artigo(
    id: 'a010',
    objetivoId: 'ler',
    categoriaId: 'ler_fc',
    nivel: 2,
    titulo: 'Frankenstein, a origem da ficção científica moderna',
    autor: 'Equipe Ikai',
    resumo:
        'Publicado em 1818, o livro de Mary Shelley já discutia os limites '
        'da ciência e a responsabilidade de quem cria.',
    tags: ['mary shelley', 'ficção científica', 'ética'],
    paragrafos: [
      'Frankenstein, de Mary Shelley, foi publicado em 1818 e é muitas '
          'vezes apontado como um dos primeiros romances de ficção '
          'científica. A autora começou a escrevê-lo ainda muito jovem.',
      'Na história, o cientista Victor Frankenstein dá vida a uma criatura '
          'e depois a abandona. O livro levanta uma pergunta que continua '
          'atual: quem cria uma tecnologia é responsável pelo que ela faz '
          'no mundo?',
    ],
  ),
  Artigo(
    id: 'a011',
    objetivoId: 'ler',
    categoriaId: 'ler_horror',
    nivel: 1,
    titulo: 'Por que gostamos de sentir medo lendo',
    autor: 'Equipe Ikai',
    resumo:
        'Uma história assustadora permite sentir medo com a segurança de '
        'quem sabe que está só lendo.',
    tags: ['horror', 'edgar allan poe', 'emoções'],
    paragrafos: [
      'A literatura de horror oferece algo curioso: o medo sem o perigo '
          'real. Dentro da história, tudo é ameaçador. Do lado de fora, você '
          'está seguro no sofá.',
      'Edgar Allan Poe explorou isso como poucos. Em contos como O Gato '
          'Preto, de 1843, o horror não vem de monstros, mas da mente '
          'perturbada do narrador, o que torna a leitura ainda mais '
          'inquietante.',
    ],
  ),
  Artigo(
    id: 'a012',
    objetivoId: 'ler',
    categoriaId: 'ler_terror',
    nivel: 2,
    titulo: 'Terror e horror: qual é a diferença',
    autor: 'Equipe Ikai',
    resumo:
        'Dois nomes parecidos para dois efeitos diferentes: sugerir e '
        'mostrar.',
    tags: ['terror', 'gótico', 'teoria literária'],
    paragrafos: [
      'A escritora inglesa Ann Radcliffe, autora de romances góticos do '
          'fim do século XVIII, é associada à distinção entre terror e '
          'horror. Para ela, o terror é a expectativa: a sombra, o ruído, '
          'a ameaça que se sugere e expande a imaginação.',
      'O horror, por sua vez, é o choque diante do que se mostra de forma '
          'explícita. Muitos leitores preferem o terror justamente porque '
          'a própria imaginação costuma ser mais assustadora do que '
          'qualquer descrição.',
    ],
  ),
  Artigo(
    id: 'a013',
    objetivoId: 'ler',
    categoriaId: 'ler_religioso',
    nivel: 2,
    titulo: 'Textos sagrados: um olhar de leitor',
    autor: 'Equipe Ikai',
    resumo:
        'Como ler um texto religioso com atenção ao gênero, à época e à '
        'língua em que foi escrito.',
    tags: ['religião', 'leitura', 'história'],
    paragrafos: [
      'Muitas tradições possuem textos sagrados, lidos por devoção, por '
          'estudo ou por interesse histórico e literário. Independentemente '
          'da crença de quem lê, vale prestar atenção ao contexto.',
      'Em um mesmo livro podem existir poesia, leis, narrativas e cartas, '
          'e cada gênero pede uma leitura diferente. Também importam a '
          'época em que o texto surgiu e a língua original, já que toda '
          'tradução envolve escolhas. Ler com essa atenção ajuda a '
          'respeitar o texto e a entender melhor quem o lê.',
    ],
  ),
  Artigo(
    id: 'a014',
    objetivoId: 'ler',
    categoriaId: 'ler_distopia',
    nivel: 3,
    titulo: '1984: a vigilância como tema',
    autor: 'Equipe Ikai',
    resumo:
        'O romance de George Orwell, de 1949, criou palavras e imagens que '
        'usamos até hoje para falar de controle.',
    tags: ['george orwell', 'distopia', 'vigilância'],
    paragrafos: [
      'Publicado em 1949, 1984 se passa em um país onde o Estado observa '
          'todos o tempo todo. A figura do Grande Irmão, os cartazes que '
          'dizem que ele está de olho em você, virou símbolo de vigilância.',
      'Orwell também mostra que controlar a linguagem é controlar o '
          'pensamento. Na história, a língua oficial, a novafala, reduz o '
          'vocabulário para que certas ideias nem possam ser formuladas. '
          'É um bom livro para quem quer refletir sobre informação e '
          'poder.',
    ],
  ),
  Artigo(
    id: 'a015',
    objetivoId: 'ler',
    categoriaId: 'ler_aventura',
    nivel: 1,
    titulo: 'A Ilha do Tesouro e o imaginário dos piratas',
    autor: 'Equipe Ikai',
    resumo:
        'O clássico de Robert Louis Stevenson ajudou a criar a imagem '
        'popular do pirata.',
    tags: ['robert louis stevenson', 'clássicos', 'piratas'],
    paragrafos: [
      'A Ilha do Tesouro, de Robert Louis Stevenson, foi publicada em livro '
          'em 1883. Conta a história do jovem Jim Hawkins, que encontra um '
          'mapa e embarca em uma viagem em busca de um tesouro.',
      'Muito do que imaginamos sobre piratas vem desse livro: o mapa do '
          'tesouro, a ilha misteriosa e o papagaio no ombro do carismático '
          'e perigoso Long John Silver. É aventura clássica, de leitura '
          'ágil.',
    ],
  ),
  Artigo(
    id: 'a016',
    objetivoId: 'ler',
    categoriaId: 'ler_dp',
    nivel: 1,
    titulo: 'Hábitos pequenos, mudança grande',
    autor: 'Equipe Ikai',
    resumo:
        'Começar pequeno costuma funcionar melhor do que tentar mudar '
        'tudo de uma vez.',
    tags: ['hábitos', 'desenvolvimento pessoal', 'rotina'],
    paragrafos: [
      'Muita gente tenta mudar de vida em um dia e desiste na semana '
          'seguinte. Uma alternativa é escolher um hábito tão pequeno que '
          'seja difícil recusar, como ler uma página por dia.',
      'O ganho de um dia é quase invisível, mas a repetição soma. Além '
          'disso, é mais fácil manter um hábito quando ele está ligado a '
          'algo que você já faz, como ler logo depois do café. Comece '
          'pequeno e aumente só quando ficar fácil.',
    ],
  ),
  Artigo(
    id: 'a017',
    objetivoId: 'ler',
    categoriaId: 'ler_tecnico',
    nivel: 2,
    titulo: 'Como ler um texto técnico sem se perder',
    autor: 'Equipe Ikai',
    resumo:
        'Uma estratégia em três passos para não travar diante de um texto '
        'denso.',
    tags: ['estudo', 'leitura técnica', 'método'],
    paragrafos: [
      'Textos técnicos não precisam ser lidos do começo ao fim de uma só '
          'vez. Primeiro, passe os olhos pelo resumo, pelos títulos e pelas '
          'conclusões para ter um mapa do que vem pela frente.',
      'Depois, leia com atenção as partes que interessam e pare nos '
          'exemplos: tente refazê-los sozinho. Por fim, explique o conteúdo '
          'com suas palavras, em voz alta ou por escrito. Se não conseguir, '
          'você sabe exatamente o que precisa reler.',
    ],
  ),
  Artigo(
    id: 'a018',
    objetivoId: 'ler',
    categoriaId: 'ler_biografia',
    nivel: 2,
    titulo: 'Quarto de Despejo e a voz de quem escreve a própria vida',
    autor: 'Equipe Ikai',
    resumo:
        'O diário de Carolina Maria de Jesus mostra a vida na favela pelos '
        'olhos de quem a viveu.',
    tags: ['carolina maria de jesus', 'diário', 'literatura brasileira'],
    paragrafos: [
      'Quarto de Despejo foi publicado em 1960 e reúne os diários de '
          'Carolina Maria de Jesus, moradora da favela do Canindé, em São '
          'Paulo. Catadora de papel, ela escrevia à noite, depois do '
          'trabalho.',
      'O livro é um relato em primeira pessoa sobre fome, trabalho e '
          'dignidade. Ele lembra que relatos de vida não são só de '
          'pessoas famosas: quem viveu a experiência tem uma perspectiva '
          'que nenhuma outra fonte consegue substituir.',
    ],
  ),

  // ------------------------------------------------------------
  // ESTUDAR
  // ------------------------------------------------------------
  Artigo(
    id: 'a019',
    objetivoId: 'estudar',
    categoriaId: 'estudar_matematica',
    nivel: 1,
    titulo: 'Problemas de matemática: leia duas vezes, resolva uma',
    autor: 'Equipe Ikai',
    resumo:
        'Um método simples para organizar um problema antes de fazer '
        'qualquer conta.',
    tags: ['método de estudo', 'resolução de problemas', 'matemática'],
    paragrafos: [
      'Muitos erros em matemática acontecem antes da primeira conta, na '
          'leitura do enunciado. Leia o problema duas vezes: na primeira, '
          'entenda a história; na segunda, sublinhe os dados e a pergunta.',
      'Em seguida, faça um desenho ou um esquema e estime a ordem de '
          'grandeza da resposta. Só então calcule. No final, volte à '
          'pergunta e veja se o resultado faz sentido. Uma resposta '
          'negativa para uma quantidade de pessoas, por exemplo, mostra '
          'que algo deu errado.',
    ],
  ),
  Artigo(
    id: 'a020',
    objetivoId: 'estudar',
    categoriaId: 'estudar_lp',
    nivel: 1,
    titulo: 'Crase sem medo: a regra do vou a, volto da',
    autor: 'Equipe Ikai',
    resumo: 'Um truque clássico para decidir quando usar o acento grave.',
    tags: ['gramática', 'crase', 'português'],
    paragrafos: [
      'A crase é a fusão da preposição a com o artigo a. Um truque famoso '
          'ajuda a decidir: troque o verbo por ir e vir. Se você diz "vou '
          'a" e "volto da", há crase: "Vou à escola, volto da escola".',
      'Se você diz "vou a" e "volto de", não há crase: "Vou a Roma, volto '
          'de Roma". Lembre também que não se usa crase antes de verbos nem '
          'antes de palavras masculinas, exceto em expressões como "à moda '
          'de".',
    ],
  ),
  Artigo(
    id: 'a021',
    objetivoId: 'estudar',
    categoriaId: 'estudar_ingles',
    nivel: 2,
    titulo: 'False friends: palavras que enganam',
    autor: 'Equipe Ikai',
    resumo:
        'Palavras do inglês que parecem português, mas significam outra '
        'coisa.',
    tags: ['vocabulário', 'inglês', 'false friends'],
    paragrafos: [
      'False friends são palavras parecidas entre dois idiomas, mas com '
          'sentidos diferentes. Em inglês, "pretend" não é pretender: '
          'significa fingir. "Actually" não é atualmente: quer dizer na '
          'verdade.',
      'Outros exemplos: "library" é biblioteca, não livraria (que é '
          '"bookstore"), e "parents" são os pais, não os parentes (que são '
          '"relatives"). Anote os que você já confundiu e revise de vez em '
          'quando.',
    ],
  ),
  Artigo(
    id: 'a022',
    objetivoId: 'estudar',
    categoriaId: 'estudar_artes',
    nivel: 1,
    titulo: 'Cores quentes e cores frias',
    autor: 'Equipe Ikai',
    resumo: 'Como a temperatura das cores muda a sensação de uma imagem.',
    tags: ['teoria das cores', 'artes visuais', 'composição'],
    paragrafos: [
      'Em artes visuais, vermelho, laranja e amarelo são chamados de cores '
          'quentes, enquanto azul, verde e violeta são as frias. Essa '
          'divisão não é de temperatura real, e sim de sensação.',
      'As cores quentes tendem a parecer próximas e energéticas, e as '
          'frias, distantes e calmas. Artistas usam isso para dar '
          'profundidade a uma pintura e guiar o olhar: um detalhe quente '
          'em uma paisagem fria chama atenção imediatamente.',
    ],
  ),
  Artigo(
    id: 'a023',
    objetivoId: 'estudar',
    categoriaId: 'estudar_historia',
    nivel: 2,
    titulo: 'Revolução Francesa: o que mudou em 1789',
    autor: 'Equipe Ikai',
    resumo: 'Três ideias para entender o início de um processo que mudou o mundo.',
    tags: ['revolução francesa', 'idade contemporânea', 'direitos'],
    paragrafos: [
      'A Revolução Francesa começou em 1789, em um país com forte '
          'desigualdade e crise econômica. A tomada da Bastilha, em 14 de '
          'julho, tornou-se o símbolo do início do processo.',
      'Três ideias ajudam a entender seu impacto. A primeira é a de que o '
          'poder vem do povo, e não do rei por direito divino. A segunda é '
          'a Declaração dos Direitos do Homem e do Cidadão, de agosto de '
          '1789. A terceira é o lema liberdade, igualdade e fraternidade, '
          'que inspirou movimentos em muitos outros países.',
    ],
  ),
  Artigo(
    id: 'a024',
    objetivoId: 'estudar',
    categoriaId: 'estudar_geografia',
    nivel: 2,
    titulo: 'Latitude e longitude: como localizar qualquer ponto',
    autor: 'Equipe Ikai',
    resumo: 'As duas medidas que formam o endereço de qualquer lugar do planeta.',
    tags: ['coordenadas', 'cartografia', 'geografia'],
    paragrafos: [
      'A latitude indica a distância ao norte ou ao sul da linha do '
          'Equador, que vale zero grau. Ela vai de 0 a 90 graus em cada '
          'direção, chegando aos polos.',
      'A longitude indica a distância a leste ou a oeste do meridiano de '
          'Greenwich, também de zero grau, e vai até 180 graus. Juntas, '
          'latitude e longitude formam as coordenadas geográficas, usadas '
          'por mapas e aplicativos de localização.',
    ],
  ),
  Artigo(
    id: 'a025',
    objetivoId: 'estudar',
    categoriaId: 'estudar_filosofia',
    nivel: 2,
    titulo: 'Sócrates e a arte de perguntar',
    autor: 'Equipe Ikai',
    resumo:
        'Um filósofo que quase não escreveu nada mudou a forma de '
        'investigar ideias.',
    tags: ['sócrates', 'filosofia antiga', 'método'],
    paragrafos: [
      'Sócrates viveu em Atenas, no século V a.C., e não deixou nada '
          'escrito. Conhecemos suas ideias principalmente pelos diálogos '
          'de seu discípulo Platão.',
      'Seu método consistia em fazer perguntas até que a pessoa percebesse '
          'contradições nas próprias respostas. A famosa ideia de que ele '
          'só sabia que nada sabia resume essa postura: reconhecer a '
          'própria ignorância é o primeiro passo para aprender.',
    ],
  ),
  Artigo(
    id: 'a026',
    objetivoId: 'estudar',
    categoriaId: 'estudar_sociologia',
    nivel: 3,
    titulo: 'Fato social, segundo Durkheim',
    autor: 'Equipe Ikai',
    resumo: 'O conceito que ajudou a transformar a sociologia em ciência.',
    tags: ['durkheim', 'sociologia clássica', 'conceitos'],
    paragrafos: [
      'Émile Durkheim, em As Regras do Método Sociológico, de 1895, '
          'definiu o fato social como maneiras de agir, pensar e sentir que '
          'existem fora do indivíduo e exercem sobre ele uma força de '
          'coerção.',
      'Exemplos são as leis, a língua que falamos e os costumes. Ninguém '
          'escolhe a língua em que nasce, mas ela molda o pensamento. Para '
          'Durkheim, a sociologia deve estudar esses fatos como coisas, '
          'com observação e método.',
    ],
  ),
  Artigo(
    id: 'a027',
    objetivoId: 'estudar',
    categoriaId: 'estudar_ef',
    nivel: 1,
    titulo: 'Aquecimento: por que cinco minutos importam',
    autor: 'Equipe Ikai',
    resumo: 'O que acontece no corpo quando você se prepara antes de se exercitar.',
    tags: ['exercício', 'saúde', 'preparação'],
    paragrafos: [
      'O aquecimento aumenta gradualmente os batimentos cardíacos e a '
          'temperatura dos músculos, e prepara as articulações para o '
          'movimento. Em geral, ele ajuda o corpo a render melhor e a '
          'reduzir o risco de lesões.',
      'Um aquecimento simples pode ter cinco minutos de caminhada ou '
          'trote leve, círculos com braços e quadris, e repetições '
          'lentas do movimento que será feito depois. Se tiver dores '
          'persistentes, procure um profissional de saúde.',
    ],
  ),
  Artigo(
    id: 'a028',
    objetivoId: 'estudar',
    categoriaId: 'estudar_biologia',
    nivel: 1,
    titulo: 'Fotossíntese em poucas linhas',
    autor: 'Equipe Ikai',
    resumo: 'Como as plantas transformam luz em alimento e liberam oxigênio.',
    tags: ['plantas', 'energia', 'biologia celular'],
    paragrafos: [
      'A fotossíntese é o processo pelo qual plantas, algas e algumas '
          'bactérias usam a energia da luz para produzir açúcar a partir '
          'de gás carbônico e água.',
      'Nas plantas, ela ocorre nos cloroplastos, que contêm clorofila, o '
          'pigmento verde que absorve a luz. Como resultado, a planta '
          'produz glicose, que serve de alimento, e libera oxigênio para '
          'a atmosfera.',
    ],
  ),
  Artigo(
    id: 'a029',
    objetivoId: 'estudar',
    categoriaId: 'estudar_fisica',
    nivel: 2,
    titulo: 'Inércia: a primeira lei de Newton',
    autor: 'Equipe Ikai',
    resumo: 'Por que você é jogado para frente quando o carro freia.',
    tags: ['mecânica', 'newton', 'movimento'],
    paragrafos: [
      'A primeira lei de Newton diz que um corpo em repouso continua em '
          'repouso, e um corpo em movimento continua em movimento retilíneo '
          'e com velocidade constante, a menos que uma força resultante '
          'atue sobre ele. Essa tendência se chama inércia.',
      'Quando um carro freia bruscamente, seu corpo tende a continuar '
          'andando para frente. É por isso que o cinto de segurança é '
          'importante: ele aplica a força que impede o corpo de seguir '
          'em movimento.',
    ],
  ),
  Artigo(
    id: 'a030',
    objetivoId: 'estudar',
    categoriaId: 'estudar_quimica',
    nivel: 2,
    titulo: 'Tabela periódica: como ler',
    autor: 'Equipe Ikai',
    resumo: 'Linhas, colunas e o que a posição de um elemento revela.',
    tags: ['elementos químicos', 'mendeleev', 'tabela periódica'],
    paragrafos: [
      'O químico russo Dmitri Mendeleev propôs, em 1869, uma organização '
          'dos elementos que previa até a existência de elementos ainda '
          'desconhecidos. Hoje, a tabela é ordenada pelo número atômico, '
          'ou seja, pela quantidade de prótons.',
      'As linhas horizontais são chamadas de períodos, e as colunas, de '
          'grupos ou famílias. Elementos do mesmo grupo costumam ter '
          'comportamentos químicos parecidos. Por isso, a posição de um '
          'elemento já diz muito sobre ele.',
    ],
  ),

  // ------------------------------------------------------------
  // NOVAS CATEGORIAS E APRENDER UM OFÍCIO
  // ------------------------------------------------------------
  Artigo(
    id: 'a031',
    objetivoId: 'ver_conteudo',
    categoriaId: 'ver_natureza',
    nivel: 1,
    titulo: 'A dança das abelhas',
    autor: 'Equipe Ikai',
    resumo:
        'Uma abelha que volta à colmeia consegue indicar às outras onde '
        'há flores. Ela faz isso dançando.',
    tags: ['abelhas', 'comunicação', 'comportamento animal'],
    paragrafos: [
      'Quando uma abelha operária encontra uma boa fonte de alimento, '
          'ela volta à colmeia e executa uma dança em forma de oito. Nessa '
          'dança, chamada de dança do requebrado, o trecho reto do oito é o '
          'que carrega a informação: a direção em que a abelha caminha '
          'nesse trecho indica a direção do alimento em relação ao Sol.',
      'Quanto mais longe estiver a fonte, mais tempo dura o trecho reto '
          'da dança. As outras abelhas acompanham o movimento de perto, no '
          'escuro da colmeia, e depois saem para buscar o alimento. O '
          'zoólogo austríaco Karl von Frisch decifrou esse sistema e, por '
          'isso, recebeu o Prêmio Nobel de Fisiologia ou Medicina em 1973.',
    ],
  ),
  Artigo(
    id: 'a032',
    objetivoId: 'ver_conteudo',
    categoriaId: 'ver_tecnologia',
    nivel: 1,
    titulo: 'O que acontece quando você faz uma busca',
    autor: 'Equipe Ikai',
    resumo:
        'Em fração de segundo, um buscador escolhe poucas páginas entre '
        'bilhões. Veja o caminho em três etapas.',
    tags: ['internet', 'buscadores', 'tecnologia'],
    paragrafos: [
      'Um buscador não percorre a internet quando você digita. Antes '
          'disso, programas chamados rastreadores visitam páginas de forma '
          'automática, seguindo os links de uma para outra. O conteúdo '
          'encontrado é organizado em um grande índice, parecido com o '
          'índice remissivo de um livro, que aponta em quais páginas cada '
          'palavra aparece.',
      'Quando você faz a busca, o sistema consulta esse índice pronto e '
          'ordena os resultados com base em muitos critérios, como a '
          'relação do texto com o que foi pedido e a qualidade da página. '
          'Por isso, escrever a pergunta com clareza costuma melhorar a '
          'resposta, e conferir a fonte continua sendo uma boa prática.',
    ],
  ),
  Artigo(
    id: 'a033',
    objetivoId: 'ver_conteudo',
    categoriaId: 'ver_espaco',
    nivel: 2,
    titulo: 'Por que vemos sempre a mesma face da Lua',
    autor: 'Equipe Ikai',
    resumo:
        'A Lua gira, mas gira no mesmo ritmo em que orbita a Terra. O '
        'resultado é uma face sempre voltada para nós.',
    tags: ['lua', 'astronomia', 'órbita'],
    paragrafos: [
      'A Lua dá uma volta em torno de si mesma no mesmo tempo que leva '
          'para dar uma volta em torno da Terra, pouco mais de 27 dias. '
          'Quando os dois períodos coincidem, dizemos que o satélite está '
          'em rotação sincronizada. Por isso, da Terra, enxergamos sempre o '
          'mesmo lado.',
      'Essa sincronia não é coincidência. Ela resulta da atração '
          'gravitacional entre os dois corpos, que, ao longo de milhões de '
          'anos, foi freando a rotação da Lua até igualá-la ao tempo da '
          'órbita. O outro lado, chamado de lado oculto, só foi fotografado '
          'em 1959, pela sonda soviética Luna 3. Ele não é escuro: recebe '
          'luz do Sol como o lado que vemos.',
    ],
  ),
  Artigo(
    id: 'a034',
    objetivoId: 'ver_conteudo',
    categoriaId: 'ver_musica',
    nivel: 1,
    titulo: 'O que faz uma nota soar diferente de outra',
    autor: 'Equipe Ikai',
    resumo:
        'Altura, intensidade e timbre explicam por que um violino e uma '
        'flauta tocando a mesma nota não soam iguais.',
    tags: ['som', 'frequência', 'timbre'],
    paragrafos: [
      'Todo som é uma vibração que se propaga pelo ar. A altura, que '
          'diferencia o grave do agudo, depende da frequência dessa '
          'vibração, medida em hertz. A nota lá usada como referência para '
          'afinar instrumentos vibra a 440 hertz, ou seja, 440 vezes por '
          'segundo.',
      'Já a intensidade é o que chamamos de volume, e o timbre é a '
          'característica que distingue as fontes sonoras. Um violino e uma '
          'flauta podem tocar a mesma nota, com a mesma altura e a mesma '
          'intensidade, e ainda assim soarem diferentes. Isso acontece '
          'porque cada instrumento produz, além da vibração principal, uma '
          'combinação própria de vibrações mais fracas.',
    ],
  ),
  Artigo(
    id: 'a035',
    objetivoId: 'ver_conteudo',
    categoriaId: 'ver_cinema',
    nivel: 2,
    titulo: 'O efeito Kuleshov',
    autor: 'Equipe Ikai',
    resumo:
        'Um mesmo rosto, três imagens diferentes. O que a montagem faz '
        'com o nosso olhar.',
    tags: ['cinema', 'montagem', 'psicologia'],
    paragrafos: [
      'No início do século 20, o cineasta soviético Lev Kuleshov se '
          'interessou por um fenômeno da montagem. Segundo o relato '
          'clássico do experimento, ele combinou a imagem do rosto '
          'inexpressivo de um ator com outras imagens, como um prato de '
          'comida, uma criança em um caixão e uma mulher em um sofá.',
      'Os espectadores teriam percebido emoções diferentes no mesmo '
          'rosto: fome, tristeza, desejo. A conclusão é que o sentido de '
          'uma cena nasce da relação entre os planos, e não apenas de cada '
          'plano sozinho. Esse princípio, conhecido como efeito Kuleshov, '
          'influenciou a forma de montar filmes e ajuda a entender por que '
          'a ordem das imagens muda o que sentimos.',
    ],
  ),
  Artigo(
    id: 'a036',
    objetivoId: 'ver_conteudo',
    categoriaId: 'ver_gastronomia',
    nivel: 2,
    titulo: 'Por que o pão dourado tem mais sabor',
    autor: 'Equipe Ikai',
    resumo:
        'A crosta escura de um pão ou de um bife vem de uma reação '
        'química descrita há mais de cem anos.',
    tags: ['química dos alimentos', 'reação de maillard', 'culinária'],
    paragrafos: [
      'A reação de Maillard recebe o nome do químico francês Louis- '
          'Camille Maillard, que a descreveu em 1912. Ela acontece quando '
          'aminoácidos e certos açúcares são aquecidos juntos e se '
          'transformam em centenas de novas substâncias, responsáveis pela '
          'cor dourada e por aromas que não existiam no alimento cru.',
      'Ela começa de forma mais evidente em temperaturas acima de cerca '
          'de 140 graus e é favorecida por superfícies secas. Por isso, '
          'secar bem a carne antes de colocá-la na panela ajuda a dourá-la, '
          'e a água em excesso atrapalha. Não é a mesma coisa que a '
          'caramelização, que envolve apenas o açúcar.',
    ],
  ),
  Artigo(
    id: 'a037',
    objetivoId: 'ver_conteudo',
    categoriaId: 'ver_viagens',
    nivel: 1,
    titulo: 'Machu Picchu: a cidade no alto dos Andes',
    autor: 'Equipe Ikai',
    resumo:
        'Construída pelo Império Inca no século 15, a cidade de pedra '
        'fica a mais de 2.400 metros de altitude.',
    tags: ['peru', 'incas', 'patrimônio mundial'],
    paragrafos: [
      'Machu Picchu fica nos Andes peruanos, a cerca de 2.430 metros de '
          'altitude. Foi construída por volta de 1450, no auge do Império '
          'Inca, provavelmente como propriedade de um governante, e '
          'abandonada algumas décadas depois, na época da conquista '
          'espanhola. Os blocos de pedra foram encaixados com tanta '
          'precisão que dispensam argamassa.',
      'O explorador norte-americano Hiram Bingham levou o lugar ao '
          'conhecimento do mundo em 1911, guiado por moradores da região, '
          'que já conheciam o sítio. Em 1983, Machu Picchu foi declarado '
          'Patrimônio Mundial pela Unesco. Hoje, o número de visitantes é '
          'controlado para proteger as construções.',
    ],
  ),
  Artigo(
    id: 'a038',
    objetivoId: 'ver_conteudo',
    categoriaId: 'ver_arquitetura',
    nivel: 1,
    titulo: 'Brasília: uma cidade planejada',
    autor: 'Equipe Ikai',
    resumo:
        'A capital federal nasceu de um concurso de projetos e foi '
        'inaugurada em 1960.',
    tags: ['brasília', 'urbanismo', 'niemeyer'],
    paragrafos: [
      'Brasília foi inaugurada em 21 de abril de 1960, durante o '
          'governo de Juscelino Kubitschek. O plano da cidade, escolhido em '
          'concurso, é do urbanista Lúcio Costa e se organiza a partir do '
          'cruzamento de dois grandes eixos, o que lhe deu o apelido de '
          'plano piloto e a forma lembrada como a de um avião.',
      'Os principais edifícios públicos, como o Palácio do Planalto e o '
          'Congresso Nacional, foram projetados pelo arquiteto Oscar '
          'Niemeyer. Em 1987, o conjunto urbanístico da cidade foi '
          'reconhecido pela Unesco como Patrimônio Mundial, algo raro para '
          'uma cidade tão jovem.',
    ],
  ),
  Artigo(
    id: 'a039',
    objetivoId: 'ver_conteudo',
    categoriaId: 'ver_saude',
    nivel: 1,
    titulo: 'Por que dormir bem importa',
    autor: 'Equipe Ikai',
    resumo:
        'O sono não é um intervalo da vida: é quando o corpo e a mente se '
        'reorganizam.',
    tags: ['sono', 'saúde', 'rotina'],
    paragrafos: [
      'Durante a noite, o sono passa por ciclos que duram, em média, '
          'cerca de uma hora e meia e alternam fases mais leves, mais '
          'profundas e a fase do sono REM, associada aos sonhos. Cada fase '
          'tem um papel, e interromper o sono com frequência impede que o '
          'ciclo se complete.',
      'A maior parte dos adultos precisa de sete a nove horas de sono '
          'por noite, mas a necessidade varia de pessoa para pessoa. Manter '
          'horários regulares, reduzir a luz das telas antes de dormir e '
          'deixar o quarto escuro e silencioso são hábitos simples que '
          'costumam ajudar. Quem tem dificuldade persistente para dormir '
          'deve procurar um profissional de saúde.',
    ],
  ),
  Artigo(
    id: 'a040',
    objetivoId: 'ver_conteudo',
    categoriaId: 'ver_economia',
    nivel: 1,
    titulo: 'O que é inflação',
    autor: 'Equipe Ikai',
    resumo:
        'Os preços sobem, mas a inflação mede a alta de todos eles '
        'juntos, e não de um produto só.',
    tags: ['inflação', 'economia', 'ipca'],
    paragrafos: [
      'Inflação é o aumento geral e contínuo dos preços. Se só o preço '
          'do tomate sobe, isso não é inflação: é preciso que uma grande '
          'parte dos produtos e serviços fique mais cara ao mesmo tempo. '
          'Com a inflação, o mesmo dinheiro compra menos coisas do que '
          'antes.',
      'No Brasil, o índice oficial é o IPCA, calculado pelo IBGE a '
          'partir de uma cesta de produtos e serviços consumidos pelas '
          'famílias. A inflação já foi um problema grave no país. Ela só '
          'foi controlada de forma duradoura a partir do Plano Real, '
          'lançado em 1994, quando a nova moeda começou a circular em 1º de '
          'julho.',
    ],
  ),
  Artigo(
    id: 'a041',
    objetivoId: 'ler',
    categoriaId: 'ler_poesia',
    nivel: 1,
    titulo: 'Como ler um poema',
    autor: 'Equipe Ikai',
    resumo:
        'Poemas não pedem pressa nem “entendimento” imediato. Pedem voz, '
        'pausa e atenção às imagens.',
    tags: ['poesia', 'leitura', 'versos'],
    paragrafos: [
      'Um bom jeito de começar é ler o poema em voz alta, mesmo que '
          'baixinho. O som das palavras, o ritmo e as pausas no fim de cada '
          'verso fazem parte do sentido. Também vale reler: a segunda '
          'leitura quase sempre revela algo que passou despercebido na '
          'primeira.',
      'Não é preciso que o poema rime. Desde o modernismo, muitos '
          'poetas brasileiros escrevem em verso livre, sem rima nem métrica '
          'fixa. Em vez de procurar uma única resposta correta, observe as '
          'imagens que o texto cria e o que elas despertam em você. A '
          'interpretação nasce desse diálogo entre o que está escrito e '
          'quem lê.',
    ],
  ),
  Artigo(
    id: 'a042',
    objetivoId: 'ler',
    categoriaId: 'ler_classicos',
    nivel: 2,
    titulo: 'Por que ler Machado de Assis',
    autor: 'Equipe Ikai',
    resumo:
        'Um narrador que já morreu, ironia fina e uma sociedade em '
        'retrato: o autor que ainda surpreende.',
    tags: ['machado de assis', 'literatura brasileira', 'realismo'],
    paragrafos: [
      'Machado de Assis nasceu no Rio de Janeiro, em 1839, e foi o '
          'primeiro presidente da Academia Brasileira de Letras, fundada em '
          '1897. Seu romance Memórias Póstumas de Brás Cubas, publicado em '
          '1881, é considerado o marco do realismo no Brasil e é narrado '
          'por um defunto, que conta a própria vida com ironia.',
      'O que mantém Machado atual é o olhar sobre o comportamento '
          'humano: vaidade, interesse, hipocrisia, tudo apresentado com '
          'humor discreto. Quem está começando pode se aproximar pelos '
          'contos, como O alienista e A cartomante, que são curtos e '
          'mostram bem o estilo do autor.',
    ],
  ),
  Artigo(
    id: 'a043',
    objetivoId: 'ler',
    categoriaId: 'ler_ficcao_historica',
    nivel: 2,
    titulo: 'Ficção histórica: onde termina o fato',
    autor: 'Equipe Ikai',
    resumo:
        'Personagens inventados convivem com pessoas reais. Como ler esse '
        'gênero sem confundir as duas coisas.',
    tags: ['ficção histórica', 'romance', 'história'],
    paragrafos: [
      'A ficção histórica coloca personagens e enredos inventados '
          'dentro de um período real. O escocês Walter Scott, com romances '
          'como Waverley, de 1814, popularizou o gênero na Europa. Em Os '
          'três mosqueteiros, publicado por Alexandre Dumas em 1844, '
          'aparecem figuras que existiram de fato, como o cardeal '
          'Richelieu, ao lado de heróis criados pelo autor.',
      'Ler esse tipo de livro pede um cuidado: o romance não é um livro '
          'de história. O autor pode simplificar fatos, mudar datas ou '
          'imaginar diálogos para fazer a narrativa funcionar. Uma boa '
          'prática é usar o livro como porta de entrada e, depois, procurar '
          'uma fonte confiável sobre o período para separar o que aconteceu '
          'do que foi imaginado.',
    ],
  ),
  Artigo(
    id: 'a044',
    objetivoId: 'ler',
    categoriaId: 'ler_cronicas',
    nivel: 1,
    titulo: 'A crônica: literatura do dia a dia',
    autor: 'Equipe Ikai',
    resumo:
        'Textos curtos, nascidos nos jornais, que transformam um pequeno '
        'fato em literatura.',
    tags: ['crônica', 'jornal', 'literatura brasileira'],
    paragrafos: [
      'A crônica é um gênero curto, ligado ao jornal, que parte de um '
          'fato do cotidiano, como uma conversa ouvida no ônibus, uma chuva '
          'ou uma lembrança, e o transforma em reflexão ou em humor. No '
          'Brasil, o gênero ganhou características próprias e tem uma '
          'tradição forte, com autores como Machado de Assis, Rubem Braga e '
          'Cecília Meireles.',
      'Por serem curtas, as crônicas são uma ótima porta de entrada '
          'para quem quer criar o hábito de leitura. Cabem em poucos '
          'minutos e, em geral, não exigem conhecimento prévio. Muitas '
          'foram reunidas em livros, o que permite ler uma por dia, no '
          'ritmo que fizer sentido.',
    ],
  ),
  Artigo(
    id: 'a045',
    objetivoId: 'estudar',
    categoriaId: 'estudar_programacao',
    nivel: 1,
    titulo: 'O que é um algoritmo',
    autor: 'Equipe Ikai',
    resumo:
        'Um algoritmo é uma sequência de passos para resolver um '
        'problema. Uma receita de bolo já é um.',
    tags: ['algoritmo', 'lógica', 'programação'],
    paragrafos: [
      'Um algoritmo é uma sequência finita de passos bem definidos para '
          'resolver um problema ou realizar uma tarefa. Uma receita de bolo '
          'é um bom exemplo: tem entradas, que são os ingredientes, uma '
          'ordem de passos e um resultado. Programar é, em grande parte, '
          'descrever algoritmos de forma que o computador consiga executá- '
          'los.',
      'A palavra vem do nome do matemático persa al-Khwarizmi, que '
          'viveu no século 9. Já o primeiro algoritmo pensado para ser '
          'executado por uma máquina é atribuído a Ada Lovelace, que, em '
          '1843, descreveu um método para calcular números de Bernoulli na '
          'máquina analítica de Charles Babbage. Antes de escrever qualquer '
          'código, vale sempre treinar escrevendo os passos em palavras.',
    ],
  ),
  Artigo(
    id: 'a046',
    objetivoId: 'estudar',
    categoriaId: 'estudar_espanhol',
    nivel: 1,
    titulo: 'Falsos amigos entre português e espanhol',
    autor: 'Equipe Ikai',
    resumo:
        'Palavras parecidas, sentidos diferentes: as pegadinhas mais '
        'comuns de quem estuda espanhol.',
    tags: ['espanhol', 'vocabulário', 'falsos cognatos'],
    paragrafos: [
      'Português e espanhol são línguas muito próximas, e isso ajuda no '
          'começo, mas também gera armadilhas. Os chamados falsos amigos '
          'são palavras parecidas na escrita ou no som que têm significados '
          'diferentes. Em espanhol, embarazada significa grávida, e não '
          'envergonhada, que se diz avergonzada.',
      'Outros exemplos: exquisito significa delicioso ou refinado, e '
          'não esquisito, que em espanhol se diz raro ou extraño. Cena, em '
          'espanhol, é o jantar, e não a cena de um filme. E rato, em '
          'espanhol, é um momento ou um instante, como em esperar un rato. '
          'Uma boa estratégia é anotar cada falso amigo que você encontrar '
          'em uma lista própria e revisar essa lista de tempos em tempos.',
    ],
  ),
  Artigo(
    id: 'a047',
    objetivoId: 'estudar',
    categoriaId: 'estudar_redacao',
    nivel: 2,
    titulo: 'A estrutura da redação argumentativa',
    autor: 'Equipe Ikai',
    resumo:
        'Tese, argumentos e conclusão: o esqueleto de um texto que '
        'convence, como o cobrado no Enem.',
    tags: ['redação', 'enem', 'argumentação'],
    paragrafos: [
      'O texto argumentativo costuma ter três partes. Na introdução, '
          'você apresenta o tema e a tese, isto é, a sua posição. No '
          'desenvolvimento, normalmente em dois parágrafos, cada argumento '
          'é explicado e sustentado com dados, exemplos ou referências. Na '
          'conclusão, retoma-se a tese e fecha-se a ideia.',
      'No Enem, a redação é avaliada em cinco competências, com nota de '
          '0 a 1000, e a última exige uma proposta de intervenção para o '
          'problema discutido. Uma boa proposta indica quem deve agir, qual '
          'ação realizar, de que modo, com que finalidade e com algum '
          'detalhamento. Planejar por cinco minutos antes de escrever '
          'costuma poupar muito tempo depois.',
    ],
  ),
  Artigo(
    id: 'a048',
    objetivoId: 'estudar',
    categoriaId: 'estudar_financas',
    nivel: 2,
    titulo: 'Juros simples e juros compostos',
    autor: 'Equipe Ikai',
    resumo:
        'A mesma taxa pode render valores bem diferentes. A diferença '
        'está em sobre o que os juros incidem.',
    tags: ['juros', 'matemática financeira', 'investimentos'],
    paragrafos: [
      'Nos juros simples, a taxa incide sempre sobre o valor inicial. A '
          'fórmula do juro é J = C · i · t, em que C é o capital, i é a '
          'taxa e t é o tempo. Aplicando 1.000 reais a 10% ao mês por dois '
          'meses, o juro é de 200 reais, e o montante final é de 1.200 '
          'reais.',
      'Nos juros compostos, a taxa incide também sobre os juros já '
          'acumulados, o que é conhecido como juros sobre juros. O montante '
          'é M = C · (1 + i)^t. Com os mesmos 1.000 reais, a 10% ao mês por '
          'dois meses, o resultado é 1.210 reais. A diferença parece '
          'pequena no início, mas cresce muito com o tempo, e isso vale '
          'tanto para quem investe quanto para quem deve.',
    ],
  ),
  Artigo(
    id: 'a049',
    objetivoId: 'oficio',
    categoriaId: 'oficio_marcenaria',
    nivel: 1,
    titulo: 'Madeira maciça, MDF e compensado',
    autor: 'Equipe Ikai',
    resumo:
        'Conhecer o material é o primeiro passo de qualquer peça: cada um '
        'se comporta de um jeito.',
    tags: ['madeira', 'materiais', 'marcenaria'],
    paragrafos: [
      'A madeira maciça vem direto do tronco e tem fibras, que correm '
          'no sentido do comprimento. É resistente, mas pode se dilatar e '
          'se contrair com a umidade. O compensado é feito de lâminas finas '
          'coladas com as fibras cruzadas, o que o deixa mais estável. O '
          'MDF é feito de fibras de madeira prensadas com resina e tem '
          'superfície lisa, mas não gosta de umidade.',
      'Duas regras ajudam muito quem está começando. A primeira é medir '
          'duas vezes antes de cortar uma vez, porque o erro de corte não '
          'tem volta. A segunda é respeitar as fibras: cortes e furos '
          'feitos em sentidos diferentes dão resultados diferentes. Use '
          'sempre óculos de proteção e prenda a peça antes de serrar.',
    ],
  ),
  Artigo(
    id: 'a050',
    objetivoId: 'oficio',
    categoriaId: 'oficio_eletrica',
    nivel: 1,
    titulo: 'Antes de mexer na tomada',
    autor: 'Equipe Ikai',
    resumo:
        'Em elétrica, a primeira ferramenta é o cuidado: desligar, testar '
        'e só então tocar nos fios.',
    tags: ['eletricidade', 'segurança', 'instalação'],
    paragrafos: [
      'Antes de mexer em qualquer ponto de energia, desligue o '
          'disjuntor correspondente no quadro e confirme, com um detector '
          'de tensão, que não há corrente nos fios. Só desligar o '
          'interruptor da parede não basta, porque o fio de fase pode '
          'continuar energizado.',
      'A norma brasileira de instalações elétricas de baixa tensão é a '
          'ABNT NBR 5410. Entre outras coisas, ela padroniza as cores dos '
          'fios: azul-claro para o neutro e verde ou verde e amarelo para o '
          'terra. Trocar uma tomada ou uma lâmpada é um serviço simples, '
          'mas mudanças no quadro ou na fiação devem ser feitas por um '
          'eletricista.',
    ],
  ),
  Artigo(
    id: 'a051',
    objetivoId: 'oficio',
    categoriaId: 'oficio_hidraulica',
    nivel: 1,
    titulo: 'Como vedar uma rosca sem vazamento',
    autor: 'Equipe Ikai',
    resumo:
        'A fita veda-rosca é barata e resolve boa parte dos pequenos '
        'vazamentos, se for usada do jeito certo.',
    tags: ['encanamento', 'vazamento', 'veda-rosca'],
    paragrafos: [
      'Em conexões roscadas, o vazamento costuma vir de uma vedação mal '
          'feita. A fita veda-rosca, feita de PTFE, preenche os espaços '
          'minúsculos entre os filetes da rosca. Antes de aplicar, limpe a '
          'rosca e remova a fita antiga.',
      'Enrole a fita no mesmo sentido em que a peça será rosqueada, '
          'dando algumas voltas e deixando livre o primeiro filete. '
          'Rosqueie com firmeza, sem forçar demais, para não trincar a '
          'peça. Antes de qualquer reparo, feche o registro, e se o '
          'vazamento for em uma parte embutida na parede, chame um '
          'profissional.',
    ],
  ),
  Artigo(
    id: 'a052',
    objetivoId: 'oficio',
    categoriaId: 'oficio_culinaria',
    nivel: 1,
    titulo: 'Mise en place: tudo no seu lugar',
    autor: 'Equipe Ikai',
    resumo:
        'A técnica dos cozinheiros profissionais que faz qualquer receita '
        'ficar mais calma.',
    tags: ['cozinha', 'organização', 'técnica'],
    paragrafos: [
      'Mise en place é uma expressão francesa que significa algo como '
          'colocar tudo em seu lugar. Na cozinha, quer dizer ler a receita '
          'inteira, separar, pesar e cortar todos os ingredientes e deixar '
          'os utensílios à mão antes de acender o fogo.',
      'A vantagem é que, durante o preparo, você não precisa parar para '
          'procurar ou picar algo enquanto outra coisa queima. Essa prática '
          'reduz erros e deixa o momento de cozinhar mais tranquilo. '
          'Mantenha também a faca bem afiada: uma faca sem fio exige mais '
          'força e escorrega com mais facilidade.',
    ],
  ),
  Artigo(
    id: 'a053',
    objetivoId: 'oficio',
    categoriaId: 'oficio_panificacao',
    nivel: 1,
    titulo: 'Como o fermento faz o pão crescer',
    autor: 'Equipe Ikai',
    resumo:
        'Seres vivos minúsculos e uma rede de proteínas explicam por que '
        'a massa dobra de tamanho.',
    tags: ['pão', 'fermentação', 'glúten'],
    paragrafos: [
      'O fermento biológico é formado por leveduras, fungos '
          'microscópicos da espécie Saccharomyces cerevisiae. Elas se '
          'alimentam dos açúcares da massa e liberam gás carbônico e '
          'álcool. O gás fica preso em pequenas bolhas dentro da massa, que '
          'por isso cresce.',
      'Quem segura essas bolhas é o glúten, uma rede elástica que se '
          'forma quando duas proteínas da farinha de trigo se juntam com a '
          'água e são trabalhadas na sova. Por isso, sovar bem e respeitar '
          'o tempo de descanso fazem diferença. O álcool evapora no forno, '
          'e é lá que o calor fixa a estrutura e forma a crosta.',
    ],
  ),
  Artigo(
    id: 'a054',
    objetivoId: 'oficio',
    categoriaId: 'oficio_costura',
    nivel: 1,
    titulo: 'Da medida ao molde',
    autor: 'Equipe Ikai',
    resumo:
        'Antes da máquina, vêm a fita métrica e a paciência: o ajuste '
        'certo começa na medição.',
    tags: ['costura', 'molde', 'medidas'],
    paragrafos: [
      'Toda peça começa com as medidas do corpo, como busto, cintura e '
          'quadril, tiradas com a fita métrica rente ao corpo, sem apertar. '
          'Essas medidas são comparadas com as do molde. Ao cortar o '
          'tecido, lembre-se de deixar a margem de costura, que costuma '
          'ficar em torno de um centímetro, para unir as partes.',
      'Observe também o sentido do fio do tecido. Em tecidos planos, '
          'como o algodão, o fio corre paralelo à ourela, a borda que não '
          'desfia, e a peça cortada fora do fio tende a cair torta. Antes '
          'da costura definitiva, vale fazer o alinhavo, um ponto largo e '
          'provisório que mantém as partes no lugar para a prova.',
    ],
  ),
  Artigo(
    id: 'a055',
    objetivoId: 'oficio',
    categoriaId: 'oficio_jardinagem',
    nivel: 1,
    titulo: 'Como regar sem afogar a planta',
    autor: 'Equipe Ikai',
    resumo:
        'Mais plantas morrem por excesso de água do que por falta dela. '
        'Veja como acertar a dose.',
    tags: ['plantas', 'rega', 'cuidados'],
    paragrafos: [
      'A maioria das plantas de vaso precisa de um vaso com furos no '
          'fundo, para que a água sobrante escoe. Raízes encharcadas ficam '
          'sem ar e podem apodrecer. Por isso, mais importante do que '
          'seguir um calendário fixo é conferir o solo: enfie o dedo cerca '
          'de dois ou três centímetros na terra, e regue apenas se estiver '
          'seca.',
      'O melhor horário para regar é de manhã cedo ou no fim da tarde, '
          'quando há menos evaporação. Molhe a terra, e não as folhas, para '
          'reduzir o risco de fungos. Cada espécie tem sua necessidade: '
          'suculentas e cactos pedem pouca água, enquanto samambaias '
          'preferem a terra úmida.',
    ],
  ),
  Artigo(
    id: 'a056',
    objetivoId: 'oficio',
    categoriaId: 'oficio_mecanica',
    nivel: 2,
    titulo: 'Os quatro tempos do motor',
    autor: 'Equipe Ikai',
    resumo:
        'Admissão, compressão, combustão e escape: o ciclo que move a '
        'maioria dos carros.',
    tags: ['motor', 'carro', 'manutenção'],
    paragrafos: [
      'A maioria dos carros usa um motor de combustão interna de quatro '
          'tempos. Na admissão, o pistão desce e puxa a mistura de ar e '
          'combustível. Na compressão, ele sobe e comprime essa mistura. Na '
          'combustão, uma faísca da vela provoca a queima e empurra o '
          'pistão para baixo. No escape, o pistão sobe de novo e expulsa os '
          'gases queimados.',
      'O óleo do motor lubrifica as peças que se movem e reduz o '
          'atrito. Para conferir o nível, estacione em local plano, com o '
          'motor desligado, e siga a orientação do manual sobre o momento '
          'certo. Então retire a vareta, limpe-a, recoloque e retire de '
          'novo: o nível deve ficar entre as marcas mínima e máxima. Siga '
          'sempre o manual do veículo para o tipo de óleo e os prazos de '
          'troca.',
    ],
  ),
  Artigo(
    id: 'a057',
    objetivoId: 'oficio',
    categoriaId: 'oficio_fotografia',
    nivel: 2,
    titulo: 'O triângulo da exposição',
    autor: 'Equipe Ikai',
    resumo:
        'Abertura, velocidade e ISO controlam a luz que chega ao sensor. '
        'Entender os três muda suas fotos.',
    tags: ['fotografia', 'exposição', 'câmera'],
    paragrafos: [
      'A exposição é a quantidade de luz que chega ao sensor da câmera, '
          'e três ajustes a controlam. A abertura do diafragma regula a '
          'passagem de luz e também a profundidade de campo, isto é, quanto '
          'da imagem fica nítido. A velocidade do obturador define por '
          'quanto tempo o sensor recebe luz. O ISO indica a sensibilidade '
          'do sensor.',
      'Os três se compensam. Uma velocidade alta congela o movimento, '
          'mas deixa entrar menos luz, e para compensar é preciso abrir '
          'mais o diafragma ou aumentar o ISO, o que pode gerar ruído na '
          'imagem. Para a composição, uma dica clássica é a regra dos '
          'terços: dividir o quadro em nove partes iguais e posicionar o '
          'assunto em uma das linhas ou cruzamentos.',
    ],
  ),
  Artigo(
    id: 'a058',
    objetivoId: 'oficio',
    categoriaId: 'oficio_desenho',
    nivel: 1,
    titulo: 'Aprender a observar antes de desenhar',
    autor: 'Equipe Ikai',
    resumo:
        'Desenhar é, antes de tudo, aprender a olhar. Formas simples '
        'ajudam a começar.',
    tags: ['desenho', 'observação', 'formas'],
    paragrafos: [
      'Quase todo objeto pode ser visto como uma combinação de formas '
          'básicas: círculos, quadrados e triângulos. Começar por essas '
          'formas, com traços leves, ajuda a acertar as proporções antes de '
          'entrar nos detalhes. Compare sempre o tamanho de uma parte com o '
          'das outras, e não apenas com a imagem que você tem na cabeça.',
      'Depois da forma, observe a luz. Onde a luz bate, o desenho fica '
          'claro, e onde ela não alcança, aparece a sombra. Variar a '
          'pressão do lápis cria diferentes tons. Desenhar um objeto '
          'simples por dez minutos todos os dias costuma trazer mais '
          'evolução do que um desenho longo uma vez por mês.',
    ],
  ),
  Artigo(
    id: 'a059',
    objetivoId: 'oficio',
    categoriaId: 'oficio_artesanato',
    nivel: 1,
    titulo: 'Crochê e tricô: qual é a diferença',
    autor: 'Equipe Ikai',
    resumo:
        'Os dois usam fio e agulha, mas são técnicas diferentes. Saiba '
        'por onde começar.',
    tags: ['crochê', 'tricô', 'trabalhos manuais'],
    paragrafos: [
      'No crochê, usa-se uma única agulha com um gancho na ponta, e '
          'cada ponto é concluído antes de seguir para o próximo. No tricô, '
          'usam-se duas agulhas longas, e muitos pontos ficam abertos ao '
          'mesmo tempo na agulha. Por isso, o crochê costuma ser '
          'considerado mais fácil para quem está começando.',
      'O ponto mais básico do crochê é a corrente, feita puxando uma '
          'laçada pela outra. A partir dele, surgem o ponto baixo, o ponto '
          'alto e muitas outras combinações. Comece com um fio de espessura '
          'média, de cor clara, para enxergar bem cada ponto, e faça uma '
          'pequena amostra antes de iniciar uma peça maior.',
    ],
  ),
  Artigo(
    id: 'a060',
    objetivoId: 'oficio',
    categoriaId: 'oficio_instrumento',
    nivel: 1,
    titulo: 'Praticar pouco, todos os dias',
    autor: 'Equipe Ikai',
    resumo:
        'Quinze minutos diários rendem mais do que duas horas de uma vez '
        'só, uma vez por semana.',
    tags: ['música', 'prática', 'aprendizagem'],
    paragrafos: [
      'Estudos sobre aprendizagem mostram que a prática distribuída ao '
          'longo do tempo funciona melhor do que a prática concentrada em '
          'um único dia, um efeito conhecido como espaçamento. Com um '
          'instrumento, isso significa que quinze ou vinte minutos por dia '
          'tendem a render mais do que uma sessão longa e irregular.',
      'Duas ferramentas ajudam muito. A primeira é o metrônomo, que '
          'mantém o ritmo constante. A segunda é a velocidade lenta: tocar '
          'um trecho devagar, sem erros, e só então acelerar, evita fixar '
          'vícios difíceis de corrigir. Em vez de repetir a música inteira, '
          'isole o compasso que dá mais trabalho e pratique só ele.',
    ],
  ),
];
