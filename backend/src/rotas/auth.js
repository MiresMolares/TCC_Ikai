import { Router } from 'express';
import bcrypt from 'bcryptjs';
import rateLimit from 'express-rate-limit';
import { criarToken, exigirLogin } from '../auth.js';
import { conflito, naoAutorizado, ruim } from '../erros.js';
import { limpo } from '../texto.js';

const EMAIL = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const SENHA_MIN = 8;
const SENHA_MAX = 72; // limite do bcrypt

export function rotasAuth({ db, config }) {
  const r = Router();
  const login = exigirLogin({ db, config });

  const resposta = (u) => ({
    token: criarToken(config, u),
    usuario: { nome: u.nome, email: u.email },
    // O app usa isto para saber se pode oferecer a IA (a chave fica aqui).
    ia: Boolean(config.geminiKey),
  });

  // Contra tentativas de adivinhar senha: 20 a cada 15 minutos por IP.
  const limite = config.limitarLogin
    ? rateLimit({
        windowMs: 15 * 60 * 1000,
        limit: 20,
        standardHeaders: true,
        legacyHeaders: false,
        message: { erro: 'Muitas tentativas. Tente de novo em alguns minutos.' },
      })
    : (_req, _res, next) => next();

  r.post('/auth/cadastro', limite, async (req, res) => {
    const nome = limpo(req.body?.nome);
    const email = String(req.body?.email ?? '').trim().toLowerCase();
    const senha = String(req.body?.senha ?? '');
    if (nome.length < 2 || nome.length > 80) throw ruim('Informe seu nome completo.');
    if (!EMAIL.test(email) || email.length > 120) throw ruim('Informe um e-mail válido.');
    if (senha.length < SENHA_MIN) {
      throw ruim(`A senha deve ter pelo menos ${SENHA_MIN} caracteres.`);
    }
    if (senha.length > SENHA_MAX) throw ruim(`A senha pode ter no máximo ${SENHA_MAX} caracteres.`);

    const doc = {
      nome,
      email,
      senhaHash: await bcrypt.hash(senha, config.bcryptCusto),
      criadoEm: new Date(),
    };
    try {
      const { insertedId } = await db.usuarios.insertOne(doc);
      res.status(201).json(resposta({ ...doc, _id: insertedId }));
    } catch (e) {
      if (e?.code === 11000) throw conflito('Este e-mail já está cadastrado.');
      throw e;
    }
  });

  // Hash falso para gastar o mesmo tempo quando o e-mail não existe.
  const hashFalso = bcrypt.hashSync('nao-existe', config.bcryptCusto);

  r.post('/auth/login', limite, async (req, res) => {
    const email = String(req.body?.email ?? '').trim().toLowerCase();
    const senha = String(req.body?.senha ?? '');
    if (!email || !senha) throw ruim('Preencha e-mail e senha.');
    if (!EMAIL.test(email)) throw ruim('Informe um e-mail válido.');
    const u = await db.usuarios.findOne({ email });
    const ok = await bcrypt.compare(senha, u ? u.senhaHash : hashFalso);
    if (!u || !ok) throw naoAutorizado('E-mail ou senha incorretos.');
    res.json(resposta(u));
  });

  r.get('/auth/eu', login, (req, res) => {
    res.json({
      usuario: { nome: req.usuario.nome, email: req.usuario.email },
      ia: Boolean(config.geminiKey),
    });
  });

  // O e-mail identifica a conta e não muda por aqui (igual ao app).
  r.patch('/auth/eu', login, async (req, res) => {
    const nome = limpo(req.body?.nome);
    if (nome.length < 2 || nome.length > 80) {
      throw ruim('O nome deve ter pelo menos 2 caracteres.');
    }
    await db.usuarios.updateOne({ _id: req.usuario._id }, { $set: { nome } });
    res.json({ usuario: { nome, email: req.usuario.email } });
  });

  r.post('/auth/senha', login, async (req, res) => {
    const atual = String(req.body?.atual ?? '');
    const nova = String(req.body?.nova ?? '');
    if (!(await bcrypt.compare(atual, req.usuario.senhaHash))) {
      throw ruim('A senha atual está incorreta.');
    }
    if (nova.length < SENHA_MIN) {
      throw ruim(`A nova senha deve ter pelo menos ${SENHA_MIN} caracteres.`);
    }
    if (nova.length > SENHA_MAX) throw ruim(`A senha pode ter no máximo ${SENHA_MAX} caracteres.`);
    const senhaHash = await bcrypt.hash(nova, config.bcryptCusto);
    await db.usuarios.updateOne({ _id: req.usuario._id }, { $set: { senhaHash } });
    res.status(204).end();
  });

  // Exclusão de conta: apaga a pessoa e tudo o que ela escreveu.
  r.delete('/meus-dados', login, async (req, res) => {
    const id = req.usuario._id;
    const minhas = await db.comunidades.find({ criadorId: id }, { projection: { _id: 1 } }).toArray();
    const ids = minhas.map((c) => c._id);
    if (ids.length) await db.posts.deleteMany({ comunidadeId: { $in: ids } });
    await db.comunidades.deleteMany({ criadorId: id });
    await db.posts.deleteMany({ autorId: id });
    await db.artigos.deleteMany({ autorId: id });
    await db.usuarios.deleteOne({ _id: id });
    res.status(204).end();
  });

  return r;
}
