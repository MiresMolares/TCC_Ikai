import 'package:flutter/material.dart';

import '../data/artigo.dart';
import '../services/config_service.dart';
import 'estilo.dart';

/// O usuário escolhe a dificuldade; o app nunca decide por ele.
class SeletorNivel extends StatelessWidget {
  const SeletorNivel({super.key});

  @override
  Widget build(BuildContext context) {
    final cfg = ConfigService.instance;
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text(
          'Nível:',
          style: TextStyle(fontSize: 13, color: Cores.subtitulo),
        ),
        for (var n = 0; n <= Artigo.nivelMaximo; n++)
          ChoiceChip(
            label: Text(Artigo.nomeDoNivel(n)),
            selected: cfg.nivelConteudo == n,
            onSelected: (_) => cfg.definirNivelConteudo(n),
          ),
      ],
    );
  }
}
