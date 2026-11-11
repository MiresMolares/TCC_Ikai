import 'package:flutter/material.dart';

import 'estilo.dart';

/// Botão fixo e suspenso da Ik AI. Fica sempre na tela (acima de todas as
/// páginas) e pode ser arrastado para onde atrapalhar menos; a posição vale
/// enquanto o app está aberto. Fica ACIMA do Navigator, então não usa
/// Tooltip nem nada que dependa de Overlay.
class BotaoIkFlutuante extends StatefulWidget {
  final VoidCallback aoTocar;
  const BotaoIkFlutuante({super.key, required this.aoTocar});

  static const double tamanho = 60;

  @override
  State<BotaoIkFlutuante> createState() => _BotaoIkFlutuanteState();
}

class _BotaoIkFlutuanteState extends State<BotaoIkFlutuante> {
  // Posição como fração do espaço livre (0 a 1), para sobreviver a giros de
  // tela. Começa no canto inferior direito, acima da barra de navegação.
  static double _fx = 1;
  static double _fy = 0.86;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, caixa) {
        const t = BotaoIkFlutuante.tamanho;
        const margem = 12.0;
        final livreX = (caixa.maxWidth - t - 2 * margem).clamp(0.0, 1e6);
        final livreY = (caixa.maxHeight - t - 2 * margem).clamp(0.0, 1e6);
        final x = margem + livreX * _fx;
        final y = margem + livreY * _fy;

        return Stack(
          children: [
            Positioned(
              left: x,
              top: y,
              child: GestureDetector(
                onPanUpdate: (d) {
                  setState(() {
                    if (livreX > 0) {
                      _fx = (_fx + d.delta.dx / livreX).clamp(0.0, 1.0);
                    }
                    if (livreY > 0) {
                      _fy = (_fy + d.delta.dy / livreY).clamp(0.0, 1.0);
                    }
                  });
                },
                child: Semantics(
                  button: true,
                  label: 'Conversar com a Ik AI',
                  child: Material(
                    color: Cores.laranja,
                    shape: const CircleBorder(),
                    elevation: 6,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: widget.aoTocar,
                      child: const SizedBox(
                        width: t,
                        height: t,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              color: Colors.white,
                              size: 24,
                            ),
                            Text(
                              'Ik AI',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
