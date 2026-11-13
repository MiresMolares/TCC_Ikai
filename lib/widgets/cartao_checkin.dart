import 'package:flutter/material.dart';

import '../services/compromisso_service.dart';
import 'estilo.dart';

/// Pergunta, sem cobrança, como foi o combinado feito com a Ik AI na última
/// vez. Some quando não há combinado esperando resposta.
class CartaoCheckIn extends StatelessWidget {
  const CartaoCheckIn({super.key});

  @override
  Widget build(BuildContext context) {
    final servico = CompromissoService.instance;
    return ListenableBuilder(
      listenable: servico,
      builder: (context, _) {
        final p = servico.pendente;
        if (p == null) return const SizedBox.shrink();
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Cores.verdeClaro,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Cores.verde),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Seu combinado com a Ik AI',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Cores.tituloVerde,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Você combinou "${p.quando}": ${p.titulo}. Como foi?',
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: Cores.tituloVerde,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final r in RespostaCombinado.values)
                    OutlinedButton(
                      onPressed: () => servico.responder(p.id, r),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Cores.verde,
                        side: const BorderSide(color: Cores.verde),
                      ),
                      child: Text(nomeDaResposta(r)),
                    ),
                  TextButton(
                    onPressed: servico.descartarPendente,
                    child: const Text('Dispensar'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Não existe resposta errada. Isso fica só no seu aparelho.',
                style: TextStyle(fontSize: 11, color: Cores.subtitulo),
              ),
            ],
          ),
        );
      },
    );
  }
}
