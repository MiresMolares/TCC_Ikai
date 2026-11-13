import 'package:flutter/material.dart';

import '../core/uso_diario.dart';
import '../services/tempo_diario.dart';
import 'estilo.dart';

/// Barras simples dos últimos 7 dias (do mais antigo para hoje), com a meta
/// marcada. Só números do próprio usuário.
class BarrasDaSemana extends StatelessWidget {
  final ResumoSemanal resumo;
  const BarrasDaSemana({super.key, required this.resumo});

  @override
  Widget build(BuildContext context) {
    final maior = [
      resumo.maiorDiaSeg,
      resumo.metaSeg,
      1,
    ].reduce((a, b) => a > b ? a : b);
    const altura = 72.0;
    final metaY = altura * (resumo.metaSeg / maior);
    final hoje = DateTime.now();

    String letra(int i) {
      // porDia[6] é hoje; porDia[0] é 6 dias atrás.
      final d = hoje.subtract(Duration(days: 6 - i));
      const nomes = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];
      return nomes[d.weekday - 1];
    }

    return SizedBox(
      height: altura + 22,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 22 + metaY,
            child: Container(height: 1, color: Cores.verde.withAlpha(120)),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < resumo.porDia.length; i++)
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 18,
                        height: (altura * (resumo.porDia[i] / maior))
                            .clamp(resumo.porDia[i] > 0 ? 3.0 : 0.0, altura)
                            .toDouble(),
                        decoration: BoxDecoration(
                          color: resumo.porDia[i] > resumo.metaSeg
                              ? Cores.laranja
                              : Cores.verde,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        letra(i),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: i == 6
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: Cores.subtitulo,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Mostra o uso da pessoa e pergunta "o que você tem a dizer sobre o seu
/// algoritmo?". Só aparece para quem já usa de forma recorrente. Uma
/// resposta por semana; depois mostra só os números e o que ela respondeu.
class CartaoUsoSemanal extends StatefulWidget {
  /// true: mostra também as barras (usado na tela de progresso).
  final bool comBarras;
  const CartaoUsoSemanal({super.key, this.comBarras = false});

  @override
  State<CartaoUsoSemanal> createState() => _CartaoUsoSemanalState();
}

class _CartaoUsoSemanalState extends State<CartaoUsoSemanal> {
  final _t = TempoDiarioService.instance;
  final _comentario = TextEditingController();
  RespostaBalanco? _escolhida;

  @override
  void dispose() {
    _comentario.dispose();
    super.dispose();
  }

  void _registrar() {
    final r = _escolhida;
    if (r == null) return;
    _t.registrarBalanco(r, texto: _comentario.text);
    _comentario.clear();
    setState(() => _escolhida = null);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _t,
      builder: (context, _) {
        if (!_t.metaDefinida || !_t.usoRecorrente) {
          return const SizedBox.shrink();
        }
        final resumo = _t.resumoSemanal;
        final dentro = resumo.mediaDentroDaMeta;
        final feito = _t.balancoDestaSemana;

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: dentro ? Cores.verdeClaro : Cores.rosado,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: dentro ? Cores.verde : Cores.laranja),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Seu tempo no Ikai',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Cores.tituloVerde,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                resumo.texto,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: Cores.tituloVerde,
                ),
              ),
              if (widget.comBarras) ...[
                const SizedBox(height: 14),
                BarrasDaSemana(resumo: resumo),
                const SizedBox(height: 4),
                Text(
                  'A linha marca a sua meta de ${formatarHm(resumo.metaSeg)}.',
                  style: const TextStyle(fontSize: 11, color: Cores.subtitulo),
                ),
              ],
              const SizedBox(height: 12),
              if (feito != null)
                Text(
                  'Nesta semana você respondeu: ${nomeDoBalanco(feito.resposta)}.'
                  '${feito.texto.isEmpty ? '' : ' "${feito.texto}"'}',
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: Cores.subtitulo,
                  ),
                )
              else ...[
                const Text(
                  'O que você tem a dizer sobre o seu algoritmo? Você sente '
                  'que está ganhando tempo com o Ikai?',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                    color: Cores.tituloVerde,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final r in RespostaBalanco.values)
                      ChoiceChip(
                        label: Text(nomeDoBalanco(r)),
                        selected: _escolhida == r,
                        selectedColor: Colors.white,
                        onSelected: (_) => setState(() => _escolhida = r),
                      ),
                  ],
                ),
                if (_escolhida != null) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: _comentario,
                    maxLength: 200,
                    maxLines: 2,
                    minLines: 1,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Quer explicar? (opcional)',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Cores.borda),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: _registrar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Cores.laranja,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Registrar'),
                    ),
                  ),
                ],
              ],
            ],
          ),
        );
      },
    );
  }
}
