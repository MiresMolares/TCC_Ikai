import 'package:flutter/material.dart';

import 'estilo.dart';

/// Textos de apoio do Ikai. São PRELIMINARES: antes de publicar o app,
/// os documentos de privacidade e termos precisam de revisão jurídica.
class TextosApp {
  TextosApp._();

  static const String ajuda = '''O que é o Ikai?
Um aplicativo para aprender e se desenvolver sem prender você na tela. O feed é finito e a meta de tempo é sua.

Sua meta diária
No primeiro uso você diz quanto tempo quer usar o Ikai por dia. A Ik AI avisa quando você chega na metade. No fim, ela abre uma conversa: você conta o que aprendeu, pode pedir mais um pouco de tempo explicando por quê (até duas vezes por dia, e o motivo fica registrado) ou encerrar o dia. Diminuir a meta vale na hora; aumentar vale a partir de amanhã. Você muda a meta em Configurações.

Seu tempo, sempre à vista
Quem já usa com frequência vê, ao abrir o app, quanto usou nos últimos dias, a média por dia e se está dentro da meta, e responde se sente que está ganhando tempo. Esses números são só seus.

Versões
Iniciante: escolha o objetivo e as categorias (uma ou várias). Avançada: inclui um lembrete de foco por leitura e um espaço para contar à Ik AI o que você quer fazer longe da tela. Você troca em Configurações.

Feed finito
O feed mostra uma quantidade fixa de conteúdos por dia, não importa quantas categorias você escolha. Quando eles acabam, o feed acaba.

Escrever e comunidades
Você pode escrever artigos e criar comunidades na aba Comunidade, e escrever mensagens no mural das comunidades. Por enquanto, o que você cria fica só neste aparelho; com o banco de dados, passará a ser visto por outras pessoas.

Biblioteca
Salve artigos em pastas que você mesmo cria. Um artigo pode estar em mais de uma pasta.

Ik AI
Você pode conversar com a Ik AI quando quiser, pelo botão flutuante que fica sempre na tela (você pode arrastá-lo), e ela também conversa com você no fim do seu tempo do dia. Conte o que tem vontade, o que tem à mão (por exemplo, "estou sem meu livro"), quanto tempo e energia você tem, e ela mostra várias opções. Ao escolher uma, você combina o momento e, na próxima vez, ela pergunta como foi. Se você permitir, o que você escreve na conversa é enviado ao Gemini (Google); se não, as ideias são geradas no seu aparelho. A Ik AI não substitui ajuda profissional: em caso de sofrimento sério, ligue para o CVV (188) ou para o SAMU (192).

Notificações
Ficam desligadas por padrão. Você liga em Configurações, se quiser.

Problemas e sugestões
Reinicie o aplicativo e confira se há atualização. Se continuar, procure o canal oficial de suporte do Ikai.''';

  static const String privacidade = '''Seus dados no Ikai

O que é guardado no seu aparelho: sua biblioteca, seu progresso, seus combinados com a Ik AI, seu tempo de uso por dia, suas respostas sobre o que aprendeu e sobre ganhar ou perder tempo, os artigos, comunidades e mensagens que você criou e suas preferências, separados por conta.

O que é enviado a terceiros: somente se você ativar a opção na etapa "Ik AI" ou na conversa com a Ik AI, o que você escreveu, o modo e as categorias que você escolheu e as condições que você contou (como "sem livro" ou "10 minutos") são enviados ao Gemini (Google). Mensagens que indicam sofrimento sério nunca são enviadas. Seu nome e seu e-mail nunca são enviados.

Anúncios: quando existirem, serão escolhidos pelo contexto do conteúdo, sem usar seus dados privados.

Exportar e excluir: em Configurações você pode exportar seus dados e excluir sua conta.''';

  static const String termos = '''Termos de uso

Ao usar o Ikai você concorda em usar o aplicativo de forma respeitosa, sem publicar conteúdo ofensivo ou ilegal e sem tentar burlar a sua própria meta de tempo. Mensagens, artigos e comunidades que você criar devem respeitar as outras pessoas.

Os artigos são de caráter informativo e educacional.

O Ikai pode mudar estes termos; mudanças relevantes serão avisadas no aplicativo.''';

  static const String sobre = '''Ikai

Um companheiro de evolução pessoal de baixa dopamina: feed finito, meta de tempo definida por você e sugestões da Ik AI para levar sua energia para fora da tela.

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
