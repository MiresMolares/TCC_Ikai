import jwt from 'jsonwebtoken';
import { ObjectId } from 'mongodb';
import { naoAutorizado } from './erros.js';

export function criarToken(config, usuario) {
  return jwt.sign({ sub: String(usuario._id) }, config.jwtSecret, {
    expiresIn: config.jwtExpira,
  });
}

/** Exige "Authorization: Bearer <token>" e põe o usuário em req.usuario. */
export function exigirLogin({ db, config }) {
  return async (req, _res, next) => {
    try {
      const cab = req.get('authorization') || '';
      const m = /^Bearer (.+)$/.exec(cab);
      if (!m) throw naoAutorizado();
      let carga;
      try {
        carga = jwt.verify(m[1], config.jwtSecret);
      } catch {
        throw naoAutorizado('Sua sessão expirou. Entre de novo.');
      }
      if (!ObjectId.isValid(carga.sub)) throw naoAutorizado();
      const u = await db.usuarios.findOne({ _id: new ObjectId(carga.sub) });
      if (!u) throw naoAutorizado('Conta não encontrada.');
      req.usuario = u;
      next();
    } catch (e) {
      next(e);
    }
  };
}

export const primeiroNome = (nome) =>
  (String(nome).trim().split(/\s+/)[0] || 'Leitor');

export const usuarioPublico = (u, config) => ({
  nome: u.nome,
  email: u.email,
});
