import 'package:flutter/material.dart';

import '../core/uso_diario.dart';
import '../services/acoes_fim_do_dia.dart';
import '../services/chat_fabrica.dart';
import '../services/chat_ik_ai.dart';
import '../services/tempo_diario.dart';
import '../widgets/estilo.dart';
import '../widgets/ik_ai_chat_view.dart';
import '../widgets/paisagem.dart';

/// O tempo do dia acabou (ou a pessoa pediu para encerrar): a Ik AI abre uma
/// conversa. Lá a pessoa conta o que aprendeu, justifica mais um pouco de
/// tempo (no máximo duas vezes por dia, e fica registrado) ou encerra o dia.
///
/// Fica ACIMA do Navigator (veja SessaoGuard): tem o próprio Overlay, que o
/// campo de texto exige, e não abre diálogos nem menus.
class TelaFimDoDia extends StatefulWidget {
  const TelaFimDoDia({super.key});

  @override
  State<TelaFimDoDia> createState() => _TelaFimDoDiaState();
}

class _TelaFimDoDiaState extends State<TelaFimDoDia> {
  late final ChatIkAi _chat;
  final _t = TempoDiarioService.instance;

  @override
  void initState() {
    super.initState();
    _chat = novoChatIkAi(
      ocasiao: 'fim',
      minutosUsados: (_t.usadoHojeSeg / 60).round(),
      fimDoDia: AcoesFimDoDiaReais(_t),
    );
  }

  @override
  void dispose() {
    _chat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final voluntario = _t.fimVoluntario;
    return Overlay.wrap(
      child: Scaffold(
        backgroundColor: Cores.fundoEtapas,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                children: [
                  PaisagemView(
                    paisagem: Paisagem.entardecer,
                    altura: 180,
                    raio: const BorderRadius.vertical(
                      bottom: Radius.circular(28),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.hourglass_bottom_rounded,
                            size: 36,
                            color: Color(0xFF7A3418),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  voluntario
                                      ? 'Encerrar por hoje?'
                                      : 'Seu tempo de hoje acabou',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF5A2418),
                                  ),
                                ),
                                Text(
                                  'Você usou ${formatarHm(_t.usadoHojeSeg)} '
                                  'de ${formatarHm(_t.limiteHojeSeg)} hoje.',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF5A2418),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(child: IkAiChatView(chat: _chat)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// O dia foi encerrado: o app só volta amanhã. Mostra o que a pessoa
/// registrou hoje, sem empurrar nada.
class TelaEncerrado extends StatelessWidget {
  const TelaEncerrado({super.key});

  @override
  Widget build(BuildContext context) {
    final t = TempoDiarioService.instance;
    final hoje = chaveDoDia(DateTime.now());
    final aprendi = [
      for (final r in t.reflexoes)
        if (r.dia == hoje && r.tipo == 'aprendi') r.texto,
    ];

    return Overlay.wrap(
      child: Scaffold(
        backgroundColor: const Color(0xFF1A3446),
        body: PaisagemView(
          paisagem: Paisagem.noite,
          ajuste: AjustePaisagem.largura,
          child: SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 64, 28, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.nights_stay_outlined,
                        size: 48,
                        color: Color(0xFFF4EFD6),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Por hoje é só',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFF4EFD6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Você usou ${formatarHm(t.usadoHojeSeg)} hoje. '
                        'Amanhã o Ikai estará aqui, com a sua meta de '
                        '${t.metaMin} min.',
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.4,
                          color: Color(0xFFD5DCD8),
                        ),
                      ),
                      if (aprendi.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        const Text(
                          'O que você contou que aprendeu hoje',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFF4EFD6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        for (final a in aprendi.take(3))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '"$a"',
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.4,
                                color: Color(0xFFD5DCD8),
                              ),
                            ),
                          ),
                      ],
                      const SizedBox(height: 24),
                      const Text(
                        'Você pode fechar o app. Descansar a tela também é '
                        'parte do método.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFFB7C3C2),
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
    );
  }
}
