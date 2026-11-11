import 'package:flutter/material.dart';

import '../services/chat_fabrica.dart';
import '../services/chat_ik_ai.dart';
import '../widgets/estilo.dart';
import '../widgets/ik_ai_chat_view.dart';
import '../widgets/navegador.dart';

/// Abre a conversa livre com a Ik AI por cima de qualquer tela. A rota tem
/// nome para o botão flutuante saber que deve se esconder aqui.
Future<void>? abrirIkAi() => NavegadorIk.abrir<void>(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: NavegadorIk.rotaIkAi),
        builder: (context) => const IkAiPage(),
      ),
    );

/// Conversa livre com a Ik AI: para quem quer ideias do que fazer longe da
/// tela a qualquer momento, não só quando o tempo acaba.
class IkAiPage extends StatefulWidget {
  const IkAiPage({super.key});

  @override
  State<IkAiPage> createState() => _IkAiPageState();
}

class _IkAiPageState extends State<IkAiPage> {
  late final ChatIkAi _chat;

  @override
  void initState() {
    super.initState();
    _chat = novoChatIkAi(ocasiao: 'livre');
  }

  @override
  void dispose() {
    _chat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Cores.fundoEtapas,
      appBar: AppBar(
        title: const Text('Ik AI'),
        backgroundColor: Cores.fundo,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: IkAiChatView(chat: _chat),
          ),
        ),
      ),
    );
  }
}
