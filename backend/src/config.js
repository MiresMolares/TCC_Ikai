// Configuração lida das variáveis de ambiente (veja .env.example).
export function lerConfig(env = process.env) {
  return {
    porta: Number(env.PORT || 3000),
    mongoUri: env.MONGODB_URI || 'mongodb://127.0.0.1:27017',
    mongoDb: env.MONGODB_DB || 'ikai',
    jwtSecret: env.JWT_SECRET || '',
    jwtExpira: env.JWT_EXPIRA || '7d',
    geminiKey: env.GEMINI_API_KEY || '',
    geminiModelo: env.GEMINI_MODEL || 'gemini-3.8-flash',
    corsOrigem: env.CORS_ORIGEM || '*',
    bcryptCusto: Number(env.BCRYPT_CUSTO || 10),
    limitarLogin: env.LIMITAR_LOGIN !== 'nao',
  };
}

export function validarConfig(c) {
  if (c.jwtSecret.length < 16) {
    throw new Error(
      'Defina JWT_SECRET com pelo menos 16 caracteres (veja .env.example).',
    );
  }
}
