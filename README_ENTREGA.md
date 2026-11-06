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
6. `flutter test` (9 arquivos, 118 testes de lógica).

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

## Adicionar mais artigos (sem banco de dados)
Copie o modelo no topo de `lib/data/artigos_dados.dart`. Prompt para outra IA:

> Gere artigos originais em português do Brasil, sem emojis, no formato Dart abaixo. Cada artigo tem 3 a 5 parágrafos, fatos verificáveis, tom claro e calmo. Use categoriaId só destes: [cole os ids]. Continue a numeração a partir de a031. Inclua `nivel` (1 iniciante, 2 intermediário, 3 avançado) e varie os níveis dentro da mesma categoria. Devolva só o código.
> `Artigo(id: 'a031', objetivoId: '...', categoriaId: '...', nivel: 1, titulo: '...', autor: 'Equipe Ikai', resumo: '...', tags: ['...'], paragrafos: ['...'])`

## Limitações conhecidas
- A chave do Gemini no app é insegura para produção: publique via back-end (proxy).
- Ainda não há pausa mínima obrigatória entre sessões: depois do bloqueio, "Iniciar nova sessão" libera outra na hora.
- Contas são de mentira, em memória; "recuperar senha" não envia e-mail de verdade.
- Textos de privacidade e termos são preliminares.
- Botões de login social só mostram aviso.
