// Testes da API contra um MongoDB de verdade.
// Rode:  MONGODB_URI=mongodb://127.0.0.1:27017 npm test
// (cada execução usa um banco novo, que é apagado no fim)
import { test, before, after, describe } from 'node:test';
import assert from 'node:assert/strict';
import { criarApp } from '../src/app.js';
import { lerConfig } from '../src/config.js';
import { conectar } from '../src/db.js';

let db, servidor, base;
const chamadasGemini = [];
let respostaGemini = { status: 200, corpo: { candidates: [{ content: { parts: [{ text: '{"resposta":"oi","ideias":[]}' }] } }] } };

const fetchFalso = async (url, init) => {
  chamadasGemini.push({ url, init });
  return {
    ok: respostaGemini.status < 300,
    status: respostaGemini.status,
    text: async () => JSON.stringify(respostaGemini.corpo),
  };
};

async function chamar(metodo, caminho, corpo, token) {
  const r = await fetch(base + caminho, {
    method: metodo,
    headers: {
      'content-type': 'application/json',
      ...(token ? { authorization: `Bearer ${token}` } : {}),
    },
    body: corpo === undefined ? undefined : JSON.stringify(corpo),
  });
  const texto = await r.text();
  let json = null;
  try { json = texto ? JSON.parse(texto) : null; } catch { /* sem corpo */ }
  return { status: r.status, json };
}

async function novaConta(nome, email, senha = 'senha-forte-1') {
  const r = await chamar('POST', '/auth/cadastro', { nome, email, senha });
  assert.equal(r.status, 201, JSON.stringify(r.json));
  return r.json.token;
}

const artigoValido = (extra = {}) => ({
  objetivo: 'ler',
  categoria: 'ler_romance',
  nivel: 2,
  titulo: 'Capitães da Areia em poucas linhas',
  resumo: 'Um resumo curto sobre o romance de Jorge Amado.',
  tags: ['romance', 'brasil'],
  paragrafos: [
    'O livro acompanha um grupo de meninos que vive nas ruas de Salvador, nos anos trinta.',
    'Jorge Amado mostra a cidade pelos olhos de quem não tem lugar nela, sem pieguice.',
  ],
  ...extra,
});

const comunidadeValida = (extra = {}) => ({
  nome: 'Leitores de sábado',
  descricao: 'Encontro tranquilo para falar de livros.',
  icone: 'livro',
  categorias: ['ler_romance'],
  regras: ['Respeite as pessoas; debata ideias.'],
  ...extra,
});

before(async () => {
  const config = {
    ...lerConfig({}),
    mongoUri: process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017',
    mongoDb: `ikai_teste_${Date.now()}`,
    jwtSecret: 'segredo-de-teste-bem-longo',
    geminiKey: 'chave-falsa',
    bcryptCusto: 4,
    limitarLogin: false,
  };
  db = await conectar(config);
  const app = criarApp({ db, config, fetchImpl: fetchFalso });
  await new Promise((ok) => { servidor = app.listen(0, '127.0.0.1', ok); });
  base = `http://127.0.0.1:${servidor.address().port}`;
});

after(async () => {
  await new Promise((ok) => servidor.close(ok));
  await db.base.dropDatabase();
  await db.cliente.close();
});

describe('saúde e erros gerais', () => {
  test('GET /saude diz se a IA está ligada', async () => {
    const r = await chamar('GET', '/saude');
    assert.deepEqual(r.json, { ok: true, ia: true });
  });
  test('rota desconhecida dá 404 em JSON', async () => {
    const r = await chamar('GET', '/nada');
    assert.equal(r.status, 404);
    assert.ok(r.json.erro);
  });
  test('sem token, conteúdo é negado', async () => {
    assert.equal((await chamar('GET', '/artigos')).status, 401);
    assert.equal((await chamar('POST', '/ia/gemini', {})).status, 401);
  });
  test('token inválido é negado', async () => {
    assert.equal((await chamar('GET', '/artigos', undefined, 'lixo')).status, 401);
  });
});

describe('login', () => {
  test('cadastro cria conta, guarda hash e nunca devolve a senha', async () => {
    const r = await chamar('POST', '/auth/cadastro', {
      nome: 'Ana Souza', email: ' ANA@Teste.com ', senha: 'senha-forte-1',
    });
    assert.equal(r.status, 201);
    assert.equal(r.json.usuario.email, 'ana@teste.com');
    assert.equal(r.json.ia, true);
    assert.ok(r.json.token);
    assert.equal(JSON.stringify(r.json).includes('senha-forte-1'), false);
    const doc = await db.usuarios.findOne({ email: 'ana@teste.com' });
    assert.notEqual(doc.senhaHash, 'senha-forte-1');
    assert.ok(doc.senhaHash.startsWith('$2'));
  });

  test('valida nome, e-mail e senha', async () => {
    const base = { nome: 'Bia Lima', email: 'bia@teste.com', senha: 'senha-forte-1' };
    for (const ruim of [
      { nome: 'A' }, { email: 'sem-arroba' }, { senha: '1234567' },
      { senha: 'x'.repeat(73) },
    ]) {
      const r = await chamar('POST', '/auth/cadastro', { ...base, ...ruim });
      assert.equal(r.status, 400, JSON.stringify(ruim));
    }
  });

  test('e-mail repetido (qualquer caixa) dá 409', async () => {
    await novaConta('Caio Dois', 'dup@teste.com');
    const r = await chamar('POST', '/auth/cadastro', {
      nome: 'Outro', email: 'DUP@teste.com', senha: 'senha-forte-1',
    });
    assert.equal(r.status, 409);
  });

  test('login certo e errado', async () => {
    await novaConta('Dani Cruz', 'dani@teste.com');
    const ok = await chamar('POST', '/auth/login', { email: 'DANI@teste.com', senha: 'senha-forte-1' });
    assert.equal(ok.status, 200);
    assert.equal(ok.json.usuario.nome, 'Dani Cruz');
    const errada = await chamar('POST', '/auth/login', { email: 'dani@teste.com', senha: 'errada-errada' });
    assert.equal(errada.status, 401);
    const inexistente = await chamar('POST', '/auth/login', { email: 'nao@teste.com', senha: 'senha-forte-1' });
    assert.equal(inexistente.status, 401);
    assert.equal(inexistente.json.erro, errada.json.erro); // não revela se o e-mail existe
    assert.equal((await chamar('POST', '/auth/login', { email: '', senha: '' })).status, 400);
  });

  test('eu, trocar nome, trocar senha', async () => {
    const t = await novaConta('Eva Lima', 'eva@teste.com');
    assert.equal((await chamar('GET', '/auth/eu', undefined, t)).json.usuario.email, 'eva@teste.com');
    const p = await chamar('PATCH', '/auth/eu', { nome: 'Eva Souza', email: 'outro@x.com' }, t);
    assert.equal(p.json.usuario.nome, 'Eva Souza');
    assert.equal(p.json.usuario.email, 'eva@teste.com'); // e-mail não muda por aqui
    assert.equal((await chamar('PATCH', '/auth/eu', { nome: 'E' }, t)).status, 400);

    assert.equal((await chamar('POST', '/auth/senha', { atual: 'x', nova: 'nova-senha-1' }, t)).status, 400);
    assert.equal((await chamar('POST', '/auth/senha', { atual: 'senha-forte-1', nova: '123' }, t)).status, 400);
    assert.equal((await chamar('POST', '/auth/senha', { atual: 'senha-forte-1', nova: 'nova-senha-1' }, t)).status, 204);
    assert.equal((await chamar('POST', '/auth/login', { email: 'eva@teste.com', senha: 'senha-forte-1' })).status, 401);
    assert.equal((await chamar('POST', '/auth/login', { email: 'eva@teste.com', senha: 'nova-senha-1' })).status, 200);
  });
});

describe('artigos', () => {
  test('publica, lista e devolve o e-mail só para o autor', async () => {
    const a = await novaConta('Gus Lima', 'gus@teste.com');
    const b = await novaConta('Hana Dias', 'hana@teste.com');
    const novo = await chamar('POST', '/artigos', artigoValido(), a);
    assert.equal(novo.status, 201, JSON.stringify(novo.json));
    assert.equal(novo.json.autor, 'Gus'); // só o primeiro nome
    assert.equal(novo.json.email, 'gus@teste.com');
    assert.equal(novo.json.usuario, true);
    assert.match(novo.json.em, /^\d{4}-\d{2}-\d{2}$/);

    const paraB = (await chamar('GET', '/artigos', undefined, b)).json;
    const visto = paraB.find((x) => x.id === novo.json.id);
    assert.ok(visto);
    assert.equal(visto.email, ''); // outro usuário nunca vê o e-mail
    const paraA = (await chamar('GET', '/artigos', undefined, a)).json;
    assert.equal(paraA.find((x) => x.id === novo.json.id).email, 'gus@teste.com');
  });

  test('aceita o id do app, rejeita id repetido e ignora id malformado', async () => {
    const t = await novaConta('Ivo Dias', 'ivo@teste.com');
    const ok = await chamar('POST', '/artigos', artigoValido({ id: 'u17000000000000' }), t);
    assert.equal(ok.json.id, 'u17000000000000');
    const dup = await chamar('POST', '/artigos', artigoValido({ id: 'u17000000000000' }), t);
    assert.equal(dup.status, 409);
    const ruim = await chamar('POST', '/artigos', artigoValido({ id: 'a001' }), t);
    assert.notEqual(ruim.json.id, 'a001');
    assert.ok(ruim.json.id.startsWith('u'));
  });

  test('valida categoria, nível, tamanhos, tags e remove emojis', async () => {
    const t = await novaConta('Jade Lima', 'jade@teste.com');
    const falha = async (extra, status = 400) =>
      assert.equal((await chamar('POST', '/artigos', artigoValido(extra), t)).status, status, JSON.stringify(extra).slice(0, 80));
    await falha({ categoria: 'ler_inexistente' });
    await falha({ objetivo: 'estudar' }); // categoria de outro objetivo
    await falha({ nivel: 0 });
    await falha({ nivel: 4 });
    await falha({ nivel: '2' });
    await falha({ titulo: 'Oi' });
    await falha({ resumo: 'curto' });
    await falha({ paragrafos: ['curto demais'] });
    await falha({ paragrafos: ['x'.repeat(2001)] });
    await falha({ paragrafos: 'não é lista' });
    await falha({ tags: ['a'] });
    await falha({ tags: ['um', 'dois', 'tres', 'quatro', 'cinco', 'seis'] });
    await falha({ tags: [1] });

    const r = await chamar('POST', '/artigos', artigoValido({
      titulo: 'Título com emoji \u{1F600} aqui', tags: ['Romance', 'romance', ' Brasil '],
    }), t);
    assert.equal(r.status, 201);
    assert.equal(r.json.titulo, 'Título com emoji aqui');
    assert.deepEqual(r.json.tags, ['romance', 'brasil']);
  });

  test('só o autor apaga', async () => {
    const a = await novaConta('Kai Dias', 'kai@teste.com');
    const b = await novaConta('Lia Dias', 'lia@teste.com');
    const { json } = await chamar('POST', '/artigos', artigoValido(), a);
    assert.equal((await chamar('DELETE', `/artigos/${json.id}`, undefined, b)).status, 403);
    assert.equal((await chamar('DELETE', `/artigos/${json.id}`, undefined, a)).status, 204);
    assert.equal((await chamar('DELETE', `/artigos/${json.id}`, undefined, a)).status, 404);
  });

  test('limite de artigos por dia', async () => {
    const t = await novaConta('Mel Dias', 'mel@teste.com');
    for (let i = 0; i < 10; i++) {
      assert.equal((await chamar('POST', '/artigos', artigoValido(), t)).status, 201);
    }
    assert.equal((await chamar('POST', '/artigos', artigoValido(), t)).status, 429);
  });
});

describe('comunidades e mensagens', () => {
  test('cria, lista e não deixa nome repetido (sem acento/caixa) nem usar nome de fixa', async () => {
    const a = await novaConta('Noa Dias', 'noa@teste.com');
    const r = await chamar('POST', '/comunidades', comunidadeValida({ nome: 'Poesia à tarde' }), a);
    assert.equal(r.status, 201, JSON.stringify(r.json));
    assert.equal(r.json.por, 'noa@teste.com');
    assert.equal(r.json.usuario, true);
    const dup = await chamar('POST', '/comunidades', comunidadeValida({ nome: 'POESIA A TARDE' }), a);
    assert.equal(dup.status, 409);
    const fixa = await chamar('POST', '/comunidades', comunidadeValida({ nome: 'Clube de Leitores' }), a);
    assert.equal(fixa.status, 409);
    const lista = (await chamar('GET', '/comunidades', undefined, a)).json;
    assert.ok(lista.some((c) => c.id === r.json.id));
  });

  test('valida os campos', async () => {
    const t = await novaConta('Ota Dias', 'ota@teste.com');
    const falha = async (extra) =>
      assert.equal((await chamar('POST', '/comunidades', comunidadeValida({ nome: `Nome ${Math.random()}`.slice(0, 20), ...extra }), t)).status, 400, JSON.stringify(extra));
    await falha({ nome: 'ab' });
    await falha({ nome: 'x'.repeat(41) });
    await falha({ descricao: 'curta' });
    await falha({ icone: 'inexistente' });
    await falha({ categorias: [] });
    await falha({ categorias: ['nao_existe'] });
    await falha({ categorias: ['ler_romance', 'ler_fc', 'ler_dp', 'ler_horror', 'ler_terror', 'ler_aventura'] });
    await falha({ regras: ['x'.repeat(121)] });
    await falha({ regras: ['1', '2', '3', '4', '5', '6', '7'] });
  });

  test('mensagens: criar, listar (mais novas primeiro), e-mail só para o autor', async () => {
    const a = await novaConta('Pia Dias', 'pia@teste.com');
    const b = await novaConta('Rui Dias', 'rui@teste.com');
    const c = (await chamar('POST', '/comunidades', comunidadeValida({ nome: 'Mensagens boas' }), a)).json;
    const p1 = await chamar('POST', `/comunidades/${c.id}/posts`, { texto: 'Primeira mensagem' }, a);
    assert.equal(p1.status, 201, JSON.stringify(p1.json));
    await new Promise((ok) => setTimeout(ok, 5));
    await chamar('POST', `/comunidades/${c.id}/posts`, { texto: 'Segunda mensagem \u{1F600}' }, b);
    const lista = (await chamar('GET', `/comunidades/${c.id}/posts`, undefined, b)).json;
    assert.deepEqual(lista.map((p) => p.texto), ['Segunda mensagem', 'Primeira mensagem']);
    assert.equal(lista[0].email, 'rui@teste.com');
    assert.equal(lista[1].email, ''); // da Pia: o Rui não vê
    assert.equal(lista[1].nome, 'Pia');
    assert.equal(typeof lista[0].ms, 'number');
  });

  test('comunidades fixas aceitam mensagens; id inexistente dá 404', async () => {
    const t = await novaConta('Sol Dias', 'sol@teste.com');
    assert.equal((await chamar('POST', '/comunidades/historia/posts', { texto: 'Olá, pessoal' }, t)).status, 201);
    assert.equal((await chamar('GET', '/comunidades/historia/posts', undefined, t)).json.length >= 1, true);
    assert.equal((await chamar('POST', '/comunidades/nada/posts', { texto: 'Olá, pessoal' }, t)).status, 404);
  });

  test('valida o texto e limita a frequência', async () => {
    const t = await novaConta('Tom Dias', 'tom@teste.com');
    assert.equal((await chamar('POST', '/comunidades/ideias/posts', { texto: 'ab' }, t)).status, 400);
    assert.equal((await chamar('POST', '/comunidades/ideias/posts', { texto: 'x'.repeat(501) }, t)).status, 400);
    for (let i = 0; i < 20; i++) {
      assert.equal((await chamar('POST', '/comunidades/ideias/posts', { texto: `mensagem ${i}` }, t)).status, 201);
    }
    assert.equal((await chamar('POST', '/comunidades/ideias/posts', { texto: 'mais uma' }, t)).status, 429);
  });

  test('apagar: autor da mensagem ou criador da comunidade; fixa só o autor', async () => {
    const dono = await novaConta('Uma Dias', 'uma@teste.com');
    const outro = await novaConta('Vic Dias', 'vic@teste.com');
    const terceiro = await novaConta('Wal Dias', 'wal@teste.com');
    const c = (await chamar('POST', '/comunidades', comunidadeValida({ nome: 'Regras de apagar' }), dono)).json;
    const p = (await chamar('POST', `/comunidades/${c.id}/posts`, { texto: 'mensagem do outro' }, outro)).json;
    assert.equal((await chamar('DELETE', `/comunidades/${c.id}/posts/${p.id}`, undefined, terceiro)).status, 403);
    assert.equal((await chamar('DELETE', `/comunidades/${c.id}/posts/${p.id}`, undefined, dono)).status, 204);
    const q = (await chamar('POST', `/comunidades/${c.id}/posts`, { texto: 'outra mensagem' }, outro)).json;
    assert.equal((await chamar('DELETE', `/comunidades/${c.id}/posts/${q.id}`, undefined, outro)).status, 204);

    const f = (await chamar('POST', '/comunidades/ciencia/posts', { texto: 'mensagem fixa' }, outro)).json;
    assert.equal((await chamar('DELETE', `/comunidades/ciencia/posts/${f.id}`, undefined, dono)).status, 403);
    assert.equal((await chamar('DELETE', `/comunidades/ciencia/posts/${f.id}`, undefined, outro)).status, 204);
  });

  test('apagar comunidade: só o criador, e as mensagens vão junto', async () => {
    const dono = await novaConta('Xis Dias', 'xis@teste.com');
    const outro = await novaConta('Yan Dias', 'yan@teste.com');
    const c = (await chamar('POST', '/comunidades', comunidadeValida({ nome: 'Para apagar' }), dono)).json;
    await chamar('POST', `/comunidades/${c.id}/posts`, { texto: 'vai embora junto' }, outro);
    assert.equal((await chamar('DELETE', `/comunidades/${c.id}`, undefined, outro)).status, 403);
    assert.equal((await chamar('DELETE', `/comunidades/${c.id}`, undefined, dono)).status, 204);
    assert.equal(await db.posts.countDocuments({ comunidadeId: c.id }), 0);
    assert.equal((await chamar('GET', `/comunidades/${c.id}/posts`, undefined, dono)).status, 404);
  });
});

describe('exclusão de conta', () => {
  test('apaga a conta e tudo o que ela escreveu, inclusive mensagens nas comunidades dela', async () => {
    const zed = await novaConta('Zed Dias', 'zed@teste.com');
    const amigo = await novaConta('Amigo Dias', 'amigo@teste.com');
    const art = (await chamar('POST', '/artigos', artigoValido(), zed)).json;
    const com = (await chamar('POST', '/comunidades', comunidadeValida({ nome: 'Do Zed' }), zed)).json;
    await chamar('POST', `/comunidades/${com.id}/posts`, { texto: 'mensagem do amigo' }, amigo);
    await chamar('POST', '/comunidades/historia/posts', { texto: 'mensagem do Zed' }, zed);

    assert.equal((await chamar('DELETE', '/meus-dados', undefined, zed)).status, 204);
    assert.equal(await db.usuarios.countDocuments({ email: 'zed@teste.com' }), 0);
    assert.equal(await db.artigos.countDocuments({ _id: art.id }), 0);
    assert.equal(await db.comunidades.countDocuments({ _id: com.id }), 0);
    assert.equal(await db.posts.countDocuments({ comunidadeId: com.id }), 0);
    assert.equal(await db.posts.countDocuments({ autorNome: 'Zed' }), 0);
    // o token antigo deixa de valer
    assert.equal((await chamar('GET', '/auth/eu', undefined, zed)).status, 401);
    // o amigo continua existindo
    assert.equal((await chamar('GET', '/auth/eu', undefined, amigo)).status, 200);
  });
});

describe('proxy do Gemini', () => {
  const corpo = (extra = {}) => ({
    system_instruction: { parts: [{ text: 'Você é a Ik AI.' }] },
    contents: [{ role: 'user', parts: [{ text: '<declarado>oi</declarado>' }] }],
    generationConfig: { temperature: 0.8, maxOutputTokens: 2048, responseMimeType: 'application/json' },
    ...extra,
  });

  test('encaminha com a chave do servidor e devolve a resposta do Gemini', async () => {
    const t = await novaConta('Ia Dias', 'ia@teste.com');
    chamadasGemini.length = 0;
    const r = await chamar('POST', '/ia/gemini', corpo(), t);
    assert.equal(r.status, 200);
    assert.equal(r.json.candidates[0].content.parts[0].text, '{"resposta":"oi","ideias":[]}');
    assert.equal(chamadasGemini.length, 1);
    const { url, init } = chamadasGemini[0];
    assert.ok(url.includes('/models/gemini-3.8-flash:generateContent'));
    assert.equal(init.headers['x-goog-api-key'], 'chave-falsa');
    const enviado = JSON.parse(init.body);
    assert.equal(enviado.generationConfig.responseMimeType, 'application/json');
  });

  test('descarta campos fora do formato e limita os números', async () => {
    const t = await novaConta('Ib Dias', 'ib@teste.com');
    chamadasGemini.length = 0;
    await chamar('POST', '/ia/gemini', corpo({
      tools: [{ googleSearch: {} }],
      safetySettings: [],
      generationConfig: { temperature: 99, maxOutputTokens: 999999, responseMimeType: 'text/plain', candidateCount: 8 },
    }), t);
    const enviado = JSON.parse(chamadasGemini[0].init.body);
    assert.deepEqual(Object.keys(enviado).sort(), ['contents', 'generationConfig', 'system_instruction']);
    assert.equal(enviado.generationConfig.temperature, 1.5);
    assert.equal(enviado.generationConfig.maxOutputTokens, 8192);
    assert.equal(enviado.generationConfig.responseMimeType, 'application/json');
    assert.equal(enviado.generationConfig.candidateCount, undefined);
  });

  test('rejeita conversa vazia, grande demais ou mal formada', async () => {
    const t = await novaConta('Ic Dias', 'ic@teste.com');
    for (const ruim of [
      {}, { contents: [] }, { contents: 'x' },
      { contents: [{ role: 'user', parts: [] }] },
      { contents: [{ role: 'user', parts: [{ text: 'x'.repeat(6001) }] }] },
      { contents: Array.from({ length: 15 }, () => ({ role: 'user', parts: [{ text: 'a' }] })) },
    ]) {
      assert.equal((await chamar('POST', '/ia/gemini', ruim, t)).status, 400);
    }
  });

  test('erro do Gemini vira 502 sem vazar detalhes, e a chave nunca aparece', async () => {
    const t = await novaConta('Id Dias', 'id@teste.com');
    respostaGemini = { status: 404, corpo: { error: { message: 'models/xyz is not found' } } };
    const r = await chamar('POST', '/ia/gemini', corpo(), t);
    assert.equal(r.status, 502);
    assert.equal(JSON.stringify(r.json).includes('chave-falsa'), false);
    assert.equal(JSON.stringify(r.json).includes('xyz'), false);
    respostaGemini = { status: 200, corpo: { candidates: [{ content: { parts: [{ text: '{"resposta":"oi","ideias":[]}' }] } }] } };
  });

  test('limite por hora', async () => {
    const t = await novaConta('Ie Dias', 'ie@teste.com');
    for (let i = 0; i < 60; i++) {
      assert.equal((await chamar('POST', '/ia/gemini', corpo(), t)).status, 200);
    }
    assert.equal((await chamar('POST', '/ia/gemini', corpo(), t)).status, 429);
  });
});

test('sem chave no servidor, a IA responde 503 e /saude avisa', async () => {
  const config = { ...lerConfig({}), jwtSecret: 'segredo-de-teste-bem-longo', geminiKey: '', bcryptCusto: 4, limitarLogin: false };
  const app = criarApp({ db, config, fetchImpl: fetchFalso });
  const srv = await new Promise((ok) => { const s = app.listen(0, '127.0.0.1', () => ok(s)); });
  try {
    const url = `http://127.0.0.1:${srv.address().port}`;
    assert.deepEqual(await (await fetch(`${url}/saude`)).json(), { ok: true, ia: false });
    const cad = await (await fetch(`${url}/auth/cadastro`, {
      method: 'POST', headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ nome: 'Sem Chave', email: 'semchave@teste.com', senha: 'senha-forte-1' }),
    })).json();
    assert.equal(cad.ia, false);
    const r = await fetch(`${url}/ia/gemini`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${cad.token}` },
      body: JSON.stringify({ contents: [{ role: 'user', parts: [{ text: 'oi' }] }] }),
    });
    assert.equal(r.status, 503);
  } finally {
    await new Promise((ok) => srv.close(ok));
  }
});
