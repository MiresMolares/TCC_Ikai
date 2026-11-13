// Testes do banco de dados do app (MongoDB de verdade): catálogo, regras do
// banco, sessões, preferências, notificações e exclusão de conta.
// Rode:  MONGODB_URI=mongodb://127.0.0.1:27017 npm test
import { test, before, after, describe } from 'node:test';
import assert from 'node:assert/strict';
import { ObjectId } from 'mongodb';
import { criarApp } from '../src/app.js';
import { lerConfig } from '../src/config.js';
import { conectar, sincronizarCatalogo } from '../src/db.js';
import { OBJETIVOS, CATEGORIAS_INFO, OBJETIVOS_INFO } from '../src/catalogo.js';
import { existsSync, readFileSync } from 'node:fs';

let db, servidor, base;

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

let contador = 0;
async function novaConta(nome = 'Ana Souza') {
  contador += 1;
  const email = `pessoa${contador}@exemplo.com`;
  const r = await chamar('POST', '/auth/cadastro', { nome, email, senha: 'senha-forte-1' });
  assert.equal(r.status, 201, JSON.stringify(r.json));
  const u = await db.usuarios.findOne({ email });
  return { token: r.json.token, id: u._id };
}

const sessaoValida = (extra = {}) => ({
  objetivo: 'estudar',
  categorias: ['estudar_ingles', 'estudar_historia'],
  duracaoSegundos: 1800,
  ...extra,
});

// Erro 121 = "Document failed validation" (o banco recusou).
const recusadoPeloBanco = (e) => e?.code === 121;

before(async () => {
  const config = {
    ...lerConfig({}),
    mongoUri: process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017',
    mongoDb: `ikai_banco_${Date.now()}`,
    jwtSecret: 'segredo-de-teste-bem-longo',
    bcryptCusto: 4,
    limitarLogin: false,
  };
  db = await conectar(config);
  const app = criarApp({ db, config });
  await new Promise((ok) => { servidor = app.listen(0, '127.0.0.1', ok); });
  base = `http://127.0.0.1:${servidor.address().port}`;
});

after(async () => {
  await new Promise((ok) => servidor.close(ok));
  await db.base.dropDatabase();
  await db.cliente.close();
});

describe('estrutura do banco', () => {
  test('as 9 coleções existem, cada uma com validador de esquema', async () => {
    const lista = await db.base.listCollections().toArray();
    const nomes = lista.map((c) => c.name).sort();
    assert.deepEqual(nomes, [
      'artigos', 'categorias', 'comunidades', 'notificacoes', 'objetivos',
      'posts', 'preferencias', 'sessoes', 'usuarios',
    ]);
    for (const c of lista) {
      assert.ok(c.options?.validator?.$jsonSchema, `${c.name} sem validador`);
      assert.equal(c.options.validationAction, 'error');
    }
  });

  test('os índices importantes existem (e-mail único, uma sessão ativa, expiração)', async () => {
    const nomes = async (col) => (await db[col].indexes()).map((i) => i.name);
    const email = (await db.usuarios.indexes()).find((i) => i.name === 'email_1');
    assert.equal(email.unique, true);
    assert.ok((await nomes('sessoes')).includes('uma_sessao_ativa'));
    const ttl = (await db.notificacoes.indexes()).find((i) => i.name === 'expira_em_90_dias');
    assert.equal(ttl.expireAfterSeconds, 90 * 24 * 3600);
    const unica = (await db.sessoes.indexes()).find((i) => i.name === 'uma_sessao_ativa');
    assert.equal(unica.unique, true);
    assert.deepEqual(unica.partialFilterExpression, { estado: 'ativa' });
  });

  test('o catálogo é gravado (4 objetivos e 60 categorias) e sincronizar de novo não duplica', async () => {
    assert.equal(await db.objetivos.countDocuments(), 4);
    assert.equal(await db.categorias.countDocuments(), 60);
    await sincronizarCatalogo(db);
    assert.equal(await db.objetivos.countDocuments(), 4);
    assert.equal(await db.categorias.countDocuments(), 60);
    const c = await db.categorias.findOne({ _id: 'estudar_ingles' });
    assert.equal(c.objetivoId, 'estudar');
    assert.equal(c.titulo, 'Inglês');
  });

  test('o próprio banco recusa dados fora das regras', async () => {
    const { id } = await novaConta();
    const agora = new Date();
    const sessao = {
      usuarioId: id, objetivoId: 'ler', categoriaIds: ['ler_romance'],
      duracaoSegundos: 60, iniciadaEm: agora, expiraEm: agora, estado: 'expirada',
    };
    // um documento certo passa
    const { insertedId } = await db.sessoes.insertOne({ ...sessao });
    await db.sessoes.deleteOne({ _id: insertedId });

    const ruins = [
      ['sessões', db.sessoes, { ...sessao, duracaoSegundos: 0 }],
      ['sessões', db.sessoes, { ...sessao, duracaoSegundos: 10801 }],
      ['sessões', db.sessoes, { ...sessao, categoriaIds: [] }],
      ['sessões', db.sessoes, { ...sessao, categoriaIds: ['nao_existe'] }],
      ['sessões', db.sessoes, { ...sessao, estado: 'pausada' }],
      ['usuários', db.usuarios, { nome: 'A', email: 'a@b.co', senhaHash: 'x'.repeat(30), criadoEm: agora }],
      ['usuários', db.usuarios, { nome: 'Ana', email: 'sem-arroba', senhaHash: 'x'.repeat(30), criadoEm: agora }],
      ['notificações', db.notificacoes, { usuarioId: id, tipo: 'spam', titulo: 'x', descricao: '', criadaEm: agora, lida: false }],
      ['preferências', db.preferencias, { _id: new ObjectId(), tamanhoTexto: 2, atualizadoEm: agora }],
      ['preferências', db.preferencias, { _id: new ObjectId(), nivelConteudo: 4, atualizadoEm: agora }],
    ];
    for (const [nome, col, doc] of ruins) {
      await assert.rejects(col.insertOne(doc), recusadoPeloBanco, `${nome} deveria ser recusado`);
    }
  });
});

describe('catálogo (rotas)', () => {
  test('GET /objetivos exige login', async () => {
    assert.equal((await chamar('GET', '/objetivos')).status, 401);
  });

  test('GET /objetivos traz os 4 objetivos com as suas categorias, em ordem', async () => {
    const { token } = await novaConta();
    const r = await chamar('GET', '/objetivos', undefined, token);
    assert.equal(r.status, 200);
    assert.deepEqual(r.json.map((o) => o.id), ['ver_conteudo', 'ler', 'estudar', 'oficio']);
    assert.deepEqual(r.json.map((o) => o.categorias.length), [16, 16, 16, 12]);
    assert.equal(r.json[2].titulo, 'Estudar');
    assert.deepEqual(Object.keys(r.json[2].categorias[0]), ['id', 'objetivo', 'titulo', 'icone']);
    assert.equal(r.json[2].categorias[0].id, 'estudar_matematica');
  });

  test('GET /objetivos/:id/categorias e 404 para objetivo que não existe', async () => {
    const { token } = await novaConta();
    const ok = await chamar('GET', '/objetivos/ler/categorias', undefined, token);
    assert.equal(ok.status, 200);
    assert.equal(ok.json.length, 16);
    assert.ok(ok.json.every((c) => c.objetivo === 'ler'));
    const nao = await chamar('GET', '/objetivos/danca/categorias', undefined, token);
    assert.equal(nao.status, 404);
  });
});

describe('sessões', () => {
  test('exigem login', async () => {
    assert.equal((await chamar('POST', '/sessoes', sessaoValida())).status, 401);
    assert.equal((await chamar('GET', '/sessoes')).status, 401);
  });

  test('POST /sessoes cria a sessão e devolve o tempo restante', async () => {
    const { token, id } = await novaConta();
    const r = await chamar('POST', '/sessoes', sessaoValida(), token);
    assert.equal(r.status, 201, JSON.stringify(r.json));
    assert.equal(r.json.estado, 'ativa');
    assert.equal(r.json.objetivo, 'estudar');
    assert.deepEqual(r.json.categorias, ['estudar_ingles', 'estudar_historia']);
    assert.equal(r.json.duracaoSegundos, 1800);
    assert.ok(r.json.restanteSegundos > 1790 && r.json.restanteSegundos <= 1800);
    const doc = await db.sessoes.findOne({ _id: new ObjectId(r.json.id) });
    assert.ok(doc.usuarioId.equals(id));
    assert.equal(doc.expiraEm.getTime() - doc.iniciadaEm.getTime(), 1800 * 1000);
  });

  test('aceita "categoria" no singular e tira categorias repetidas', async () => {
    const a = await novaConta();
    const um = await chamar('POST', '/sessoes', { objetivo: 'ler', categoria: 'ler_romance', duracaoSegundos: 60 }, a.token);
    assert.equal(um.status, 201);
    assert.deepEqual(um.json.categorias, ['ler_romance']);
    const b = await novaConta();
    const rep = await chamar('POST', '/sessoes',
      { objetivo: 'ler', categorias: ['ler_fc', 'ler_fc'], duracaoSegundos: 60 }, b.token);
    assert.deepEqual(rep.json.categorias, ['ler_fc']);
  });

  test('recusa pedidos inválidos com mensagem clara (400)', async () => {
    const { token, id } = await novaConta();
    const casos = [
      [sessaoValida({ objetivo: 'danca' }), 'Escolha o objetivo.'],
      [sessaoValida({ objetivo: undefined }), 'Escolha o objetivo.'],
      [sessaoValida({ categorias: [] }), 'Escolha pelo menos uma categoria.'],
      [sessaoValida({ categorias: ['ler_romance'] }), 'Há categoria que não pertence ao objetivo escolhido.'],
      [sessaoValida({ categorias: ['estudar_matematica', 'estudar_lp', 'estudar_ingles', 'estudar_artes', 'estudar_historia', 'estudar_fisica'] }),
        'Escolha no máximo 5 categorias.'],
      [sessaoValida({ duracaoSegundos: 0 }), 'A duração deve ficar entre 1 segundo e 3 horas.'],
      [sessaoValida({ duracaoSegundos: 10801 }), 'A duração deve ficar entre 1 segundo e 3 horas.'],
      [sessaoValida({ duracaoSegundos: 90.5 }), 'A duração deve ficar entre 1 segundo e 3 horas.'],
      [sessaoValida({ duracaoSegundos: '60' }), 'A duração deve ficar entre 1 segundo e 3 horas.'],
    ];
    for (const [corpo, msg] of casos) {
      const r = await chamar('POST', '/sessoes', corpo, token);
      assert.equal(r.status, 400, JSON.stringify(corpo));
      assert.equal(r.json.erro, msg);
    }
    assert.equal(await db.sessoes.countDocuments({ usuarioId: id }), 0); // nada foi gravado
  });

  test('limites da duração: 1 segundo e 3 horas são aceitos', async () => {
    const a = await novaConta();
    assert.equal((await chamar('POST', '/sessoes', sessaoValida({ duracaoSegundos: 1 }), a.token)).status, 201);
    const b = await novaConta();
    assert.equal((await chamar('POST', '/sessoes', sessaoValida({ duracaoSegundos: 10800 }), b.token)).status, 201);
  });

  test('não deixa começar outra sessão enquanto uma está em andamento (409)', async () => {
    const { token } = await novaConta();
    assert.equal((await chamar('POST', '/sessoes', sessaoValida(), token)).status, 201);
    const r = await chamar('POST', '/sessoes', sessaoValida({ duracaoSegundos: 60 }), token);
    assert.equal(r.status, 409);
    assert.match(r.json.erro, /sessão em andamento/);
  });

  test('duas sessões pedidas ao mesmo tempo: só uma entra (o banco garante)', async () => {
    const { token, id } = await novaConta();
    const rs = await Promise.all(
      Array.from({ length: 6 }, () => chamar('POST', '/sessoes', sessaoValida({ duracaoSegundos: 120 }), token)),
    );
    const codigos = rs.map((r) => r.status).sort();
    assert.deepEqual(codigos, [201, 409, 409, 409, 409, 409]);
    assert.equal(await db.sessoes.countDocuments({ usuarioId: id, estado: 'ativa' }), 1);
  });

  test('GET /sessoes/ativa devolve a sessão em andamento; sem sessão, 404', async () => {
    const { token } = await novaConta();
    assert.equal((await chamar('GET', '/sessoes/ativa', undefined, token)).status, 404);
    const criada = await chamar('POST', '/sessoes', sessaoValida(), token);
    const r = await chamar('GET', '/sessoes/ativa', undefined, token);
    assert.equal(r.status, 200);
    assert.equal(r.json.id, criada.json.id);
  });

  test('quando o tempo acaba a sessão expira sozinha e libera uma nova', async () => {
    const { token, id } = await novaConta();
    const a = await chamar('POST', '/sessoes', sessaoValida({ duracaoSegundos: 600 }), token);
    // simula a passagem do tempo no banco
    const passado = new Date(Date.now() - 1000);
    await db.sessoes.updateOne({ _id: new ObjectId(a.json.id) }, { $set: { expiraEm: passado, iniciadaEm: new Date(passado.getTime() - 600e3) } });

    assert.equal((await chamar('GET', '/sessoes/ativa', undefined, token)).status, 404);
    const velha = await chamar('GET', `/sessoes/${a.json.id}`, undefined, token);
    assert.equal(velha.json.estado, 'expirada');
    assert.equal(velha.json.restanteSegundos, 0);
    assert.equal(new Date(velha.json.encerradaEm).getTime(), passado.getTime());

    const nova = await chamar('POST', '/sessoes', sessaoValida({ duracaoSegundos: 60 }), token);
    assert.equal(nova.status, 201);
    assert.equal(await db.sessoes.countDocuments({ usuarioId: id }), 2);
  });

  test('histórico: mais recente primeiro, com limite e paginação por data', async () => {
    const { token, id } = await novaConta();
    const t0 = Date.now();
    const docs = Array.from({ length: 5 }, (_, i) => {
      const ini = new Date(t0 - (i + 1) * 3600e3); // de hora em hora
      return {
        usuarioId: id, objetivoId: 'ler', categoriaIds: ['ler_romance'], duracaoSegundos: 600,
        iniciadaEm: ini, expiraEm: new Date(ini.getTime() + 600e3), encerradaEm: new Date(ini.getTime() + 600e3), estado: 'expirada',
      };
    });
    await db.sessoes.insertMany(docs);
    const todas = await chamar('GET', '/sessoes', undefined, token);
    assert.equal(todas.json.length, 5);
    const ts = todas.json.map((s) => new Date(s.iniciadaEm).getTime());
    assert.deepEqual(ts, [...ts].sort((x, y) => y - x));
    const duas = await chamar('GET', '/sessoes?limite=2', undefined, token);
    assert.equal(duas.json.length, 2);
    const proxima = await chamar('GET', `/sessoes?limite=2&antes=${encodeURIComponent(duas.json[1].iniciadaEm)}`, undefined, token);
    assert.equal(proxima.json.length, 2);
    assert.ok(new Date(proxima.json[0].iniciadaEm) < new Date(duas.json[1].iniciadaEm));
    assert.equal((await chamar('GET', '/sessoes?antes=ontem', undefined, token)).status, 400);
  });

  test('GET /sessoes/ultima devolve a última escolha para sugerir na próxima vez', async () => {
    const { token, id } = await novaConta();
    assert.equal((await chamar('GET', '/sessoes/ultima', undefined, token)).status, 404);
    const ini = new Date(Date.now() - 7200e3);
    await db.sessoes.insertOne({
      usuarioId: id, objetivoId: 'estudar', categoriaIds: ['estudar_ingles'], duracaoSegundos: 240,
      iniciadaEm: ini, expiraEm: new Date(ini.getTime() + 240e3), encerradaEm: new Date(ini.getTime() + 240e3), estado: 'expirada',
    });
    const r = await chamar('GET', '/sessoes/ultima', undefined, token);
    assert.equal(r.status, 200);
    assert.equal(r.json.objetivo, 'estudar');
    assert.deepEqual(r.json.categorias, ['estudar_ingles']);
    assert.equal(r.json.duracaoSegundos, 240);
  });

  test('GET /sessoes/resumo soma o tempo por dia, objetivo e categoria', async () => {
    const { token, id } = await novaConta();
    const dia = (n) => new Date(Date.now() - n * 24 * 3600e3);
    const sessao = (ini, obj, cats, seg) => ({
      usuarioId: id, objetivoId: obj, categoriaIds: cats, duracaoSegundos: seg,
      iniciadaEm: ini, expiraEm: new Date(ini.getTime() + seg * 1000), encerradaEm: new Date(ini.getTime() + seg * 1000), estado: 'expirada',
    });
    await db.sessoes.insertMany([
      sessao(dia(1), 'estudar', ['estudar_ingles', 'estudar_historia'], 1800),
      sessao(dia(2), 'estudar', ['estudar_ingles'], 900),
      sessao(dia(3), 'ler', ['ler_romance'], 600),
      sessao(dia(30), 'ler', ['ler_romance'], 7200), // fora da janela de 7 dias
    ]);
    const r = await chamar('GET', '/sessoes/resumo?dias=7', undefined, token);
    assert.equal(r.status, 200);
    assert.equal(r.json.dias, 7);
    assert.equal(r.json.sessoes, 3);
    assert.equal(r.json.segundos, 3300);
    assert.deepEqual(r.json.porObjetivo, [
      { objetivo: 'estudar', sessoes: 2, segundos: 2700 },
      { objetivo: 'ler', sessoes: 1, segundos: 600 },
    ]);
    assert.deepEqual(r.json.categoriasMaisUsadas[0], { categoria: 'estudar_ingles', titulo: 'Inglês', sessoes: 2 });
    assert.equal(r.json.porDia.length, 3);
    assert.equal(r.json.porDia.reduce((n, d) => n + d.segundos, 0), 3300);
    const tudo = await chamar('GET', '/sessoes/resumo?dias=90', undefined, token);
    assert.equal(tudo.json.sessoes, 4);
    const vazio = await chamar('GET', '/sessoes/resumo', undefined, (await novaConta()).token);
    assert.equal(vazio.json.sessoes, 0);
    assert.deepEqual(vazio.json.porObjetivo, []);
  });

  test('uma pessoa não vê as sessões de outra', async () => {
    const a = await novaConta();
    const b = await novaConta();
    const s = await chamar('POST', '/sessoes', sessaoValida(), a.token);
    assert.equal((await chamar('GET', `/sessoes/${s.json.id}`, undefined, b.token)).status, 404);
    assert.equal((await chamar('GET', '/sessoes', undefined, b.token)).json.length, 0);
    assert.equal((await chamar('GET', '/sessoes/não-é-id', undefined, a.token)).status, 404);
  });
});

describe('preferências', () => {
  test('quem nunca mexeu recebe o padrão: tudo desligado, texto 1,0', async () => {
    const { token } = await novaConta();
    const r = await chamar('GET', '/preferencias', undefined, token);
    assert.equal(r.status, 200);
    assert.deepEqual(r.json, {
      tema: 'sistema', altoContraste: false, tamanhoTexto: 1, notificacoes: false,
      lembretes: false, sons: false, vibracao: false, nivelConteudo: 0,
      iaAutorizada: null, metaDiariaMin: null, atualizadoEm: null,
    });
  });

  test('PATCH muda só o que foi enviado e guarda no banco', async () => {
    const { token, id } = await novaConta();
    const a = await chamar('PATCH', '/preferencias', { tema: 'escuro', tamanhoTexto: 1.2 }, token);
    assert.equal(a.status, 200);
    assert.equal(a.json.tema, 'escuro');
    assert.equal(a.json.tamanhoTexto, 1.2);
    assert.equal(a.json.notificacoes, false);
    const b = await chamar('PATCH', '/preferencias', { notificacoes: true, nivelConteudo: 2, metaDiariaMin: 90, iaAutorizada: true }, token);
    assert.equal(b.json.tema, 'escuro'); // continua
    assert.equal(b.json.notificacoes, true);
    assert.equal(b.json.nivelConteudo, 2);
    assert.equal(b.json.metaDiariaMin, 90);
    assert.equal(b.json.iaAutorizada, true);
    const doc = await db.preferencias.findOne({ _id: id });
    assert.equal(doc.tema, 'escuro');
    assert.equal(await db.preferencias.countDocuments({ _id: id }), 1);
    const c = await chamar('PATCH', '/preferencias', { metaDiariaMin: null, iaAutorizada: null }, token);
    assert.equal(c.json.metaDiariaMin, null);
    assert.equal(c.json.iaAutorizada, null);
  });

  test('recusa valores fora das regras (400)', async () => {
    const { token } = await novaConta();
    const ruins = [
      [{}, 'Envie pelo menos uma preferência para mudar.'],
      [{ tema: 'roxo' }, 'Tema inválido.'],
      [{ tamanhoTexto: 2 }, 'O tamanho do texto deve ficar entre 0,8 e 1,4.'],
      [{ tamanhoTexto: '1' }, 'O tamanho do texto deve ficar entre 0,8 e 1,4.'],
      [{ nivelConteudo: 4 }, 'O nível do conteúdo deve ser de 0 a 3.'],
      [{ notificacoes: 'sim' }, 'O campo notificacoes deve ser verdadeiro ou falso.'],
      [{ metaDiariaMin: 0 }, 'A meta diária deve ser de 1 a 1440 minutos, ou nula para desligar.'],
    ];
    for (const [corpo, msg] of ruins) {
      const r = await chamar('PATCH', '/preferencias', corpo, token);
      assert.equal(r.status, 400, JSON.stringify(corpo));
      assert.equal(r.json.erro, msg);
    }
    const ok = await chamar('PATCH', '/preferencias', { tamanhoTexto: 0.8 }, token);
    assert.equal(ok.status, 200);
    assert.equal((await chamar('PATCH', '/preferencias', { tamanhoTexto: 1.4 }, token)).status, 200);
  });

  test('DELETE volta tudo ao padrão', async () => {
    const { token } = await novaConta();
    await chamar('PATCH', '/preferencias', { notificacoes: true }, token);
    assert.equal((await chamar('DELETE', '/preferencias', undefined, token)).status, 204);
    assert.equal((await chamar('GET', '/preferencias', undefined, token)).json.notificacoes, false);
  });

  test('cada pessoa tem as suas', async () => {
    const a = await novaConta();
    const b = await novaConta();
    await chamar('PATCH', '/preferencias', { tema: 'claro' }, a.token);
    await chamar('PATCH', '/preferencias', { tema: 'escuro' }, b.token);
    assert.equal((await chamar('GET', '/preferencias', undefined, a.token)).json.tema, 'claro');
    assert.equal((await chamar('GET', '/preferencias', undefined, b.token)).json.tema, 'escuro');
  });
});

describe('notificações', () => {
  const nova = (extra = {}) => ({ tipo: 'lembrete', titulo: 'Hora de uma pausa', descricao: 'Levante e beba água.', ...extra });

  test('caixa começa vazia; POST cria; GET lista com o total de não lidas', async () => {
    const { token } = await novaConta();
    const vazia = await chamar('GET', '/notificacoes', undefined, token);
    assert.deepEqual(vazia.json, { naoLidas: 0, itens: [] });
    const c = await chamar('POST', '/notificacoes', nova(), token);
    assert.equal(c.status, 201);
    assert.equal(c.json.lida, false);
    assert.equal(c.json.tipo, 'lembrete');
    await chamar('POST', '/notificacoes', nova({ tipo: 'conquista', titulo: 'Meta cumprida' }), token);
    const r = await chamar('GET', '/notificacoes', undefined, token);
    assert.equal(r.json.naoLidas, 2);
    assert.equal(r.json.itens.length, 2);
    assert.equal(r.json.itens[0].titulo, 'Meta cumprida'); // mais recente primeiro
  });

  test('recusa tipo e textos inválidos (400)', async () => {
    const { token } = await novaConta();
    assert.equal((await chamar('POST', '/notificacoes', nova({ tipo: 'spam' }), token)).status, 400);
    assert.equal((await chamar('POST', '/notificacoes', nova({ titulo: '   ' }), token)).status, 400);
    assert.equal((await chamar('POST', '/notificacoes', nova({ titulo: 'x'.repeat(81) }), token)).status, 400);
    assert.equal((await chamar('POST', '/notificacoes', nova({ descricao: 'y'.repeat(301) }), token)).status, 400);
  });

  test('PATCH marca como lida; ?lida=false filtra; ler-todas marca o resto', async () => {
    const { token } = await novaConta();
    const a = await chamar('POST', '/notificacoes', nova(), token);
    await chamar('POST', '/notificacoes', nova({ titulo: 'Segunda' }), token);
    await chamar('POST', '/notificacoes', nova({ titulo: 'Terceira' }), token);
    const lida = await chamar('PATCH', `/notificacoes/${a.json.id}`, { lida: true }, token);
    assert.equal(lida.json.lida, true);
    assert.equal((await chamar('PATCH', `/notificacoes/${a.json.id}`, { lida: 'sim' }, token)).status, 400);
    const nao = await chamar('GET', '/notificacoes?lida=false', undefined, token);
    assert.equal(nao.json.itens.length, 2);
    assert.equal(nao.json.naoLidas, 2);
    const todas = await chamar('POST', '/notificacoes/ler-todas', undefined, token);
    assert.deepEqual(todas.json, { marcadas: 2 });
    assert.equal((await chamar('GET', '/notificacoes', undefined, token)).json.naoLidas, 0);
  });

  test('DELETE apaga uma; DELETE sem id limpa a caixa; id de outra pessoa dá 404', async () => {
    const a = await novaConta();
    const b = await novaConta();
    const n1 = await chamar('POST', '/notificacoes', nova(), a.token);
    await chamar('POST', '/notificacoes', nova({ titulo: 'Outra' }), a.token);
    assert.equal((await chamar('DELETE', `/notificacoes/${n1.json.id}`, undefined, b.token)).status, 404);
    assert.equal((await chamar('PATCH', `/notificacoes/${n1.json.id}`, { lida: true }, b.token)).status, 404);
    assert.equal((await chamar('DELETE', `/notificacoes/${n1.json.id}`, undefined, a.token)).status, 204);
    assert.equal((await chamar('DELETE', `/notificacoes/${n1.json.id}`, undefined, a.token)).status, 404);
    assert.equal((await chamar('GET', '/notificacoes', undefined, a.token)).json.itens.length, 1);
    assert.equal((await chamar('DELETE', '/notificacoes', undefined, a.token)).status, 204);
    assert.equal((await chamar('GET', '/notificacoes', undefined, a.token)).json.itens.length, 0);
    assert.equal((await chamar('PATCH', '/notificacoes/xyz', { lida: true }, a.token)).status, 404);
  });

  test('a caixa tem limite de 200 notificações guardadas (429)', async () => {
    const { token, id } = await novaConta();
    const agora = new Date();
    await db.notificacoes.insertMany(Array.from({ length: 200 }, (_, i) => ({
      usuarioId: id, tipo: 'sistema', titulo: `n${i}`, descricao: '', criadaEm: agora, lida: true,
    })));
    const r = await chamar('POST', '/notificacoes', nova(), token);
    assert.equal(r.status, 429);
  });
});

describe('exclusão de conta', () => {
  test('DELETE /meus-dados apaga sessões, notificações e preferências só de quem saiu', async () => {
    const a = await novaConta();
    const b = await novaConta();
    for (const p of [a, b]) {
      await chamar('POST', '/sessoes', sessaoValida({ duracaoSegundos: 300 }), p.token);
      await chamar('POST', '/notificacoes', { tipo: 'sistema', titulo: 'Oi', descricao: '' }, p.token);
      await chamar('PATCH', '/preferencias', { tema: 'escuro' }, p.token);
    }
    assert.equal((await chamar('DELETE', '/meus-dados', undefined, a.token)).status, 204);
    assert.equal(await db.sessoes.countDocuments({ usuarioId: a.id }), 0);
    assert.equal(await db.notificacoes.countDocuments({ usuarioId: a.id }), 0);
    assert.equal(await db.preferencias.countDocuments({ _id: a.id }), 0);
    assert.equal(await db.usuarios.countDocuments({ _id: a.id }), 0);
    // quem ficou continua com tudo
    assert.equal(await db.sessoes.countDocuments({ usuarioId: b.id }), 1);
    assert.equal(await db.notificacoes.countDocuments({ usuarioId: b.id }), 1);
    assert.equal(await db.preferencias.countDocuments({ _id: b.id }), 1);
  });
});

describe('atualização de um banco antigo (v6)', () => {
  test('um banco que já tinha dados e índices antigos é atualizado sem perder nada', async () => {
    const nome = `ikai_antigo_${Date.now()}`;
    const config = { ...lerConfig({}), mongoUri: process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017', mongoDb: nome };
    // monta o banco como a versão anterior deixava: sem validador, índices simples
    const { MongoClient } = await import('mongodb');
    const cli = new MongoClient(config.mongoUri);
    await cli.connect();
    const velho = cli.db(nome);
    await velho.collection('usuarios').createIndex({ email: 1 }, { unique: true });
    await velho.collection('artigos').createIndex({ criadoEm: -1 });
    await velho.collection('comunidades').createIndex({ nomeChave: 1 }, { unique: true });
    await velho.collection('posts').createIndex({ comunidadeId: 1, criadoEm: -1 });
    const uid = new ObjectId();
    await velho.collection('usuarios').insertOne({ _id: uid, nome: 'Bia Lima', email: 'bia@exemplo.com', senhaHash: 'x'.repeat(60), criadoEm: new Date() });
    await velho.collection('artigos').insertOne({ _id: 'u1', autorId: uid, autorNome: 'Bia' }); // incompleto de propósito
    await cli.close();

    const novo = await conectar(config); // não pode dar erro
    try {
      assert.equal(await novo.usuarios.countDocuments({ email: 'bia@exemplo.com' }), 1);
      assert.equal(await novo.artigos.countDocuments(), 1); // o documento antigo continua lá
      assert.equal(await novo.objetivos.countDocuments(), 4);
      assert.equal(await novo.categorias.countDocuments(), 60);
      const nomes = (await novo.sessoes.indexes()).map((i) => i.name);
      assert.ok(nomes.includes('uma_sessao_ativa'));
      // e rodar de novo (reinício do servidor) também não dá erro
      const outra = await conectar(config);
      await outra.cliente.close();
    } finally {
      await novo.base.dropDatabase();
      await novo.cliente.close();
    }
  });
});

// O catálogo do servidor é uma cópia do que está no app (lib/pages_configurar).
// Se o app estiver na pasta de cima (como no repositório), confere item a item.
const PASTA_APP = new URL('../../lib/pages_configurar/', import.meta.url);
const ARQUIVOS_APP = {
  ver_conteudo: 'objetivo_conteudo.dart', ler: 'objetivo_leitura.dart',
  estudar: 'objetivo_estudo.dart', oficio: 'objetivo_oficio.dart',
};

describe('catálogo igual ao do app', { skip: !existsSync(new URL('objetivo_oficio.dart', PASTA_APP)) }, () => {
  for (const [objetivo, arquivo] of Object.entries(ARQUIVOS_APP)) {
    test(`${objetivo}: mesmas categorias, títulos e ordem`, () => {
      const dart = readFileSync(new URL(arquivo, PASTA_APP), 'utf8');
      const itens = [...dart.matchAll(/Categoria\(\s*id: '(\w+)',\s*titulo: '([^']+)',\s*icone: Icons\.(\w+),/g)];
      assert.deepEqual(itens.map((m) => m[1]), OBJETIVOS[objetivo]);
      for (const [, id, titulo, icone] of itens) {
        assert.deepEqual(CATEGORIAS_INFO[id], { titulo, icone }, id);
      }
      const o = dart.match(/Objetivo\(\s*id: '(\w+)',\s*titulo: '([^']+)',\s*icone: Icons\.(\w+),/);
      assert.equal(o[1], objetivo);
      assert.deepEqual(OBJETIVOS_INFO[objetivo], { titulo: o[2], icone: o[3] });
    });
  }
});
