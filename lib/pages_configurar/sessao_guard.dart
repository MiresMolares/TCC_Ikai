import 'dart:async';
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

import '../services/chat_fabrica.dart';
import '../services/chat_ik_ai.dart';
import '../widgets/estilo.dart';
import '../widgets/ik_ai_chat_view.dart';
import 'controle_objetivo.dart';

/// Fica ACIMA do Navigator (ver MaterialApp.builder em main.dart).
///
/// Quando a sessão expira, o Navigator inteiro sai da árvore e entra a
/// [TelaBloqueio]. Assim nenhuma tela, diálogo ou menu aberto sobrevive ao
/// fim do tempo, e não existe botão "voltar" para burlar o limite.
/// Ao iniciar nova sessão o Navigator é recriado do zero.
class SessaoGuard extends StatefulWidget {
  final Widget child;

  const SessaoGuard({super.key, required this.child});

  @override
  State<SessaoGuard> createState() => _SessaoGuardState();
}

class _SessaoGuardState extends State<SessaoGuard>
    with WidgetsBindingObserver {
  final ControleObjetivos _c = ControleObjetivos.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Timers pausam em segundo plano; ao voltar, o relógio é conferido na hora.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _c.verificar();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _c,
      builder: (context, _) {
        if (_c.estado == EstadoSessao.expirada) {
          return const TelaBloqueio();
        }
        return widget.child;
      },
    );
  }
}

/// Mostra o tempo restante em formato de relógio (mm:ss ou h:mm:ss).
class TempoRestante extends StatelessWidget {
  final TextStyle? estilo;

  const TempoRestante({super.key, this.estilo});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Duration>(
      valueListenable: ControleObjetivos.instance.restante,
      builder: (context, restante, _) => Text(
        formatarRelogio(restante),
        style: estilo ??
            const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Cores.tituloVerde,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
      ),
    );
  }
}

/// Tela exibida quando a sessão acaba: a pessoa é levada à conversa com a
/// Ik AI, que oferece várias opções reais do que fazer longe da tela e
/// aceita o que ela disser (por exemplo, "não estou com meu livro").
///
/// A pausa entre sessões é obrigatória: o botão de nova sessão só abre
/// quando a contagem chega a zero.
///
/// Esta tela fica ACIMA do Navigator, por isso tem o próprio Overlay (o campo
/// de texto precisa de um) e não abre diálogos nem menus.
class TelaBloqueio extends StatefulWidget {
  const TelaBloqueio({super.key});

  @override
  State<TelaBloqueio> createState() => _TelaBloqueioState();
}

class _TelaBloqueioState extends State<TelaBloqueio> {
  late final ChatIkAi _chat;
  Timer? _timer;
  ResumoSessao? _resumo;

  @override
  void initState() {
    super.initState();
    final c = ControleObjetivos.instance;
    _resumo = c.ultimoResumo;
    final r = _resumo;
    _chat = novoChatIkAi(
      ocasiao: 'fim',
      resumo: r,
      minutosUsados: r == null ? 0 : (r.usadoSegundos / 60).round(),
    );
    c.atualizarPausa();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => c.atualizarPausa(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _chat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = _resumo;
    final peloUsuario = r?.encerradaPeloUsuario ?? false;

    return PopScope(
      canPop: false,
      child: Overlay.wrap(
        child: Scaffold(
          backgroundColor: Cores.fundoEtapas,
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  children: [
                    _cabecalho(r, peloUsuario),
                    Expanded(child: IkAiChatView(chat: _chat)),
                    _rodape(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _cabecalho(ResumoSessao? r, bool peloUsuario) {
    final detalhe = r == null
        ? 'Bom descanso da tela.'
        : 'Você usou ${formatarDuracao(r.usadoSegundos)} em '
            '${r.categoriaTitulo}.';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        children: [
          const Icon(
            Icons.hourglass_bottom_rounded,
            size: 36,
            color: Cores.laranja,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  peloUsuario ? 'Sessão encerrada' : 'Seu tempo acabou',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Cores.tituloVerde,
                  ),
                ),
                Text(
                  detalhe,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Cores.subtitulo,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rodape() {
    final c = ControleObjetivos.instance;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Cores.bordaQuente)),
      ),
      child: ValueListenableBuilder<Duration>(
        valueListenable: c.pausaRestante,
        builder: (context, pausa, _) {
          final emPausa = pausa > Duration.zero;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: emPausa ? null : c.iniciarNovaSessao,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Cores.laranja,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    emPausa
                        ? 'Nova sessão em ${formatarRelogio(pausa)}'
                        : 'Iniciar nova sessão',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
              if (emPausa)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(
                    'Uma pausa entre as sessões ajuda a fazer algo fora da '
                    'tela de verdade.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Cores.subtitulo),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
