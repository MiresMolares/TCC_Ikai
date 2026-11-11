// Mesma limpeza do app (lib/core/sem_emoji.dart e conteudo_usuario.dart).
const EMOJI =
  /[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\u{2B00}-\u{2BFF}\u{2300}-\u{23FF}\u{FE0F}\u{200D}\u{20E3}\u{E0020}-\u{E007F}]/gu;

export function removerEmojis(t) {
  return String(t ?? '').replace(EMOJI, '').replace(/[ \t]{2,}/g, ' ').trim();
}

/** Uma linha: sem emojis, espaços normalizados. */
export function limpo(t) {
  return removerEmojis(t).replace(/[ \t]+/g, ' ').trim();
}

/** Para comparar nomes: sem acento, minúsculo, espaços únicos. */
export function normalizar(t) {
  return String(t ?? '')
    .normalize('NFD')
    .replace(/\p{M}/gu, '')
    .toLowerCase()
    .replace(/\s+/g, ' ')
    .trim();
}

export function dia(data) {
  return data.toISOString().slice(0, 10);
}
