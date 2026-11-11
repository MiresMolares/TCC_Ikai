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
