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
///     objetivoId: 'ler',               // 'ver_conteudo' | 'ler' | 'estudar'
///     categoriaId: 'ler_romance',      // id de uma categoria do objetivo
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
/// lib/pages_configurar/objetivo_conteudo.dart, objetivo_leitura.dart e
/// objetivo_estudo.dart. O teste `flutter test` avisa se algum id estiver
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
];
