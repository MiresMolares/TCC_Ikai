import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import { ErroHttp } from './erros.js';
import { rotasAuth } from './rotas/auth.js';
import { rotasConteudo } from './rotas/conteudo.js';
import { rotasIa } from './rotas/ia.js';

/** Monta o app Express. `db` tem as coleções; `fetchImpl` é trocável nos testes. */
export function criarApp({ db, config, fetchImpl }) {
  const app = express();
  app.disable('x-powered-by');
  app.use(helmet());
  app.use(cors({ origin: config.corsOrigem === '*' ? true : config.corsOrigem.split(',') }));
  app.use(express.json({ limit: '64kb' }));

  app.get('/saude', (_req, res) => {
    res.json({ ok: true, ia: Boolean(config.geminiKey) });
  });

  app.use(rotasAuth({ db, config }));
  app.use(rotasConteudo({ db, config }));
  app.use(rotasIa({ db, config, fetchImpl }));

  app.use((_req, res) => res.status(404).json({ erro: 'Rota não encontrada.' }));

  // eslint-disable-next-line no-unused-vars
  app.use((e, _req, res, _next) => {
    if (e instanceof ErroHttp) return res.status(e.status).json({ erro: e.message });
    if (e?.type === 'entity.parse.failed') return res.status(400).json({ erro: 'JSON inválido.' });
    if (e?.type === 'entity.too.large') return res.status(413).json({ erro: 'Pedido grande demais.' });
    console.error(e);
    res.status(500).json({ erro: 'Erro interno. Tente de novo.' });
  });

  return app;
}
