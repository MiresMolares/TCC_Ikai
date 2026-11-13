// Listas oficiais. Espelham lib/pages_configurar/objetivo_*.dart do app:
// ao criar uma categoria nova no app, inclua o id aqui.
export const OBJETIVOS = {
  ver_conteudo: [
    'ver_cientifico', 'ver_cultura', 'ver_jogos', 'ver_noticia',
    'ver_esporte', 'ver_curiosidades',
  ],
  ler: [
    'ler_romance', 'ler_fantasia', 'ler_suspense', 'ler_fc', 'ler_horror',
    'ler_terror', 'ler_religioso', 'ler_distopia', 'ler_aventura', 'ler_dp',
    'ler_tecnico', 'ler_biografia',
  ],
  estudar: [
    'estudar_matematica', 'estudar_lp', 'estudar_ingles', 'estudar_artes',
    'estudar_historia', 'estudar_geografia', 'estudar_filosofia',
    'estudar_sociologia', 'estudar_ef', 'estudar_biologia', 'estudar_fisica',
    'estudar_quimica',
  ],
};

export const CATEGORIAS = new Set(Object.values(OBJETIVOS).flat());

// Comunidades fixas do app (lib/data/comunidades_dados.dart). Elas moram no
// app; o servidor só precisa saber que existem para aceitar mensagens.
export const COMUNIDADES_FIXAS = new Set(['historia', 'leitores', 'ciencia', 'ideias']);

// lib/pages_home/icones_comunidade.dart
export const ICONES = new Set([
  'historia', 'livro', 'ciencia', 'ideias', 'musica', 'arte', 'natureza',
  'mundo', 'escrita', 'estrela', 'conversa', 'lampada',
]);

export const LIMITES = {
  tituloMin: 5, tituloMax: 100,
  resumoMin: 10, resumoMax: 200,
  corpoMin: 80, corpoMax: 12000, paragrafoMax: 2000,
  maxTags: 5, tagMin: 2, tagMax: 24,
  nomeMin: 3, nomeMax: 40,
  descricaoMin: 10, descricaoMax: 140,
  maxCategoriasComunidade: 5,
  maxRegras: 6, regraMax: 120,
  postMin: 3, postMax: 500,
  // frequência (contra abuso)
  postsPorHora: 20,
  artigosPorDia: 10,
  comunidadesPorDia: 5,
  iaPorHora: 60,
};

// Títulos e ícones do catálogo. Espelham lib/pages_configurar/objetivo_*.dart
// (o ícone é o nome do Icons.* do Flutter). Servem de semente da coleção
// `objetivos` e `categorias` (src/db.js, sincronizarCatalogo).
export const OBJETIVOS_INFO = {
  ver_conteudo: { titulo: "Ver conteúdo", icone: 'play_circle_outline' },
  ler: { titulo: "Ler", icone: 'menu_book_outlined' },
  estudar: { titulo: "Estudar", icone: 'school_outlined' },
};

export const CATEGORIAS_INFO = {
  ver_cientifico: { titulo: "Científico", icone: 'science_outlined' },
  ver_cultura: { titulo: "Cultura", icone: 'museum_outlined' },
  ver_jogos: { titulo: "Jogos", icone: 'sports_esports_outlined' },
  ver_noticia: { titulo: "Notícias", icone: 'newspaper_outlined' },
  ver_esporte: { titulo: "Esporte", icone: 'sports_soccer_outlined' },
  ver_curiosidades: { titulo: "Curiosidades", icone: 'lightbulb_outline' },
  ler_romance: { titulo: "Romance", icone: 'favorite_border' },
  ler_fantasia: { titulo: "Fantasia", icone: 'auto_awesome_outlined' },
  ler_suspense: { titulo: "Suspense", icone: 'visibility_outlined' },
  ler_fc: { titulo: "Ficção Científica", icone: 'rocket_launch_outlined' },
  ler_horror: { titulo: "Horror", icone: 'nights_stay_outlined' },
  ler_terror: { titulo: "Terror", icone: 'warning_amber_outlined' },
  ler_religioso: { titulo: "Religioso", icone: 'menu_book_outlined' },
  ler_distopia: { titulo: "Distopia", icone: 'public_off_outlined' },
  ler_aventura: { titulo: "Aventura", icone: 'explore_outlined' },
  ler_dp: { titulo: "Desenvolvimento Pessoal", icone: 'psychology_outlined' },
  ler_tecnico: { titulo: "Técnico", icone: 'build_outlined' },
  ler_biografia: { titulo: "Biografia", icone: 'person_outline' },
  estudar_matematica: { titulo: "Matemática", icone: 'calculate_outlined' },
  estudar_lp: { titulo: "LP: Língua Portuguesa", icone: 'menu_book_outlined' },
  estudar_ingles: { titulo: "Inglês", icone: 'translate_outlined' },
  estudar_artes: { titulo: "Artes", icone: 'palette_outlined' },
  estudar_historia: { titulo: "História", icone: 'account_balance_outlined' },
  estudar_geografia: { titulo: "Geografia", icone: 'public_outlined' },
  estudar_filosofia: { titulo: "Filosofia", icone: 'psychology_outlined' },
  estudar_sociologia: { titulo: "Sociologia", icone: 'groups_outlined' },
  estudar_ef: { titulo: "Educação Física", icone: 'fitness_center_outlined' },
  estudar_biologia: { titulo: "Biologia", icone: 'eco_outlined' },
  estudar_fisica: { titulo: "Física", icone: 'bolt_outlined' },
  estudar_quimica: { titulo: "Química", icone: 'science_outlined' },
};

/** Objetivo ao qual uma categoria pertence (ex.: estudar_ingles -> estudar). */
export const OBJETIVO_DA_CATEGORIA = Object.fromEntries(
  Object.entries(OBJETIVOS).flatMap(([o, lista]) => lista.map((c) => [c, o])),
);
