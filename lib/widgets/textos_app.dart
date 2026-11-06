import 'package:flutter/material.dart';

import 'estilo.dart';

/// Textos de apoio do Ikai. São PRELIMINARES: antes de publicar o app,
/// os documentos de privacidade e termos precisam de revisão jurídica.
class TextosApp {
  TextosApp._();

  static const String ajuda = '''O que é o Ikai?
Um aplicativo para aprender e se desenvolver sem prender você na tela. O feed é finito e o tempo de uso é escolhido por você.

Como funciona uma sessão
Você escolhe o que quer ver, a categoria e por quanto tempo. Quando o tempo acaba, o aplicativo é bloqueado e você é levado a uma conversa com a Ik AI, que sugere várias opções de como usar sua energia fora da tela. O limite não pode ser estendido: para continuar, você espera a pausa entre as sessões (5 a 30 minutos, em Configurações) e começa uma nova sessão.

Feed finito
Cada sessão mostra uma quantidade fixa de conteúdos. Quando eles acabam, o feed acaba.

Biblioteca
Salve artigos em pastas que você mesmo cria. Um artigo pode estar em mais de uma pasta.

Ik AI
Você pode conversar com a Ik AI ao fim da sessão ou quando quiser, pela tela Início. Conte o que tem vontade, o que tem à mão (por exemplo, "estou sem meu livro"), quanto tempo e energia você tem, e ela mostra várias opções. Ao escolher uma, você combina o momento e, na próxima vez, ela pergunta como foi. Se você permitir, o que você escreve na conversa é enviado ao Gemini (Google); se não, as ideias são geradas no seu aparelho. A Ik AI não substitui ajuda profissional: em caso de sofrimento sério, ligue para o CVV (188) ou para o SAMU (192).

Notificações
Ficam desligadas por padrão. Você liga em Configurações, se quiser.

Problemas e sugestões
Reinicie o aplicativo e confira se há atualização. Se continuar, procure o canal oficial de suporte do Ikai.''';

  static const String privacidade = '''Seus dados no Ikai

O que é guardado no seu aparelho: sua biblioteca, seu progresso, seus combinados com a Ik AI e suas preferências, separados por conta.

O que é enviado a terceiros: somente se você ativar a opção na etapa "Ik AI" ou na conversa com a Ik AI, o que você escreveu, o modo da sessão e as condições que você contou (como "sem livro" ou "10 minutos") são enviados ao Gemini (Google). Mensagens que indicam sofrimento sério nunca são enviadas. Seu nome e seu e-mail nunca são enviados.

Anúncios: quando existirem, serão escolhidos pelo contexto do conteúdo, sem usar seus dados privados.

Exportar e excluir: em Configurações você pode exportar seus dados e excluir sua conta.''';

  static const String termos = '''Termos de uso

Ao usar o Ikai você concorda em usar o aplicativo de forma respeitosa, sem publicar conteúdo ofensivo ou ilegal e sem tentar burlar o limite de tempo das sessões.

Os artigos são de caráter informativo e educacional.

O Ikai pode mudar estes termos; mudanças relevantes serão avisadas no aplicativo.''';

  static const String sobre = '''Ikai

Um companheiro de evolução pessoal de baixa dopamina: feed finito, tempo definido por você e sugestões da Ik AI para levar sua energia para fora da tela.

Projeto de Trabalho de Conclusão de Curso.''';
}

/// Página simples que mostra um dos textos acima.
class PaginaTexto extends StatelessWidget {
  final String titulo;
  final String texto;
  final bool preliminar;

  const PaginaTexto({
    super.key,
    required this.titulo,
    required this.texto,
    this.preliminar = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Cores.fundo,
      appBar: AppBar(title: Text(titulo), backgroundColor: Cores.fundo),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (preliminar)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Cores.rosado,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Texto preliminar, ainda sem revisão jurídica.',
                  style: TextStyle(fontSize: 12, color: Cores.titulo),
                ),
              ),
            Text(
              texto,
              style: const TextStyle(
                fontSize: 14,
                height: 1.7,
                color: Cores.titulo,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
