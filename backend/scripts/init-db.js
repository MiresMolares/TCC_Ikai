// Prepara o banco: cria as coleções com as regras de validação, os índices e
// grava o catálogo de objetivos e categorias. Pode rodar quantas vezes quiser.
//   MONGODB_URI=mongodb://127.0.0.1:27017 npm run db:init
import { lerConfig } from '../src/config.js';
import { conectar } from '../src/db.js';

const config = lerConfig();
const db = await conectar(config);
const colecoes = await db.base.listCollections().toArray();
console.log(`Banco "${config.mongoDb}" pronto em ${config.mongoUri}`);
for (const c of colecoes.sort((a, b) => a.name.localeCompare(b.name))) {
  const n = await db.base.collection(c.name).countDocuments();
  const indices = (await db.base.collection(c.name).indexes()).map((i) => i.name).join(', ');
  console.log(`  ${c.name.padEnd(13)} ${String(n).padStart(3)} docs   índices: ${indices}`);
}
await db.cliente.close();
