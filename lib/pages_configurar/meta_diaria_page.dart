import 'package:flutter/material.dart';

import '../core/uso_diario.dart';
import '../services/tempo_diario.dart';
import '../widgets/estilo.dart';
import 'destino_inicial.dart';

/// Primeiro uso: a pessoa diz quanto tempo pretende usar o Ikai por dia e
/// escolhe a versão do app. É uma meta DELA (o app não impõe um número) e
/// pode ser mudada depois: diminuir vale na hora, aumentar vale a partir do
/// dia seguinte.
class MetaDiariaPage extends StatefulWidget {
  const MetaDiariaPage({super.key});

  @override
  State<MetaDiariaPage> createState() => _MetaDiariaPageState();
}

class _MetaDiariaPageState extends State<MetaDiariaPage> {
  int _minutos = TempoDiarioService.metaPadrao;
  bool _avancado = false;

  void _confirmar() {
    final r = TempoDiarioService.instance.definirMeta(
      _minutos,
      avancado: _avancado,
    );
    if (r == ResultadoMeta.invalida) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => destinoInicial()),
      (rota) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Cores.fundoEtapas,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ListView(
                  children: [
                    const Text(
                      'Quanto tempo você quer usar o Ikai por dia?',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Cores.tituloVerde,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'A meta é sua. A Ik AI avisa quando você chegar na '
                      'metade e, no fim, conversa com você sobre o que '
                      'aprendeu. Você pode mudar isso depois.',
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.4,
                        color: Cores.subtitulo,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE0E5DF)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            formatarHm(_minutos * 60),
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Cores.laranja,
                            ),
                          ),
                          const Text(
                            'por dia',
                            style: TextStyle(
                              fontSize: 13,
                              color: Cores.subtitulo,
                            ),
                          ),
                          Slider(
                            value: _minutos.toDouble(),
                            min: TempoDiarioService.metaMinima.toDouble(),
                            max: TempoDiarioService.metaMaxima.toDouble(),
                            divisions:
                                (TempoDiarioService.metaMaxima -
                                    TempoDiarioService.metaMinima) ~/
                                5,
                            activeColor: Cores.laranja,
                            onChanged: (v) =>
                                setState(() => _minutos = (v / 5).round() * 5),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final m in TempoDiarioService.opcoesDeMeta)
                          ChoiceChip(
                            label: Text(formatarHm(m * 60)),
                            selected: _minutos == m,
                            selectedColor: const Color(0xFFE4EFE5),
                            onSelected: (_) => setState(() => _minutos = m),
                          ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'Qual versão combina com você?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Cores.tituloVerde,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _OpcaoVersao(
                      titulo: 'Iniciante',
                      descricao:
                          'Escolha o objetivo e as categorias e '
                          'pronto. Menos passos, nada para configurar.',
                      selecionada: !_avancado,
                      onTap: () => setState(() => _avancado = false),
                    ),
                    const SizedBox(height: 10),
                    _OpcaoVersao(
                      titulo: 'Avançado',
                      descricao:
                          'Inclui um lembrete de foco por leitura e '
                          'um espaço para contar à Ik AI o que você quer '
                          'fazer longe da tela.',
                      selecionada: _avancado,
                      onTap: () => setState(() => _avancado = true),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _confirmar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Cores.laranja,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Continuar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OpcaoVersao extends StatelessWidget {
  final String titulo;
  final String descricao;
  final bool selecionada;
  final VoidCallback onTap;

  const _OpcaoVersao({
    required this.titulo,
    required this.descricao,
    required this.selecionada,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selecionada ? const Color(0xFFE4EFE5) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selecionada ? Cores.laranja : const Color(0xFFE0E5DF),
            width: selecionada ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Cores.tituloVerde,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    descricao,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: Cores.subtitulo,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              selecionada ? Icons.check_circle : Icons.circle_outlined,
              color: selecionada ? Cores.laranja : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}
