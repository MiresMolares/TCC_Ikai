import { Router } from 'express';
import { ObjectId } from 'mongodb';
import { exigirLogin, primeiroNome } from '../auth.js';
import {
  CATEGORIAS, COMUNIDADES_FIXAS, ICONES, LIMITES as L, OBJETIVOS,
} from '../catalogo.js';
import {
  conflito, naoEncontrado, proibido, ruim, ErroHttp,
} from '../erros.js';
import { dia, limpo, normalizar, removerEmojis } from '../texto.js';

const FORMATO_ID = /^[a-z][a-z0-9]{8,40}$/;

const novoId = (prefixo) => prefixo + new ObjectId().toHexString();

/** Aceita o id gerado pelo app (se for bem formado); senão cria um. */
function escolherId(bruto, prefixo) {
  const s = typeof bruto === 'string' ? bruto : '';
  return FORMATO_ID.test(s) && s.startsWith(prefixo) ? s : novoId(prefixo);
}

async function limitarFrequencia(colecao, filtro, max, janelaMs, mensagem) {
  const desde = new Date(Date.now() - janelaMs);
  const n = await colecao.countDocuments({ ...filtro, criadoEm: { $gt: desde } });
  if (n >= max) throw new ErroHttp(429, mensagem);
}

function listaDeTexto(valor, nomeDoCampo) {
  if (!Array.isArray(valor)) throw ruim(`Campo inválido: ${nomeDoCampo}.`);
  return valor.map((x) => {
    if (typeof x !== 'string') throw ruim(`Campo inválido: ${nomeDoCampo}.`);
    return x;
  });
}

function criarId(duplicado) {
  return (e) => {
    if (e?.code === 11000) throw conflito(duplicado);
    throw e;
  };
}

export function rotasConteudo({ db, config }) {
  const r = Router();
  const login = exigirLogin({ db, config });

  // O e-mail só volta para quem é o autor (o app usa para saber "é meu?").
  const eMeu = (req, id) => id.equals(req.usuario._id);

  const artigoSaida = (req, a) => ({
    id: a._id,
    objetivo: a.objetivo,
    categoria: a.categoria,
    titulo: a.titulo,
    autor: a.autorNome,
    resumo: a.resumo,
    nivel: a.nivel,
    tags: a.tags,
    paragrafos: a.paragrafos,
    usuario: true,
    email: eMeu(req, a.autorId) ? req.usuario.email : '',
    em: dia(a.criadoEm),
  });

  const comunidadeSaida = (req, c) => ({
    id: c._id,
    nome: c.nome,
    descricao: c.descricao,
    icone: c.icone,
    categorias: c.categorias,
    regras: c.regras,
    usuario: true,
    por: eMeu(req, c.criadorId) ? req.usuario.email : '',
    em: dia(c.criadoEm),
  });

  const postSaida = (req, p) => ({
    id: p._id,
    comunidade: p.comunidadeId,
    nome: p.autorNome,
    email: eMeu(req, p.autorId) ? req.usuario.email : '',
    texto: p.texto,
    ms: p.criadoEm.getTime(),
  });

  // ---------------- Artigos ----------------

  r.get('/artigos', login, async (req, res) => {
    const lista = await db.artigos.find().sort({ criadoEm: -1 }).limit(500).toArray();
    res.json(lista.map((a) => artigoSaida(req, a)));
  });

  r.post('/artigos', login, async (req, res) => {
    const b = req.body ?? {};
    const objetivo = String(b.objetivo ?? '');
    const categoria = String(b.categoria ?? '');
    if (!OBJETIVOS[objetivo]?.includes(categoria)) {
      throw ruim('Escolha o objetivo e a categoria.');
    }
    const nivel = b.nivel;
    if (!Number.isInteger(nivel) || nivel < 1 || nivel > 3) {
      throw ruim('Escolha o nível de dificuldade.');
    }
    const titulo = limpo(b.titulo);
    if (titulo.length < L.tituloMin || titulo.length > L.tituloMax) {
      throw ruim(`O título precisa ter de ${L.tituloMin} a ${L.tituloMax} caracteres.`);
    }
    const resumo = limpo(b.resumo);
    if (resumo.length < L.resumoMin || resumo.length > L.resumoMax) {
      throw ruim(`O resumo precisa ter de ${L.resumoMin} a ${L.resumoMax} caracteres.`);
    }
    const paragrafos = listaDeTexto(b.paragrafos, 'paragrafos')
      .map((p) => removerEmojis(p).replace(/\s+/g, ' ').trim())
      .filter(Boolean);
    const total = paragrafos.reduce((n, p) => n + p.length, 0);
    if (total < L.corpoMin) {
      throw ruim(`O texto está curto: escreva pelo menos ${L.corpoMin} caracteres.`);
    }
    if (total > L.corpoMax || paragrafos.some((p) => p.length > L.paragrafoMax)) {
      throw ruim(
        `O texto está longo demais. Separe em parágrafos de até ${L.paragrafoMax} ` +
          `caracteres, no máximo ${L.corpoMax} no total.`,
      );
    }
    const vistos = new Set();
    const tags = [];
    for (const t of listaDeTexto(b.tags ?? [], 'tags')) {
      const x = limpo(t).toLowerCase();
      if (x && !vistos.has(x)) { vistos.add(x); tags.push(x); }
    }
    if (tags.some((x) => x.length < L.tagMin || x.length > L.tagMax)) {
      throw ruim(`Cada assunto precisa ter de ${L.tagMin} a ${L.tagMax} caracteres.`);
    }
    if (tags.length > L.maxTags) throw ruim(`Use no máximo ${L.maxTags} assuntos.`);

    await limitarFrequencia(
      db.artigos, { autorId: req.usuario._id }, L.artigosPorDia, 24 * 3600e3,
      'Você publicou artigos demais hoje. Tente amanhã.',
    );

    const doc = {
      _id: escolherId(b.id, 'u'),
      autorId: req.usuario._id,
      autorNome: primeiroNome(req.usuario.nome),
      objetivo, categoria, nivel, titulo, resumo, tags, paragrafos,
      criadoEm: new Date(),
    };
    await db.artigos.insertOne(doc).catch(criarId('Este artigo já existe.'));
    res.status(201).json(artigoSaida(req, doc));
  });

  r.delete('/artigos/:id', login, async (req, res) => {
    const a = await db.artigos.findOne({ _id: req.params.id });
    if (!a) throw naoEncontrado('Artigo não encontrado.');
    if (!eMeu(req, a.autorId)) throw proibido('Só quem escreveu pode apagar.');
    await db.artigos.deleteOne({ _id: a._id });
    res.status(204).end();
  });

  // ---------------- Comunidades ----------------

  // Só as criadas por usuários: as fixas moram no app.
  r.get('/comunidades', login, async (req, res) => {
    const lista = await db.comunidades.find().sort({ criadoEm: 1 }).limit(500).toArray();
    res.json(lista.map((c) => comunidadeSaida(req, c)));
  });

  r.post('/comunidades', login, async (req, res) => {
    const b = req.body ?? {};
    const nome = limpo(b.nome);
    if (nome.length < L.nomeMin || nome.length > L.nomeMax) {
      throw ruim(`O nome precisa ter de ${L.nomeMin} a ${L.nomeMax} caracteres.`);
    }
    const descricao = limpo(b.descricao);
    if (descricao.length < L.descricaoMin || descricao.length > L.descricaoMax) {
      throw ruim(`A descrição precisa ter de ${L.descricaoMin} a ${L.descricaoMax} caracteres.`);
    }
    const icone = String(b.icone ?? '');
    if (!ICONES.has(icone)) throw ruim('Escolha um ícone da lista.');
    const categorias = [...new Set(listaDeTexto(b.categorias, 'categorias'))];
    if (categorias.length < 1 || categorias.length > L.maxCategoriasComunidade) {
      throw ruim(`Escolha de 1 a ${L.maxCategoriasComunidade} categorias.`);
    }
    if (!categorias.every((c) => CATEGORIAS.has(c))) throw ruim('Há uma categoria inválida.');
    const regras = listaDeTexto(b.regras ?? [], 'regras').map(limpo).filter(Boolean);
    if (regras.length > L.maxRegras || regras.some((x) => x.length > L.regraMax)) {
      throw ruim(`Use no máximo ${L.maxRegras} regras, de até ${L.regraMax} caracteres.`);
    }

    const nomeChave = normalizar(nome);
    const nomesFixos = ['historia em pauta', 'clube de leitores', 'curiosos da ciencia', 'filosofia e sociedade'];
    if (nomesFixos.includes(nomeChave)) throw conflito('Já existe uma comunidade com esse nome.');

    await limitarFrequencia(
      db.comunidades, { criadorId: req.usuario._id }, L.comunidadesPorDia, 24 * 3600e3,
      'Você criou comunidades demais hoje. Tente amanhã.',
    );

    const doc = {
      _id: escolherId(b.id, 'c'),
      criadorId: req.usuario._id,
      nome, nomeChave, descricao, icone, categorias, regras,
      criadoEm: new Date(),
    };
    await db.comunidades.insertOne(doc).catch(
      criarId('Já existe uma comunidade com esse nome.'),
    );
    res.status(201).json(comunidadeSaida(req, doc));
  });

  r.delete('/comunidades/:id', login, async (req, res) => {
    const c = await db.comunidades.findOne({ _id: req.params.id });
    if (!c) throw naoEncontrado('Comunidade não encontrada.');
    if (!eMeu(req, c.criadorId)) throw proibido('Só quem criou pode apagar.');
    await db.posts.deleteMany({ comunidadeId: c._id });
    await db.comunidades.deleteOne({ _id: c._id });
    res.status(204).end();
  });

  // ---------------- Mensagens (posts) ----------------

  async function comunidadeDoPost(id) {
    if (COMUNIDADES_FIXAS.has(id)) return { fixa: true };
    const c = await db.comunidades.findOne({ _id: id });
    if (!c) throw naoEncontrado('Comunidade não encontrada.');
    return c;
  }

  r.get('/comunidades/:id/posts', login, async (req, res) => {
    await comunidadeDoPost(req.params.id);
    const lista = await db.posts
      .find({ comunidadeId: req.params.id })
      .sort({ criadoEm: -1 })
      .limit(200)
      .toArray();
    res.json(lista.map((p) => postSaida(req, p)));
  });

  r.post('/comunidades/:id/posts', login, async (req, res) => {
    await comunidadeDoPost(req.params.id);
    const texto = removerEmojis(req.body?.texto).replace(/[ \t]+/g, ' ').trim();
    if (texto.length < L.postMin || texto.length > L.postMax) {
      throw ruim(`A mensagem precisa ter de ${L.postMin} a ${L.postMax} caracteres.`);
    }
    await limitarFrequencia(
      db.posts, { autorId: req.usuario._id }, L.postsPorHora, 3600e3,
      'Você enviou mensagens demais. Respire e tente daqui a pouco.',
    );
    const doc = {
      _id: escolherId(req.body?.id, 'p'),
      comunidadeId: req.params.id,
      autorId: req.usuario._id,
      autorNome: primeiroNome(req.usuario.nome),
      texto,
      criadoEm: new Date(),
    };
    await db.posts.insertOne(doc).catch(criarId('Esta mensagem já existe.'));
    res.status(201).json(postSaida(req, doc));
  });

  r.delete('/comunidades/:id/posts/:postId', login, async (req, res) => {
    const com = await comunidadeDoPost(req.params.id);
    const p = await db.posts.findOne({ _id: req.params.postId, comunidadeId: req.params.id });
    if (!p) throw naoEncontrado('Mensagem não encontrada.');
    const dono = !com.fixa && eMeu(req, com.criadorId);
    if (!eMeu(req, p.autorId) && !dono) throw proibido();
    await db.posts.deleteOne({ _id: p._id });
    res.status(204).end();
  });

  return r;
}
