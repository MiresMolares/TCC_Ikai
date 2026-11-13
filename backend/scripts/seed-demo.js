// Cria dados de exemplo para mostrar o banco funcionando (conta, sessões,
// preferências e notificações). Só use em banco de teste.
//   MONGODB_URI=mongodb://127.0.0.1:27017 npm run db:demo
// Conta de exemplo: ana@exemplo.com / senha-demo-123
import bcrypt from 'bcryptjs';
import { lerConfig } from '../src/config.js';
import { conectar } from '../src/db.js';

const config = lerConfig();
const db = await conectar(config);

const email = 'ana@exemplo.com';
await db.usuarios.updateOne(
  { email },
  { $setOnInsert: { nome: 'Ana Souza', email, senhaHash: await bcrypt.hash('senha-demo-123', 10), criadoEm: new Date() } },
  { upsert: true },
);
const ana = await db.usuarios.findOne({ email });

const hora = 3600e3;
const sessao = (horasAtras, objetivoId, categoriaIds, duracaoSegundos) => {
  const iniciadaEm = new Date(Date.now() - horasAtras * hora);
  const expiraEm = new Date(iniciadaEm.getTime() + duracaoSegundos * 1000);
  return { usuarioId: ana._id, objetivoId, categoriaIds, duracaoSegundos, iniciadaEm, expiraEm, encerradaEm: expiraEm, estado: 'expirada' };
};
await db.sessoes.deleteMany({ usuarioId: ana._id });
await db.sessoes.insertMany([
  sessao(70, 'ler', ['ler_distopia'], 1800),
  sessao(46, 'estudar', ['estudar_ingles'], 1200),
  sessao(26, 'estudar', ['estudar_historia', 'estudar_filosofia'], 2400),
  sessao(5, 'ver_conteudo', ['ver_cientifico', 'ver_curiosidades'], 900),
]);

await db.preferencias.updateOne(
  { _id: ana._id },
  { $set: { tema: 'claro', tamanhoTexto: 1.2, notificacoes: true, nivelConteudo: 2, metaDiariaMin: 90, atualizadoEm: new Date() } },
  { upsert: true },
);

await db.notificacoes.deleteMany({ usuarioId: ana._id });
await db.notificacoes.insertMany([
  { usuarioId: ana._id, tipo: 'conquista', titulo: 'Meta diária cumprida', descricao: 'Você ficou dentro dos 90 minutos de ontem.', criadaEm: new Date(Date.now() - 20 * hora), lida: true },
  { usuarioId: ana._id, tipo: 'lembrete', titulo: 'Hora de uma pausa', descricao: 'Levante, beba água e olhe pela janela.', criadaEm: new Date(Date.now() - 2 * hora), lida: false },
]);

console.log(`Dados de exemplo gravados no banco "${config.mongoDb}" (conta ${email}).`);
await db.cliente.close();
