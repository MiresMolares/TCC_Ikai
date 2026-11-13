// Regras de validação do banco (JSON Schema do MongoDB).
// O banco recusa documentos fora destas regras, mesmo que o código da API
// tenha um erro. O nível é "moderate": documentos antigos que já estavam
// guardados não impedem atualizações, mas tudo que entra de novo é conferido.
import { CATEGORIAS, OBJETIVOS } from './catalogo.js';

const OBJETIVO_IDS = Object.keys(OBJETIVOS);
const CATEGORIA_IDS = [...CATEGORIAS];

const texto = (min, max) => ({ bsonType: 'string', minLength: min, maxLength: max });
const inteiro = (min, max) => ({ bsonType: ['int', 'long'], minimum: min, maximum: max });
const nuloOu = (tipo) => ({ bsonType: [tipo, 'null'] });

export const ESQUEMAS = {
  usuarios: {
    bsonType: 'object',
    required: ['nome', 'email', 'senhaHash', 'criadoEm'],
    properties: {
      nome: texto(2, 80),
      email: { bsonType: 'string', maxLength: 120, pattern: '^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$' },
      senhaHash: texto(20, 100), // hash bcrypt, nunca a senha
      fotoUrl: { bsonType: ['string', 'null'], maxLength: 300 },
      criadoEm: { bsonType: 'date' },
    },
  },

  objetivos: {
    bsonType: 'object',
    required: ['_id', 'titulo', 'icone', 'ordem'],
    properties: {
      _id: { enum: OBJETIVO_IDS },
      titulo: texto(1, 40),
      icone: texto(1, 60),
      ordem: inteiro(1, 99),
    },
  },

  categorias: {
    bsonType: 'object',
    required: ['_id', 'objetivoId', 'titulo', 'icone', 'ordem'],
    properties: {
      _id: { enum: CATEGORIA_IDS },
      objetivoId: { enum: OBJETIVO_IDS },
      titulo: texto(1, 60),
      icone: texto(1, 60),
      ordem: inteiro(1, 99),
    },
  },

  // Uma linha por sessão de uso: o que a pessoa declarou antes de entrar.
  sessoes: {
    bsonType: 'object',
    required: [
      'usuarioId', 'objetivoId', 'categoriaIds', 'duracaoSegundos',
      'iniciadaEm', 'expiraEm', 'estado',
    ],
    properties: {
      usuarioId: { bsonType: 'objectId' },
      objetivoId: { enum: OBJETIVO_IDS },
      // Até 5 categorias, todas do mesmo objetivo (como no app).
      categoriaIds: { bsonType: 'array', minItems: 1, maxItems: 5, uniqueItems: true, items: { enum: CATEGORIA_IDS } },
      duracaoSegundos: inteiro(1, 10800), // RN01: de 1 s a 3 h
      iniciadaEm: { bsonType: 'date' },
      expiraEm: { bsonType: 'date' },
      encerradaEm: nuloOu('date'),
      estado: { enum: ['ativa', 'expirada'] },
    },
  },

  // Um documento por usuário; o _id é o próprio id do usuário (relação 1 para 1).
  preferencias: {
    bsonType: 'object',
    required: ['_id', 'atualizadoEm'],
    properties: {
      _id: { bsonType: 'objectId' },
      tema: { enum: ['claro', 'escuro', 'sistema'] },
      altoContraste: { bsonType: 'bool' },
      tamanhoTexto: { bsonType: ['double', 'int', 'long'], minimum: 0.8, maximum: 1.4 },
      notificacoes: { bsonType: 'bool' },
      lembretes: { bsonType: 'bool' },
      sons: { bsonType: 'bool' },
      vibracao: { bsonType: 'bool' },
      nivelConteudo: inteiro(0, 3), // 0 todos, 1 a 3 níveis
      iaAutorizada: nuloOu('bool'), // null: ainda não respondeu
      metaDiariaMin: { bsonType: ['int', 'long', 'null'], minimum: 1, maximum: 1440 },
      atualizadoEm: { bsonType: 'date' },
    },
  },

  notificacoes: {
    bsonType: 'object',
    required: ['usuarioId', 'tipo', 'titulo', 'descricao', 'criadaEm', 'lida'],
    properties: {
      usuarioId: { bsonType: 'objectId' },
      tipo: { enum: ['lembrete', 'conquista', 'comunidade', 'sistema'] },
      titulo: texto(1, 80),
      descricao: texto(0, 300),
      criadaEm: { bsonType: 'date' },
      lida: { bsonType: 'bool' },
    },
  },

  artigos: {
    bsonType: 'object',
    required: [
      '_id', 'autorId', 'autorNome', 'objetivo', 'categoria', 'nivel',
      'titulo', 'resumo', 'tags', 'paragrafos', 'criadoEm',
    ],
    properties: {
      _id: { bsonType: 'string' },
      autorId: { bsonType: 'objectId' },
      autorNome: texto(1, 80),
      objetivo: { enum: OBJETIVO_IDS },
      categoria: { enum: CATEGORIA_IDS },
      nivel: inteiro(1, 3),
      titulo: texto(5, 100),
      resumo: texto(10, 200),
      tags: { bsonType: 'array', maxItems: 5, items: { bsonType: 'string' } },
      paragrafos: { bsonType: 'array', minItems: 1, items: texto(1, 2000) },
      criadoEm: { bsonType: 'date' },
    },
  },

  comunidades: {
    bsonType: 'object',
    required: [
      '_id', 'criadorId', 'nome', 'nomeChave', 'descricao', 'icone',
      'categorias', 'regras', 'criadoEm',
    ],
    properties: {
      _id: { bsonType: 'string' },
      criadorId: { bsonType: 'objectId' },
      nome: texto(3, 40),
      nomeChave: { bsonType: 'string' },
      descricao: texto(10, 140),
      icone: { bsonType: 'string' },
      categorias: { bsonType: 'array', maxItems: 5, items: { enum: CATEGORIA_IDS } },
      regras: { bsonType: 'array', maxItems: 6, items: texto(1, 120) },
      criadoEm: { bsonType: 'date' },
    },
  },

  posts: {
    bsonType: 'object',
    required: ['_id', 'comunidadeId', 'autorId', 'autorNome', 'texto', 'criadoEm'],
    properties: {
      _id: { bsonType: 'string' },
      comunidadeId: { bsonType: 'string' },
      autorId: { bsonType: 'objectId' },
      autorNome: texto(1, 80),
      texto: texto(3, 500),
      criadoEm: { bsonType: 'date' },
    },
  },
};

/** Cria as coleções com as regras acima; se já existem, só atualiza as regras. */
export async function criarColecoes(base) {
  const existentes = new Set((await base.listCollections({}, { nameOnly: true }).toArray()).map((c) => c.name));
  for (const [nome, schema] of Object.entries(ESQUEMAS)) {
    const validator = { $jsonSchema: schema };
    if (existentes.has(nome)) {
      await base.command({ collMod: nome, validator, validationLevel: 'moderate', validationAction: 'error' });
    } else {
      await base.createCollection(nome, { validator, validationLevel: 'moderate', validationAction: 'error' });
    }
  }
}
