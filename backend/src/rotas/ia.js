import { Router } from 'express';
import { exigirLogin } from '../auth.js';
import { LIMITES as L } from '../catalogo.js';
import { ErroHttp, ruim } from '../erros.js';

const MAX_TURNOS = 14;
const MAX_TEXTO = 6000;
const MAX_TOTAL = 20000;
const MAX_SAIDA = 8192;

/** Só deixa passar o formato que o app usa; o resto é descartado. */
export function sanear(corpo) {
  const b = corpo ?? {};
  let total = 0;
  const texto = (t, max) => {
    if (typeof t !== 'string' || !t.trim()) throw ruim('Mensagem inválida.');
    if (t.length > max) throw ruim('Mensagem longa demais.');
    total += t.length;
    return t;
  };

  if (!Array.isArray(b.contents) || b.contents.length === 0 || b.contents.length > MAX_TURNOS) {
    throw ruim('Conversa inválida.');
  }
  const contents = b.contents.map((c) => {
    const role = c?.role === 'model' ? 'model' : 'user';
    const partes = Array.isArray(c?.parts) ? c.parts : [];
    if (partes.length !== 1) throw ruim('Conversa inválida.');
    return { role, parts: [{ text: texto(partes[0]?.text, MAX_TEXTO) }] };
  });

  const saida = { contents };
  const sys = b.system_instruction?.parts;
  if (Array.isArray(sys) && sys.length === 1) {
    saida.system_instruction = { parts: [{ text: texto(sys[0]?.text, MAX_TEXTO) }] };
  }
  if (total > MAX_TOTAL) throw ruim('Conversa longa demais.');

  const g = b.generationConfig ?? {};
  const t = Number(g.temperature);
  const m = Number(g.maxOutputTokens);
  saida.generationConfig = {
    temperature: Number.isFinite(t) ? Math.min(Math.max(t, 0), 1.5) : 0.8,
    maxOutputTokens: Number.isFinite(m) ? Math.min(Math.max(Math.trunc(m), 64), MAX_SAIDA) : 2048,
    responseMimeType: 'application/json',
  };
  return saida;
}

/**
 * Proxy do Gemini: o app manda a conversa para cá e a CHAVE fica só no
 * servidor. Exige login, limita tamanho e frequência.
 */
export function rotasIa({ db, config, fetchImpl = fetch }) {
  const r = Router();
  const login = exigirLogin({ db, config });
  const usos = new Map(); // usuário -> instantes das últimas chamadas

  function limitar(id) {
    const agora = Date.now();
    const janela = (usos.get(id) ?? []).filter((t) => agora - t < 3600e3);
    if (janela.length >= L.iaPorHora) {
      usos.set(id, janela);
      throw new ErroHttp(429, 'Muitas conversas com a IA nesta hora. Tente daqui a pouco.');
    }
    janela.push(agora);
    usos.set(id, janela);
  }

  r.post('/ia/gemini', login, async (req, res) => {
    if (!config.geminiKey) {
      throw new ErroHttp(503, 'A IA não está configurada no servidor.');
    }
    const corpo = sanear(req.body);
    limitar(String(req.usuario._id));

    const url =
      'https://generativelanguage.googleapis.com/v1beta/models/' +
      `${encodeURIComponent(config.geminiModelo)}:generateContent`;
    let resp;
    try {
      resp = await fetchImpl(url, {
        method: 'POST',
        headers: { 'content-type': 'application/json', 'x-goog-api-key': config.geminiKey },
        body: JSON.stringify(corpo),
        signal: AbortSignal.timeout(25000),
      });
    } catch {
      throw new ErroHttp(504, 'A IA demorou demais para responder.');
    }
    const bruto = await resp.text();
    if (!resp.ok) {
      let detalhe = '';
      try { detalhe = String(JSON.parse(bruto)?.error?.message ?? '').slice(0, 300); } catch { /* ignora */ }
      console.error(`[ia] Gemini HTTP ${resp.status} (${config.geminiModelo}): ${detalhe}`);
      throw new ErroHttp(502, `A IA não respondeu (HTTP ${resp.status}).`);
    }
    res.status(200).type('application/json').send(bruto);
  });

  return r;
}
