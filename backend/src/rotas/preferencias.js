import { Router } from 'express';
import { exigirLogin } from '../auth.js';
import { ruim } from '../erros.js';

// Valores de quem ainda não mexeu em nada. As notificações começam desligadas
// (o Ikai só avisa se a pessoa quiser).
export const PADRAO = {
  tema: 'sistema',
  altoContraste: false,
  tamanhoTexto: 1,
  notificacoes: false,
  lembretes: false,
  sons: false,
  vibracao: false,
  nivelConteudo: 0,
  iaAutorizada: null,
  metaDiariaMin: null,
};

const BOOLEANOS = ['altoContraste', 'notificacoes', 'lembretes', 'sons', 'vibracao'];

export function rotasPreferencias({ db, config }) {
  const r = Router();
  const login = exigirLogin({ db, config });

  const saida = (p) => {
    const { _id, atualizadoEm, ...campos } = p ?? {};
    return { ...PADRAO, ...campos, atualizadoEm: atualizadoEm ?? null };
  };

  r.get('/preferencias', login, async (req, res) => {
    res.json(saida(await db.preferencias.findOne({ _id: req.usuario._id })));
  });

  // Muda só os campos enviados; os outros ficam como estão.
  r.patch('/preferencias', login, async (req, res) => {
    const b = req.body ?? {};
    const mudar = {};
    if ('tema' in b) {
      if (!['claro', 'escuro', 'sistema'].includes(b.tema)) throw ruim('Tema inválido.');
      mudar.tema = b.tema;
    }
    for (const k of BOOLEANOS) {
      if (k in b) {
        if (typeof b[k] !== 'boolean') throw ruim(`O campo ${k} deve ser verdadeiro ou falso.`);
        mudar[k] = b[k];
      }
    }
    if ('tamanhoTexto' in b) {
      if (typeof b.tamanhoTexto !== 'number' || b.tamanhoTexto < 0.8 || b.tamanhoTexto > 1.4) {
        throw ruim('O tamanho do texto deve ficar entre 0,8 e 1,4.');
      }
      mudar.tamanhoTexto = b.tamanhoTexto;
    }
    if ('nivelConteudo' in b) {
      if (!Number.isInteger(b.nivelConteudo) || b.nivelConteudo < 0 || b.nivelConteudo > 3) {
        throw ruim('O nível do conteúdo deve ser de 0 a 3.');
      }
      mudar.nivelConteudo = b.nivelConteudo;
    }
    if ('iaAutorizada' in b) {
      if (b.iaAutorizada !== null && typeof b.iaAutorizada !== 'boolean') {
        throw ruim('O campo iaAutorizada deve ser verdadeiro, falso ou nulo.');
      }
      mudar.iaAutorizada = b.iaAutorizada;
    }
    if ('metaDiariaMin' in b) {
      const m = b.metaDiariaMin;
      if (m !== null && (!Number.isInteger(m) || m < 1 || m > 1440)) {
        throw ruim('A meta diária deve ser de 1 a 1440 minutos, ou nula para desligar.');
      }
      mudar.metaDiariaMin = m;
    }
    if (Object.keys(mudar).length === 0) throw ruim('Envie pelo menos uma preferência para mudar.');

    const doc = await db.preferencias.findOneAndUpdate(
      { _id: req.usuario._id },
      { $set: { ...mudar, atualizadoEm: new Date() } },
      { upsert: true, returnDocument: 'after' },
    );
    res.json(saida(doc));
  });

  // Volta tudo ao padrão.
  r.delete('/preferencias', login, async (req, res) => {
    await db.preferencias.deleteOne({ _id: req.usuario._id });
    res.status(204).end();
  });

  return r;
}
