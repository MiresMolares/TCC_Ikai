import 'comunidade.dart';

/// Comunidades fixas do app. As criadas pelos usuários vêm do repositório de
/// conteúdo (hoje local, depois o banco de dados). Os ícones são ids de
/// `iconesDeComunidade` (lib/pages_home/icones_comunidade.dart).
const List<Comunidade> comunidadesFixas = [
  Comunidade(
    id: 'historia',
    nome: 'História em pauta',
    descricao: 'Fatos, contextos e personagens que ajudam a entender o hoje.',
    iconeId: 'historia',
    categoriaIds: {'estudar_historia', 'ver_cultura'},
    regras: [
      'Cite sempre de onde veio a informação.',
      'Debata ideias, nunca pessoas.',
      'Sem conteúdo que incite ódio.',
    ],
  ),
  Comunidade(
    id: 'leitores',
    nome: 'Clube de leitores',
    descricao: 'Romances, aventuras e clássicos para conversar com calma.',
    iconeId: 'livro',
    categoriaIds: {'ler_romance', 'ler_aventura', 'ler_biografia'},
    regras: [
      'Evite revelar o final sem avisar.',
      'Indique a leitura, não cobre a de ninguém.',
      'Respeite gostos diferentes.',
    ],
  ),
  Comunidade(
    id: 'ciencia',
    nome: 'Curiosos da ciência',
    descricao: 'Do átomo ao cosmos, em textos curtos e sem pressa.',
    iconeId: 'ciencia',
    categoriaIds: {
      'ver_cientifico',
      'ver_curiosidades',
      'estudar_fisica',
      'estudar_quimica',
      'estudar_biologia',
    },
    regras: [
      'Prefira fontes e estudos a opiniões soltas.',
      'Dúvida é bem-vinda; deboche não.',
    ],
  ),
  Comunidade(
    id: 'ideias',
    nome: 'Filosofia e sociedade',
    descricao: 'Perguntas grandes, respostas abertas.',
    iconeId: 'ideias',
    categoriaIds: {'estudar_filosofia', 'estudar_sociologia'},
    regras: ['Ouça antes de responder.', 'Nenhum assunto vale uma ofensa.'],
  ),
];
