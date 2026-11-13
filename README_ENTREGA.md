# Ikai - entrega v6 (banco de dados, Ik AI de verdade, botão só na Home)

## Novidades da v6
1. **Botão flutuante da Ik AI só na Home.** Some nas etapas de escolha (objetivo, categorias), em Explorar, Perfil, leitura etc.
2. **Ik AI respondendo como IA.** Antes ela "repetia mensagens" porque o Gemini não estava ligado (sem chave, ou interruptor desligado) e o app caía nas respostas prontas do aparelho. Agora:
   - A chave do Gemini pode ficar **no servidor** (`backend/`), nunca no app. O app chama `POST /ia/gemini` com o token de login.
   - A pessoa autoriza **uma vez** (cartão no início da conversa); a escolha fica guardada e pode ser mudada em Configurações > Ik AI.
   - A conversa mostra uma faixa honesta: "IA (Gemini) ligada" ou "Modo local: respostas prontas, sem IA". Se o Gemini falhar, a faixa avisa em vez de fingir.
   - Sinais de crise (CVV 188 / SAMU 192) continuam sem passar pelo Gemini. Nome e e-mail nunca são enviados.
3. **Banco de dados (primeira fase).** Pasta `backend/`: Node + Express + MongoDB (a stack do grupo). Guarda contas (senha com hash, login por token), artigos, comunidades e mensagens dos usuários. O app usa a API quando roda com `API_URL`; sem ela, funciona como antes (contas de mentira e conteúdo local).

## Como rodar com o banco
1. Instale Node 22+ e tenha um MongoDB (local ou um cluster gratuito do MongoDB Atlas).
2. `cd backend && cp .env.example .env` e edite: `MONGODB_URI`, `JWT_SECRET` (texto longo e aleatório) e, para a IA, `GEMINI_API_KEY`.
3. `npm install` e `npm start` (porta 3000; `GET /saude` confere). `npm test` roda 64 testes contra um MongoDB real (`MONGODB_URI=...`).
   O banco do app (9 coleções, validação, índices, rotas de sessão, preferências e notificações) está descrito em `backend/docs/BANCO_DE_DADOS.md`; `npm run db:init` prepara o banco e `npm run db:demo` grava dados de exemplo.
4. No app, no `env.json` coloque `"API_URL": "http://localhost:3000"` (veja `env.json.example`) e rode `flutter run -d chrome --dart-define-from-file=env.json`. No Codespaces use o endereço público da porta 3000 (porta pública) em vez de localhost. Sem `API_URL` o app roda no modo local; sem `GEMINI_API_KEY` no `env.json` ele usa a chave do servidor.
5. Para o app no navegador falar com a API, deixe `CORS_ORIGEM=*` em desenvolvimento; em produção coloque o endereço do app.

Com a API, a senha mínima passa a ser **8** caracteres (a regra do servidor). A conta `adm@email.com` só existe no modo local; no modo com banco, crie uma conta pelo Cadastro.

### O que o servidor faz (todas as rotas exigem login, exceto cadastro/login)
| Rota | Função |
|---|---|
| `POST /auth/cadastro`, `POST /auth/login` | criar conta, entrar (devolve token) |
| `GET/PATCH /auth/eu`, `POST /auth/senha` | ver/alterar nome, trocar senha |
| `DELETE /meus-dados` | exclui a conta e tudo o que a pessoa escreveu |
| `GET/POST /artigos`, `DELETE /artigos/:id` | artigos dos usuários |
| `GET/POST /comunidades`, `DELETE /comunidades/:id` | comunidades criadas por usuários |
| `GET/POST /comunidades/:id/posts`, `DELETE .../posts/:postId` | mural |
| `POST /ia/gemini` | repassa ao Gemini com a chave do servidor (limite por pessoa) |

Regras que o servidor repete (não confia no app): tamanhos, categorias válidas, sem emojis, autor sempre vindo do token, só o autor (ou o dono da comunidade) apaga, e-mail dos outros nunca é devolvido, limites de frequência por pessoa e por IP, senha com bcrypt.

### Ainda NÃO está no banco (fase 2)
Tempo de uso diário, balanços semanais, reflexões, biblioteca, progresso, combinados e histórico continuam no aparelho (por conta). Também falta: manter o login ao fechar o app (o token fica só na memória: é preciso entrar de novo a cada abertura), e-mail de recuperação de senha (hoje não envia nada) e hospedagem do servidor (hoje roda na sua máquina).
Não consegui testar o Gemini de verdade aqui (sem chave nem acesso à rede): a integração foi testada com respostas simuladas. Ao rodar com a chave, a faixa da conversa mostra se está funcionando.

---
# Notas da v5 (continuam valendo)

## Como aplicar
1. Na raiz do projeto, APAGUE `lib/` e `test/` e copie as deste pacote no lugar. Mantenha `assets/`.
2. `flutter pub get`
3. `flutter run` (sem Gemini: as sugestões da Ik AI são geradas no aparelho). No navegador: `flutter run -d chrome`. Para ligar o Gemini, veja a seção abaixo.
4. `flutter test` (15 arquivos, 266 testes de lógica).

Conta de teste: `adm@email.com` / `1234`.

## Como ativar o Gemini (ponto 3)
O Gemini estava "inativo" porque o app não tinha chave. Agora, em 3 passos:
1. Crie uma chave em https://aistudio.google.com/apikey
2. Copie `env.json.example` para `env.json` (o `.gitignore` já impede que suba para o GitHub) e cole a chave em `GEMINI_API_KEY`.
3. `flutter run -d chrome --dart-define-from-file=env.json` (no Codespaces/navegador use sempre essa flag; sem ela o app roda, mas o Gemini fica inativo). Depois de criar ou mudar o `env.json`, pare o app e rode de novo: o valor é lido na compilação, não dá para ativar com hot reload.

Também corrigi o modelo padrão: agora é `gemini-3.8-flash`, que consta como estável na documentação oficial do Google (a lista atual de modelos Flash estáveis é `gemini-3.8-flash` e `gemini-3.6-flash`; o `gemini-3.5-flash` que apareceu numa versão anterior NÃO existe e causava erro 404, que o app escondia caindo nas sugestões locais). Se um dia o Google aposentar o modelo, basta trocar `GEMINI_MODEL` no `env.json`.

Como conferir que está ativo: Configurações > Ik AI > "Gemini (Google)" mostra "Ativo". Na versão avançada, a etapa "Ik AI" libera o interruptor; em modo debug, o console imprime o motivo quando o Gemini não responde (ex.: HTTP 404, chave inválida).
Limite conhecido: chave dentro do app é extraível. Por isso, na v6, prefira a chave no servidor (`backend/.env`).

## O que mudou, por ponto do pedido

### 1. Categorias em quadrados, com seleção múltipla
- Grade de 2 por fileira, cartões quadrados, ícone de 42 px (antes 26) em caixa de 68 px.
- Dá para marcar de 1 a 5 categorias. O feed continua com 8 conteúdos, em rodízio entre as categorias escolhidas, para uma não dominar as outras.
- "Usar a última escolha" aplica o histórico só quando a pessoa toca (nada é preenchido sozinho).

### 2. Meta diária no lugar das sessões de tempo fixo
- No primeiro uso a pessoa diz quanto quer usar por dia (10 min a 4 h) e escolhe a versão. A meta é dela: pode mudar em Configurações (diminuir vale na hora, aumentar vale a partir de amanhã).
- O app conta o tempo real de uso (só com o app à frente; segundo plano não conta).
- Na metade da meta: aviso da Ik AI no topo (some sozinho, não bloqueia).
- No fim: o app abre a conversa da Ik AI. A pessoa pode (a) contar o que aprendeu, (b) pedir mais 10, 15 ou 30 min justificando (no máximo 2 vezes por dia; a justificativa fica registrada), (c) ver ideias longe da tela, (d) encerrar o dia. Se o dia é encerrado, o app só volta no dia seguinte.
- "Encerrar o dia" também existe na Home, antes de o tempo acabar.
- Ao abrir o app (Início, Progresso e a primeira etapa da escolha), quem usa de forma recorrente vê: "Nos últimos N dias você usou o Ikai por X, uma média de Y por dia. Sua média está dentro/acima da meta de Z por dia." e a pergunta "O que você tem a dizer sobre o seu algoritmo? Você sente que está ganhando tempo com o Ikai?" (Estou ganhando tempo / Estou perdendo tempo / Mais ou menos + comentário opcional). Uma resposta por semana.
- Tudo é guardado por conta, no aparelho, e entra na exportação de dados (`tempo`): reflexões e balanços semanais são os dados para o TCC.

### 2b. Versão iniciante e avançada
- **Iniciante**: objetivo, categorias, pronto (2 etapas). Sem tempo por sessão, sem lembrete de foco, sem texto para a Ik AI.
- **Avançada**: + lembrete de foco por leitura (opcional, só avisa, não bloqueia) + espaço para contar à Ik AI o que quer fazer longe da tela (e o consentimento para o Gemini).
- Troca em Configurações. A escolha do dia fica gravada e vale só no dia: fechar o app não obriga a repetir, o dia seguinte começa limpo.

### 3. Gemini: ver acima.

### 4. O usuário faz diferença no app
- **Botão flutuante da Ik AI**: só na Home (v6), arrastável. Some sobre diálogos/menus e dentro da própria conversa.
- **Escrever artigo** (aba Comunidade > Meus artigos): objetivo, categoria, nível, título, resumo, texto, assuntos. Entra no feed e no Explorar da categoria escolhida, marcado como "(leitor)".
- **Criar comunidade**: nome, descrição, ícone, 1 a 5 categorias, regras. Dentro de cada comunidade há um **mural** (mensagens de 3 a 500 caracteres, sem curtidas). Quem escreveu apaga a própria mensagem; quem criou a comunidade apaga a comunidade e qualquer mensagem nela.
- Regras de validação (tamanhos, categoria válida, sem emojis, nome de comunidade único) ficam em `lib/services/conteudo_usuario.dart`, com 24 testes.
- **Banco de dados**: o app só conhece a interface `ConteudoRepositorio`. Sem `API_URL` usa `ConteudoLocal` (aparelho); com `API_URL` usa `ConteudoRemoto` (API + MongoDB, v6).
- Excluir a conta apaga também tudo o que a pessoa escreveu.

## Pilares mantidos
Feed finito; histórico só como sugestão (nunca aplicado sozinho); notificações desligadas por padrão; consentimento explícito para enviar algo ao Gemini (nome e e-mail nunca saem do aparelho); a Ik AI só reflete o que a pessoa declarou; gamificação só individual; sem emojis (teste varre `lib/`).

## Limitações e decisões a registrar no TCC
- A meta diária é **negociada**, não "intransponível": a pessoa pode pedir mais tempo, justificando. Mitigações: no máximo 2 prorrogações por dia, de até 30 min, com justificativa registrada, e o balanço semanal confronta o uso com a meta. Se a banca exigir bloqueio absoluto, é só definir `maxProrrogacoes = 0` em `tempo_diario.dart`.
- Os avisos (metade e fim) são **dentro do app**, não notificações do sistema operacional: com o app fechado nada é enviado (coerente com "notificações reduzidas"; push exigiria plugin e permissão).
- A contagem depende do relógio do aparelho: adiantar o relógio para o dia seguinte zera o dia. Só um servidor resolve.
- A interface nova (grade de categorias, tela de meta, avisos, botão flutuante, telas de conteúdo) **não pôde ser compilada** no ambiente onde foi escrita; a lógica está testada, as telas precisam rodar uma vez com `flutter run`. Se o analisador reclamar de algo, me envie a mensagem.
- Sem `API_URL`, o conteúdo criado por usuários é local; com ela, vai para o banco. Moderação (denúncia, bloqueio) ainda não existe.
- Sem `API_URL`, contas são de mentira, em memória; textos de privacidade e termos são preliminares; botões de login social só mostram aviso.

## Fundamentação (resumo)
- Planos "quando X, então Y": Gollwitzer & Sheeran (2006), meta-análise de 94 estudos (d = 0,65).
- Fricção antes de abrir apps reduz tentativas; pessoas tendem a desativar intervenções rígidas: Haliburton et al., CHI 2024. Por isso o limite é conversado, e não só imposto.
- A conversa segue a Entrevista Motivacional: refletir o que a pessoa disse, perguntar antes de presumir, deixar a escolha com ela.

## Adicionar mais artigos do app (sem banco)
Copie o modelo no topo de `lib/data/artigos_dados.dart`. Prompt para outra IA:

> Gere artigos originais em português do Brasil, sem emojis, no formato Dart abaixo. Cada artigo tem 3 a 5 parágrafos, fatos verificáveis, tom claro e calmo. Use categoriaId só destes: [cole os ids]. Continue a numeração a partir de a031. Inclua `nivel` (1 iniciante, 2 intermediário, 3 avançado) e varie os níveis dentro da mesma categoria. Devolva só o código.
> `Artigo(id: 'a031', objetivoId: '...', categoriaId: '...', nivel: 1, titulo: '...', autor: 'Equipe Ikai', resumo: '...', tags: ['...'], paragrafos: ['...'])`
