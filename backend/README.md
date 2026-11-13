# Ikai API

API em Node.js (Express 5) com MongoDB: login, sessões de uso, preferências, notificações, artigos, comunidades, mensagens e proxy do Gemini.

- **Banco de dados:** [docs/BANCO_DE_DADOS.md](docs/BANCO_DE_DADOS.md) (diagrama, dicionário de dados, índices, rotas e exemplos).
- **Rodar:** `npm install`, copiar `.env.example` para `.env`, `npm run db:init` e `npm start`.
- **Testar:** `MONGODB_URI=mongodb://127.0.0.1:27017 npm test` (60 testes contra um MongoDB de verdade; cada execução usa um banco novo e o apaga no fim).
