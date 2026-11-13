import 'package:flutter/material.dart';

import '../../services/config_service.dart';
import '../../widgets/estilo.dart';

/// Caixa de notificações. Por padrão o Ikai não envia notificações
/// (Pilar 2), então normalmente esta tela está vazia de propósito.
class NotificacaoPage extends StatelessWidget {
  const NotificacaoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ligadas = ConfigService.instance.notificacoes;
    return Scaffold(
      backgroundColor: Cores.fundo,
      appBar: AppBar(
        title: const Text('Notificações'),
        backgroundColor: Cores.fundo,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                ligadas
                    ? Icons.notifications_none_rounded
                    : Icons.notifications_off_outlined,
                size: 56,
                color: Cores.verde,
              ),
              const SizedBox(height: 16),
              Text(
                ligadas
                    ? 'Nenhuma notificação por enquanto'
                    : 'As notificações estão desligadas',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Cores.titulo,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                ligadas
                    ? 'Quando houver algo importante, ele aparece aqui, '
                        'sem alertas insistentes.'
                    : 'O Ikai só avisa você se você quiser. Para ligar, '
                        'vá em Perfil, Configurações.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Cores.subtitulo),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
