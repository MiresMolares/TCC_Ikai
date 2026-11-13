/** Erro com status HTTP e mensagem em português (vai para o app). */
export class ErroHttp extends Error {
  constructor(status, mensagem) {
    super(mensagem);
    this.status = status;
  }
}
export const ruim = (m) => new ErroHttp(400, m);
export const naoAutorizado = (m = 'Entre na sua conta.') => new ErroHttp(401, m);
export const proibido = (m = 'Você não pode fazer isso.') => new ErroHttp(403, m);
export const naoEncontrado = (m = 'Não encontrado.') => new ErroHttp(404, m);
export const conflito = (m) => new ErroHttp(409, m);
