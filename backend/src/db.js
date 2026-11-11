import { MongoClient } from 'mongodb';

/** Conecta, cria os índices e devolve as coleções. */
export async function conectar(config) {
  const cliente = new MongoClient(config.mongoUri);
  await cliente.connect();
  const base = cliente.db(config.mongoDb);
  const db = {
    cliente,
    base,
    usuarios: base.collection('usuarios'),
    artigos: base.collection('artigos'),
    comunidades: base.collection('comunidades'),
    posts: base.collection('posts'),
  };
  await Promise.all([
    db.usuarios.createIndex({ email: 1 }, { unique: true }),
    db.artigos.createIndex({ criadoEm: -1 }),
    db.artigos.createIndex({ autorId: 1 }),
    db.comunidades.createIndex({ nomeChave: 1 }, { unique: true }),
    db.comunidades.createIndex({ criadorId: 1 }),
    db.posts.createIndex({ comunidadeId: 1, criadoEm: -1 }),
    db.posts.createIndex({ autorId: 1, criadoEm: -1 }),
  ]);
  return db;
}
