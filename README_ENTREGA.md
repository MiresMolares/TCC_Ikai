# Ikai - entrega da evolução (iniciante para entregável)

## Como aplicar no projeto (Antigravity ou à mão)
1. Na raiz do projeto, APAGUE a pasta `lib/` e a pasta `test/` e copie as deste pacote no lugar.
2. Substitua o `pubspec.yaml` (única mudança: `http: ^1.2.0` nas dependências). Mantenha a pasta `assets/`.
3. `flutter pub get`
4. Rodar sem Gemini (sugestões geradas no aparelho):
   `flutter run`
5. Rodar com Gemini:
   `flutter run --dart-define=GEMINI_API_KEY=SUA_CHAVE`
   (opcional: `--dart-define=GEMINI_MODEL=nome-do-modelo`; padrão `gemini-3.6-flash`)
6. `flutter test` (12 arquivos, 190 testes de lógica).

Conta de teste: `adm@email.com` / `1234`.

## O que mudou, por ponto do pedido
1. **Emojis**: não havia emojis no código original. Mesmo assim: texto da Ik AI passa por filtro (`core/sem_emoji.dart`), a instrução ao Gemini proíbe emojis e um teste varre todo `lib/` e falha se algum aparecer.
2. **Tempo de uso + Gemini**: fluxo de 4 etapas (objetivo, categoria, duração, Ik AI). A sessão começa ao confirmar e vai direto à Home. O relógio usa o maior entre relógio do celular e cronômetro interno: voltar a hora não ganha tempo e celular dormindo conta. Ao acabar, `SessaoGuard` (acima do Navigator) troca o app inteiro pela tela "Seu tempo acabou!", sem botão voltar. A Ik AI mostra 3 sugestões a partir do que a pessoa escreveu (ex.: Capitães da Areia, treino, francês). Gemini só com consentimento explícito (desligado por padrão) e nome/e-mail nunca são enviados; sem chave, sem internet ou com erro, sugestões locais.
3. **Tela base funcional**: Início (feed finito de 8 artigos, filtro por assunto, fim do feed), Explorar (busca dentro do modo), Comunidade (4 de exemplo), Progresso, Perfil, Biblioteca (pastas), Notificações, Configurações, tela de artigo com "Concluir leitura". 30 artigos originais em `lib/data/artigos_dados.dart`.
4. **Erros de lógica corrigidos**: sessão podia ser estendida; sem proteção contra mudar a hora; dados de um usuário apareciam para outro (agora tudo é por e-mail); "Sair" não saía; botões sem função; nome fixo na Home; ids de categoria duplicados/errados; telas temporárias removidas.

## Segunda rodada de melhorias
- **`lib/services/ik_ai_service.dart` refeito** (mesmos nomes de método do arquivo do Antigravity, então as telas que o chamam continuam compilando). Mudou: sem dados inventados (acabou o "Paixão Segundo GH" e o "Caio" padrão); o Gemini só é usado no fim do tempo e só com autorização, sem nome nem e-mail (o nome é colocado na frase no aparelho); pergunta do cadastro, confirmação e "sugerir outra coisa" são locais e não gastam cota; "guardei na memória" agora é verdade (grava por conta, apaga ao excluir a conta, entra na exportação de dados); sem esperas falsas; texto do usuário sem emojis e limitado a 300 caracteres; nada fica em variável global entre contas. O pacote `google_generative_ai` não é mais usado: pode sair do pubspec.
- **Limite de tempo vale mesmo fechando o app**: a sessão é gravada; reabrir, sair da conta e entrar de novo, ou voltar a hora do celular não dá tempo novo. Se o tempo acabou com o app fechado, a tela de bloqueio aparece ao entrar. Só "Iniciar nova sessão" libera outra.
- **Falhas do Gemini não ficam escondidas**: em modo debug a tela final mostra o motivo de ter usado sugestões locais (ex.: "Gemini respondeu HTTP 404 (modelo ...)").
- **Nível de dificuldade** (Iniciante, Intermediário, Avançado ou Todos) escolhido pelo usuário na Início e no Explorar, salvo no aparelho. Novo campo `nivel` em cada artigo.

## Terceira rodada: a Ik AI virou um chat, e o detox ficou de verdade
**Problema relatado:** a sugestão era uma só ("leia"), a Ik AI não aparecia no app e nada obrigava a pausa.

**O que mudou**
- **Quando o tempo acaba, a pessoa cai no chat da Ik AI** (tela de bloqueio redesenhada). A Ik AI abre refletindo só o que a pessoa declarou e mostra **3 opções reais**, em cartões com tempo e nível de energia. Em cada cartão: "Vou fazer isso". Em baixo: respostas rápidas ("Não tenho meu livro", "Estou cansado", "Tenho 10 minutos", "Estou fora de casa", "Quero outra ideia") e campo de texto livre.
- **"Mas e se eu não estiver com meu livro?"**: o app entende frases como "não tenho meu livro", "esqueci o livro", "sem caneta", "tenho meia hora", "estou cansado", "estou na rua" e refaz as opções. Sem o livro ainda há leitura: contar a história de um livro de memória, resumir por escrito, ler qualquer texto impresso, pegar um livro emprestado. São ~38 atividades em 11 temas (`lib/core/atividades.dart`), com filtro por material, minutos, energia e lugar. "Outra ideia" nunca repete uma ideia já mostrada; quando acabam, a Ik AI diz isso e sugere descansar, sem inventar.
- **Funciona sem internet, sem chave e sem autorização**: o motor local (`lib/core/motor_ik_ai.dart`) responde sempre. O Gemini é opcional (interruptor na própria conversa): quando liga, ele conversa e propõe ideias novas; se falhar, o motor local assume. O Gemini recebe só o que a pessoa escreveu e as condições que ela contou. Nome e e-mail nunca saem do aparelho.
- **Combinado "quando X, então Y"**: ao escolher uma ideia, a Ik AI pergunta *quando* a pessoa começa. Isso vira um combinado salvo por conta (`CompromissoService`). Na próxima vez que o app abrir (Início ou escolha da sessão), aparece um check-in sem cobrança: "Fiz / Fiz um pouco / Não consegui". O Progresso mostra o resumo, só para a própria pessoa.
- **Pausa obrigatória entre sessões** (5, 10, 15 ou 30 min; padrão 10; não pode ser desligada): o botão "Nova sessão em mm:ss" fica travado. A pausa é gravada: fechar o app, sair da conta ou voltar a hora do celular não a encurta. O tempo em que o app ficou fechado depois do fim da sessão conta como pausa.
- **Conversa livre**: cartão "Conversar com a Ik AI" na Início, para pedir ideias a qualquer momento.
- **Segurança**: mensagens com sinais de sofrimento sério (ex.: querer se machucar) não recebem ideias nem vão para o Gemini; a Ik AI encaminha para o CVV (188) e o SAMU (192). Textos de ajuda e privacidade foram atualizados.

**Fundamentação**
- Planos "quando X, então Y" (intenções de implementação) aumentam a chance de cumprir uma meta: Gollwitzer & Sheeran (2006), meta-análise de 94 estudos, efeito médio a grande (d = 0,65).
- Pequenas fricções antes de abrir apps reduzem tentativas de abertura, e as pessoas tendem a desativar intervenções: Haliburton et al., CHI 2024 (estudo com usuários do one sec). Por isso a pausa não tem opção "desligar".
- A conversa segue a lógica da Entrevista Motivacional: refletir o que a pessoa disse, perguntar antes de presumir, deixar a escolha com ela.

## Adicionar mais artigos (sem banco de dados)
Copie o modelo no topo de `lib/data/artigos_dados.dart`. Prompt para outra IA:

> Gere artigos originais em português do Brasil, sem emojis, no formato Dart abaixo. Cada artigo tem 3 a 5 parágrafos, fatos verificáveis, tom claro e calmo. Use categoriaId só destes: [cole os ids]. Continue a numeração a partir de a031. Inclua `nivel` (1 iniciante, 2 intermediário, 3 avançado) e varie os níveis dentro da mesma categoria. Devolva só o código.
> `Artigo(id: 'a031', objetivoId: '...', categoriaId: '...', nivel: 1, titulo: '...', autor: 'Equipe Ikai', resumo: '...', tags: ['...'], paragrafos: ['...'])`

## Limitações conhecidas
- A chave do Gemini no app é insegura para produção: publique via back-end (proxy).
- A pausa e o limite dependem do relógio do aparelho: ADIANTAR a hora do celular pode encurtar a pausa (voltar a hora não adianta). Só um servidor resolve isso de vez.
- A interface nova (chat, tela de bloqueio, check-in) não pôde ser compilada no ambiente onde foi escrita: a lógica está testada, a tela precisa ser rodada uma vez com `flutter run`.
- Contas são de mentira, em memória; "recuperar senha" não envia e-mail de verdade.
- Textos de privacidade e termos são preliminares.
- Botões de login social só mostram aviso.
