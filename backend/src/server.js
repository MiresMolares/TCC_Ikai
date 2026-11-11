import { criarApp } from './app.js';
import { lerConfig, validarConfig } from './config.js';
import { conectar } from './db.js';

const config = lerConfig();
validarConfig(config);
const db = await conectar(config);
const app = criarApp({ db, config });

const servidor = app.listen(config.porta, () => {
  console.log(`Ikai API em http://localhost:${config.porta} (IA ${config.geminiKey ? 'ligada' : 'desligada'})`);
});

for (const sinal of ['SIGINT', 'SIGTERM']) {
  process.on(sinal, () => servidor.close(() => db.cliente.close().then(() => process.exit(0))));
}
