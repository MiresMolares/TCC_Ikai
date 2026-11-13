import { MongoClient } from 'mongodb';
import {
  CATEGORIAS_INFO, OBJETIVOS, OBJETIVOS_INFO, OBJETIVO_DA_CATEGORIA,
} from './catalogo.js';
import { criarColecoes } from './esquemas.js';

const NOVENTA_DIAS = 90 * 24 * 3600;

/** Grava o catálogo (objetivos e categorias) a partir de src/catalogo.js. Pode rodar sempre. */
export async function sincronizarCatalogo(db) {
  const objetivos = Object.keys(OBJETIVOS).map((id, i) => ({
    replaceOne: {
      filter: { _id: id },
      replacement: { _id: id, ...OBJETIVOS_INFO[id], ordem: i + 1 },
      upsert: true,
    },
  }));
  const categorias = Object.entries(OBJETIVOS).flatMap(([obj, lista]) =>
    lista.map((id, i) => ({
      replaceOne: {
        filter: { _id: id },
        replacement: { _id: id, objetivoId: OBJETIVO_DA_CATEGORIA[id] ?? obj, ...CATEGORIAS_INFO[id], ordem: i + 1 },
        upsert: true,
      },
    })));
  await db.objetivos.bulkWrite(objetivos);
  await db.categorias.bulkWrite(categorias);
}

/** Cria os índices. O nome de cada um aparece na documentação do banco. */
export async function criarIndices(db) {
  await Promise.all([
    // Sem nome próprio: é o mesmo índice (email_1) que a versão anterior já criava.
    db.usuarios.createIndex({ email: 1 }, { unique: true }),

    db.categorias.createIndex({ objetivoId: 1, ordem: 1 }, { name: 'por_objetivo' }),

    db.sessoes.createIndex({ usuarioId: 1, iniciadaEm: -1 }, { name: 'historico_do_usuario' }),
    // Uma sessão ativa por usuário: o próprio banco impede duas ao mesmo tempo.
    db.sessoes.createIndex(
      { usuarioId: 1 },
      { unique: true, partialFilterExpression: { estado: 'ativa' }, name: 'uma_sessao_ativa' },
    ),

    db.notificacoes.createIndex({ usuarioId: 1, criadaEm: -1 }, { name: 'caixa_do_usuario' }),
    db.notificacoes.createIndex({ usuarioId: 1, lida: 1 }, { name: 'nao_lidas' }),
    // Notificações somem sozinhas depois de 90 dias.
    db.notificacoes.createIndex({ criadaEm: 1 }, { expireAfterSeconds: NOVENTA_DIAS, name: 'expira_em_90_dias' }),

    db.artigos.createIndex({ criadoEm: -1 }),
    db.artigos.createIndex({ autorId: 1 }),
    db.comunidades.createIndex({ nomeChave: 1 }, { unique: true }),
    db.comunidades.createIndex({ criadorId: 1 }),
    db.posts.createIndex({ comunidadeId: 1, criadoEm: -1 }),
    db.posts.createIndex({ autorId: 1, criadoEm: -1 }),
  ]);
}

/** Conecta, prepara o banco (coleções, regras, índices, catálogo) e devolve as coleções. */
export async function conectar(config) {
  const cliente = new MongoClient(config.mongoUri);
  await cliente.connect();
  const base = cliente.db(config.mongoDb);
  await criarColecoes(base);
  const db = {
    cliente,
    base,
    usuarios: base.collection('usuarios'),
    objetivos: base.collection('objetivos'),
    categorias: base.collection('categorias'),
    sessoes: base.collection('sessoes'),
    preferencias: base.collection('preferencias'),
    notificacoes: base.collection('notificacoes'),
    artigos: base.collection('artigos'),
    comunidades: base.collection('comunidades'),
    posts: base.collection('posts'),
  };
  await criarIndices(db);
  await sincronizarCatalogo(db);
  return db;
}
