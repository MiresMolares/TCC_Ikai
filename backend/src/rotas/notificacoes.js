import { Router } from 'express';
import { ObjectId } from 'mongodb';
import { exigirLogin } from '../auth.js';
import { ErroHttp, naoEncontrado, ruim } from '../erros.js';
import { limpo } from '../texto.js';

const TIPOS = ['lembrete', 'conquista', 'comunidade', 'sistema'];
const MAX_GUARDADAS = 200;

export function rotasNotificacoes({ db, config }) {
  const r = Router();
  const login = exigirLogin({ db, config });

  const saida = (n) => ({
    id: n._id, tipo: n.tipo, titulo: n.titulo, descricao: n.descricao, criadaEm: n.criadaEm, lida: n.lida,
  });

  const idDaRota = (req) => {
    if (!ObjectId.isValid(req.params.id)) throw naoEncontrado('Notificação não encontrada.');
    return new ObjectId(req.params.id);
  };

  // Caixa de entrada. ?lida=false traz só as não lidas; ?limite=50 (1 a 100).
  r.get('/notificacoes', login, async (req, res) => {
    const limite = Math.min(100, Math.max(1, Number.parseInt(req.query.limite, 10) || 50));
    const filtro = { usuarioId: req.usuario._id };
    if (req.query.lida === 'false') filtro.lida = false;
    if (req.query.lida === 'true') filtro.lida = true;
    const [lista, naoLidas] = await Promise.all([
      db.notificacoes.find(filtro).sort({ criadaEm: -1 }).limit(limite).toArray(),
      db.notificacoes.countDocuments({ usuarioId: req.usuario._id, lida: false }),
    ]);
    res.json({ naoLidas, itens: lista.map(saida) });
  });

  r.post('/notificacoes', login, async (req, res) => {
    const b = req.body ?? {};
    const tipo = String(b.tipo ?? '');
    const titulo = limpo(b.titulo);
    const descricao = limpo(b.descricao ?? '');
    if (!TIPOS.includes(tipo)) throw ruim(`O tipo deve ser um destes: ${TIPOS.join(', ')}.`);
    if (titulo.length < 1 || titulo.length > 80) throw ruim('O título precisa ter de 1 a 80 caracteres.');
    if (descricao.length > 300) throw ruim('A descrição pode ter no máximo 300 caracteres.');
    if ((await db.notificacoes.countDocuments({ usuarioId: req.usuario._id })) >= MAX_GUARDADAS) {
      throw new ErroHttp(429, 'Sua caixa está cheia. Apague notificações antigas.');
    }
    const doc = { usuarioId: req.usuario._id, tipo, titulo, descricao, criadaEm: new Date(), lida: false };
    const { insertedId } = await db.notificacoes.insertOne(doc);
    res.status(201).json(saida({ ...doc, _id: insertedId }));
  });

  // Marcar todas como lidas (antes de /:id para não confundir as rotas).
  r.post('/notificacoes/ler-todas', login, async (req, res) => {
    const { modifiedCount } = await db.notificacoes.updateMany(
      { usuarioId: req.usuario._id, lida: false }, { $set: { lida: true } },
    );
    res.json({ marcadas: modifiedCount });
  });

  r.patch('/notificacoes/:id', login, async (req, res) => {
    const id = idDaRota(req);
    if (typeof req.body?.lida !== 'boolean') throw ruim('Envie "lida" como verdadeiro ou falso.');
    const n = await db.notificacoes.findOneAndUpdate(
      { _id: id, usuarioId: req.usuario._id }, { $set: { lida: req.body.lida } }, { returnDocument: 'after' },
    );
    if (!n) throw naoEncontrado('Notificação não encontrada.');
    res.json(saida(n));
  });

  r.delete('/notificacoes/:id', login, async (req, res) => {
    const { deletedCount } = await db.notificacoes.deleteOne({ _id: idDaRota(req), usuarioId: req.usuario._id });
    if (!deletedCount) throw naoEncontrado('Notificação não encontrada.');
    res.status(204).end();
  });

  // Limpar a caixa.
  r.delete('/notificacoes', login, async (req, res) => {
    await db.notificacoes.deleteMany({ usuarioId: req.usuario._id });
    res.status(204).end();
  });

  return r;
}
