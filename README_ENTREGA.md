# Ikai - entrega v5 (meta diária, versões, conteúdo dos usuários)

## Como aplicar
1. Na raiz do projeto, APAGUE `lib/` e `test/` e copie as deste pacote no lugar. Mantenha `assets/`.
2. `flutter pub get`
3. `flutter run` (sem Gemini: as sugestões da Ik AI são geradas no aparelho). No navegador: `flutter run -d chrome`. Para ligar o Gemini, veja a seção abaixo.
4. `flutter test` (14 arquivos, 241 testes de lógica).

Conta de teste: `adm@email.com` / `1234`.

## Como ativar o Gemini (ponto 3)
O Gemini estava "inativo" porque o app não tinha chave. Agora, em 3 passos:
1. Crie uma chave em https://aistudio.google.com/apikey
2. Copie `env.json.example` para `env.json` (o `.gitignore` já impede que suba para o GitHub) e cole a chave em `GEMINI_API_KEY`.
3. `flutter run -d chrome --dart-define-from-file=env.json` (no Codespaces/navegador use sempre essa flag; sem ela o app roda, mas o Gemini fica inativo). Depois de criar ou mudar o `env.json`, pare o app e rode de novo: o valor é lido na compilação, não dá para ativar com hot reload.

Também corrigi o modelo padrão: agora é `gemini-3.8-flash`, que consta como estável na documentação oficial do Google (a lista atual de modelos Flash estáveis é `gemini-3.8-flash` e `gemini-3.6-flash`; o `gemini-3.5-flash` que apareceu numa versão anterior NÃO existe e causava erro 404, que o app escondia caindo nas sugestões locais). Se um dia o Google aposentar o modelo, basta trocar `GEMINI_MODEL` no `env.json`.

Como conferir que está ativo: Configurações > Ik AI > "Gemini (Google)" mostra "Ativo". Na versão avançada, a etapa "Ik AI" libera o interruptor; em modo debug, o console imprime o motivo quando o Gemini não responde (ex.: HTTP 404, chave inválida).
Limite conhecido: chave dentro do app é extraível. Serve para o TCC; para publicar, a chamada deve passar pelo back-end.

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
- **Botão flutuante da Ik AI**: sempre na tela, acima de todas as páginas, arrastável. Some sobre diálogos/menus e dentro da própria conversa.
- **Escrever artigo** (aba Comunidade > Meus artigos): objetivo, categoria, nível, título, resumo, texto, assuntos. Entra no feed e no Explorar da categoria escolhida, marcado como "(leitor)".
- **Criar comunidade**: nome, descrição, ícone, 1 a 5 categorias, regras. Dentro de cada comunidade há um **mural** (mensagens de 3 a 500 caracteres, sem curtidas). Quem escreveu apaga a própria mensagem; quem criou a comunidade apaga a comunidade e qualquer mensagem nela.
- Regras de validação (tamanhos, categoria válida, sem emojis, nome de comunidade único) ficam em `lib/services/conteudo_usuario.dart`, com 24 testes.
- **Pronto para o banco de dados**: o app só conhece a interface `ConteudoRepositorio`. Hoje `ConteudoLocal` guarda no aparelho (simula o banco; o conteúdo só existe neste aparelho). `lib/services/conteudo_remoto.dart` está TODO COMENTADO, com o esquema SQL sugerido, as rotas REST assumidas, as regras que o servidor deve repetir e a classe `ConteudoRemoto`. Para ligar: criar a API, descomentar o arquivo e trocar `ConteudoLocal()` por `ConteudoRemoto(...)` em `ConteudoUsuarioService.instance` (uma linha).
- Excluir a conta apaga também tudo o que a pessoa escreveu.

## Pilares mantidos
Feed finito; histórico só como sugestão (nunca aplicado sozinho); notificações desligadas por padrão; consentimento explícito para enviar algo ao Gemini (nome e e-mail nunca saem do aparelho); a Ik AI só reflete o que a pessoa declarou; gamificação só individual; sem emojis (teste varre `lib/`).

## Limitações e decisões a registrar no TCC
- A meta diária é **negociada**, não "intransponível": a pessoa pode pedir mais tempo, justificando. Mitigações: no máximo 2 prorrogações por dia, de até 30 min, com justificativa registrada, e o balanço semanal confronta o uso com a meta. Se a banca exigir bloqueio absoluto, é só definir `maxProrrogacoes = 0` em `tempo_diario.dart`.
- Os avisos (metade e fim) são **dentro do app**, não notificações do sistema operacional: com o app fechado nada é enviado (coerente com "notificações reduzidas"; push exigiria plugin e permissão).
- A contagem depende do relógio do aparelho: adiantar o relógio para o dia seguinte zera o dia. Só um servidor resolve.
- A interface nova (grade de categorias, tela de meta, avisos, botão flutuante, telas de conteúdo) **não pôde ser compilada** no ambiente onde foi escrita; a lógica está testada, as telas precisam rodar uma vez com `flutter run`. Se o analisador reclamar de algo, me envie a mensagem.
- Conteúdo criado por usuários é local até o banco existir; moderação (denúncia, bloqueio) fica para a fase do banco.
- Contas são de mentira, em memória; textos de privacidade e termos são preliminares; botões de login social só mostram aviso.

## Fundamentação (resumo)
- Planos "quando X, então Y": Gollwitzer & Sheeran (2006), meta-análise de 94 estudos (d = 0,65).
- Fricção antes de abrir apps reduz tentativas; pessoas tendem a desativar intervenções rígidas: Haliburton et al., CHI 2024. Por isso o limite é conversado, e não só imposto.
- A conversa segue a Entrevista Motivacional: refletir o que a pessoa disse, perguntar antes de presumir, deixar a escolha com ela.

## Adicionar mais artigos do app (sem banco)
Copie o modelo no topo de `lib/data/artigos_dados.dart`. Prompt para outra IA:

> Gere artigos originais em português do Brasil, sem emojis, no formato Dart abaixo. Cada artigo tem 3 a 5 parágrafos, fatos verificáveis, tom claro e calmo. Use categoriaId só destes: [cole os ids]. Continue a numeração a partir de a031. Inclua `nivel` (1 iniciante, 2 intermediário, 3 avançado) e varie os níveis dentro da mesma categoria. Devolva só o código.
> `Artigo(id: 'a031', objetivoId: '...', categoriaId: '...', nivel: 1, titulo: '...', autor: 'Equipe Ikai', resumo: '...', tags: ['...'], paragrafos: ['...'])`
