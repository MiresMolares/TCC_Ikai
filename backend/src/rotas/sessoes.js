import { Router } from 'express';
import { ObjectId } from 'mongodb';
import { exigirLogin } from '../auth.js';
import { conflito, naoEncontrado, ruim } from '../erros.js';
import { dia } from '../texto.js';

const DURACAO_MAX = 10800; // RN01: de 1 segundo a 3 horas
const MAX_CATEGORIAS = 5;

/** Sessões cujo tempo acabou passam a "expirada". Quem manda é o relógio do servidor. */
export function expirarVencidas(db, usuarioId) {
  return db.sessoes.updateMany(
    { usuarioId, estado: 'ativa', expiraEm: { $lte: new Date() } },
    [{ $set: { estado: 'expirada', encerradaEm: '$expiraEm' } }],
  );
}

export function rotasSessoes({ db, config }) {
  const r = Router();
  const login = exigirLogin({ db, config });

  const saida = (s) => ({
    id: s._id,
    objetivo: s.objetivoId,
    categorias: s.categoriaIds,
    duracaoSegundos: s.duracaoSegundos,
    estado: s.estado,
    iniciadaEm: s.iniciadaEm,
    expiraEm: s.expiraEm,
    encerradaEm: s.encerradaEm ?? null,
    restanteSegundos: s.estado === 'ativa'
      ? Math.max(0, Math.ceil((s.expiraEm.getTime() - Date.now()) / 1000))
      : 0,
  });

  // Começa uma sessão. O app só libera o conteúdo depois disto.
  r.post('/sessoes', login, async (req, res) => {
    const b = req.body ?? {};
    const objetivo = String(b.objetivo ?? '');
    const duracao = b.duracaoSegundos;
    // Aceita "categorias": [...] (várias) ou "categoria": "..." (uma só).
    const bruto = Array.isArray(b.categorias) ? b.categorias : (b.categoria ? [b.categoria] : []);
    const categorias = [...new Set(bruto.map((c) => String(c)))];

    if (!(await db.objetivos.findOne({ _id: objetivo }))) throw ruim('Escolha o objetivo.');
    if (categorias.length < 1) throw ruim('Escolha pelo menos uma categoria.');
    if (categorias.length > MAX_CATEGORIAS) throw ruim(`Escolha no máximo ${MAX_CATEGORIAS} categorias.`);
    const validas = await db.categorias.countDocuments({ _id: { $in: categorias }, objetivoId: objetivo });
    if (validas !== categorias.length) throw ruim('Há categoria que não pertence ao objetivo escolhido.');
    if (!Number.isInteger(duracao) || duracao < 1 || duracao > DURACAO_MAX) {
      throw ruim('A duração deve ficar entre 1 segundo e 3 horas.');
    }

    await expirarVencidas(db, req.usuario._id);
    const agora = new Date();
    const doc = {
      usuarioId: req.usuario._id,
      objetivoId: objetivo,
      categoriaIds: categorias,
      duracaoSegundos: duracao,
      iniciadaEm: agora,
      expiraEm: new Date(agora.getTime() + duracao * 1000),
      encerradaEm: null,
      estado: 'ativa',
    };
    try {
      const { insertedId } = await db.sessoes.insertOne(doc);
      res.status(201).json(saida({ ...doc, _id: insertedId }));
    } catch (e) {
      if (e?.code === 11000) {
        const ativa = await db.sessoes.findOne({ usuarioId: req.usuario._id, estado: 'ativa' });
        const resta = ativa ? saida(ativa).restanteSegundos : 0;
        throw conflito(`Você já tem uma sessão em andamento. Ela termina em ${resta} s.`);
      }
      throw e;
    }
  });

  // A sessão em andamento, se houver (404 se não houver).
  r.get('/sessoes/ativa', login, async (req, res) => {
    await expirarVencidas(db, req.usuario._id);
    const s = await db.sessoes.findOne({ usuarioId: req.usuario._id, estado: 'ativa' });
    if (!s) throw naoEncontrado('Nenhuma sessão em andamento.');
    res.json(saida(s));
  });

  // Última sessão: o app sugere a mesma escolha na próxima vez
  // (no lugar das 3 chaves hist_* do aparelho).
  r.get('/sessoes/ultima', login, async (req, res) => {
    await expirarVencidas(db, req.usuario._id);
    const s = await db.sessoes.findOne({ usuarioId: req.usuario._id }, { sort: { iniciadaEm: -1 } });
    if (!s) throw naoEncontrado('Você ainda não fez nenhuma sessão.');
    res.json(saida(s));
  });

  // Histórico, da mais recente para a mais antiga. ?limite=20 (1 a 100) e ?antes=<data ISO>.
  r.get('/sessoes', login, async (req, res) => {
    await expirarVencidas(db, req.usuario._id);
    const limite = Math.min(100, Math.max(1, Number.parseInt(req.query.limite, 10) || 20));
    const filtro = { usuarioId: req.usuario._id };
    if (req.query.antes) {
      const d = new Date(String(req.query.antes));
      if (Number.isNaN(d.getTime())) throw ruim('Data inválida em "antes".');
      filtro.iniciadaEm = { $lt: d };
    }
    const lista = await db.sessoes.find(filtro).sort({ iniciadaEm: -1 }).limit(limite).toArray();
    res.json(lista.map(saida));
  });

  // Análise de desempenho dos últimos N dias (?dias=7, de 1 a 90): tempo por dia, objetivo e categoria.
  r.get('/sessoes/resumo', login, async (req, res) => {
    await expirarVencidas(db, req.usuario._id);
    const dias = Math.min(90, Math.max(1, Number.parseInt(req.query.dias, 10) || 7));
    const desde = new Date(Date.now() - dias * 24 * 3600e3);
    const base = [{ $match: { usuarioId: req.usuario._id, iniciadaEm: { $gte: desde } } }];
    const [porObjetivo, porCategoria, porDia, total] = await Promise.all([
      db.sessoes.aggregate([...base,
        { $group: { _id: '$objetivoId', sessoes: { $sum: 1 }, segundos: { $sum: '$duracaoSegundos' } } },
        { $sort: { segundos: -1 } }]).toArray(),
      db.sessoes.aggregate([...base,
        { $unwind: '$categoriaIds' },
        { $group: { _id: '$categoriaIds', sessoes: { $sum: 1 } } },
        { $sort: { sessoes: -1, _id: 1 } }, { $limit: 5 }]).toArray(),
      db.sessoes.aggregate([...base,
        { $group: { _id: { $dateToString: { format: '%Y-%m-%d', date: '$iniciadaEm' } }, segundos: { $sum: '$duracaoSegundos' } } },
        { $sort: { _id: 1 } }]).toArray(),
      db.sessoes.aggregate([...base,
        { $group: { _id: null, sessoes: { $sum: 1 }, segundos: { $sum: '$duracaoSegundos' } } }]).toArray(),
    ]);
    const titulos = Object.fromEntries(
      (await db.categorias.find({ _id: { $in: porCategoria.map((c) => c._id) } }).toArray()).map((c) => [c._id, c.titulo]),
    );
    res.json({
      dias,
      desde: dia(desde),
      sessoes: total[0]?.sessoes ?? 0,
      segundos: total[0]?.segundos ?? 0,
      porObjetivo: porObjetivo.map((o) => ({ objetivo: o._id, sessoes: o.sessoes, segundos: o.segundos })),
      categoriasMaisUsadas: porCategoria.map((c) => ({ categoria: c._id, titulo: titulos[c._id] ?? c._id, sessoes: c.sessoes })),
      porDia: porDia.map((d) => ({ dia: d._id, segundos: d.segundos })),
    });
  });

  r.get('/sessoes/:id', login, async (req, res) => {
    if (!ObjectId.isValid(req.params.id)) throw naoEncontrado('Sessão não encontrada.');
    await expirarVencidas(db, req.usuario._id);
    const s = await db.sessoes.findOne({ _id: new ObjectId(req.params.id), usuarioId: req.usuario._id });
    if (!s) throw naoEncontrado('Sessão não encontrada.');
    res.json(saida(s));
  });

  return r;
}
