// Listas oficiais. Espelham lib/pages_configurar/objetivo_*.dart do app:
// ao criar uma categoria nova no app, inclua o id aqui.
export const OBJETIVOS = {
  ver_conteudo: [
    'ver_cientifico', 'ver_cultura', 'ver_jogos', 'ver_noticia',
    'ver_esporte', 'ver_curiosidades', 'ver_natureza', 'ver_tecnologia',
    'ver_espaco', 'ver_musica', 'ver_cinema', 'ver_gastronomia',
    'ver_viagens', 'ver_arquitetura', 'ver_saude', 'ver_economia',
  ],
  ler: [
    'ler_romance', 'ler_fantasia', 'ler_suspense', 'ler_fc', 'ler_horror',
    'ler_terror', 'ler_religioso', 'ler_distopia', 'ler_aventura', 'ler_dp',
    'ler_tecnico', 'ler_biografia', 'ler_poesia', 'ler_classicos',
    'ler_ficcao_historica', 'ler_cronicas',
  ],
  estudar: [
    'estudar_matematica', 'estudar_lp', 'estudar_ingles', 'estudar_artes',
    'estudar_historia', 'estudar_geografia', 'estudar_filosofia',
    'estudar_sociologia', 'estudar_ef', 'estudar_biologia',
    'estudar_fisica', 'estudar_quimica', 'estudar_programacao',
    'estudar_espanhol', 'estudar_redacao', 'estudar_financas',
  ],
  oficio: [
    'oficio_marcenaria', 'oficio_eletrica', 'oficio_hidraulica',
    'oficio_culinaria', 'oficio_panificacao', 'oficio_costura',
    'oficio_jardinagem', 'oficio_mecanica', 'oficio_fotografia',
    'oficio_desenho', 'oficio_artesanato', 'oficio_instrumento',
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
  oficio: { titulo: "Aprender um ofício", icone: 'handyman_outlined' },
};

export const CATEGORIAS_INFO = {
  ver_cientifico: { titulo: "Científico", icone: 'science_outlined' },
  ver_cultura: { titulo: "Cultura", icone: 'museum_outlined' },
  ver_jogos: { titulo: "Jogos", icone: 'sports_esports_outlined' },
  ver_noticia: { titulo: "Notícias", icone: 'newspaper_outlined' },
  ver_esporte: { titulo: "Esporte", icone: 'sports_soccer_outlined' },
  ver_curiosidades: { titulo: "Curiosidades", icone: 'lightbulb_outline' },
  ver_natureza: { titulo: "Natureza e animais", icone: 'eco_outlined' },
  ver_tecnologia: { titulo: "Tecnologia", icone: 'computer_outlined' },
  ver_espaco: { titulo: "Espaço", icone: 'rocket_launch_outlined' },
  ver_musica: { titulo: "Música", icone: 'library_music_outlined' },
  ver_cinema: { titulo: "Cinema e séries", icone: 'movie_outlined' },
  ver_gastronomia: { titulo: "Gastronomia", icone: 'restaurant_outlined' },
  ver_viagens: { titulo: "Viagens e lugares", icone: 'flight_outlined' },
  ver_arquitetura: { titulo: "Arquitetura e cidades", icone: 'apartment_outlined' },
  ver_saude: { titulo: "Saúde e bem-estar", icone: 'spa_outlined' },
  ver_economia: { titulo: "Dinheiro e economia", icone: 'savings_outlined' },
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
  ler_poesia: { titulo: "Poesia", icone: 'auto_stories_outlined' },
  ler_classicos: { titulo: "Clássicos", icone: 'history_edu_outlined' },
  ler_ficcao_historica: { titulo: "Ficção histórica", icone: 'castle_outlined' },
  ler_cronicas: { titulo: "Crônicas e contos", icone: 'edit_note_outlined' },
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
  estudar_programacao: { titulo: "Programação", icone: 'code_outlined' },
  estudar_espanhol: { titulo: "Espanhol", icone: 'translate_outlined' },
  estudar_redacao: { titulo: "Redação", icone: 'edit_note_outlined' },
  estudar_financas: { titulo: "Educação financeira", icone: 'savings_outlined' },
  oficio_marcenaria: { titulo: "Marcenaria", icone: 'carpenter_outlined' },
  oficio_eletrica: { titulo: "Elétrica residencial", icone: 'electrical_services_outlined' },
  oficio_hidraulica: { titulo: "Hidráulica", icone: 'plumbing_outlined' },
  oficio_culinaria: { titulo: "Culinária", icone: 'restaurant_menu_outlined' },
  oficio_panificacao: { titulo: "Panificação", icone: 'bakery_dining_outlined' },
  oficio_costura: { titulo: "Costura", icone: 'checkroom_outlined' },
  oficio_jardinagem: { titulo: "Jardinagem", icone: 'yard_outlined' },
  oficio_mecanica: { titulo: "Mecânica", icone: 'car_repair_outlined' },
  oficio_fotografia: { titulo: "Fotografia", icone: 'photo_camera_outlined' },
  oficio_desenho: { titulo: "Desenho", icone: 'draw_outlined' },
  oficio_artesanato: { titulo: "Artesanato", icone: 'brush_outlined' },
  oficio_instrumento: { titulo: "Tocar um instrumento", icone: 'piano_outlined' },
};

/** Objetivo ao qual uma categoria pertence (ex.: estudar_ingles -> estudar). */
export const OBJETIVO_DA_CATEGORIA = Object.fromEntries(
  Object.entries(OBJETIVOS).flatMap(([o, lista]) => lista.map((c) => [c, o])),
);
