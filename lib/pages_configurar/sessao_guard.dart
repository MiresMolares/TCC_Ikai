import 'dart:async';

import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/tempo_diario.dart';
import '../widgets/botao_ik_flutuante.dart';
import '../widgets/estilo.dart';
import '../widgets/navegador.dart';
import '../pages_home/ik_ai_page.dart';
import 'tela_fim_do_dia.dart';

/// Fica ACIMA do Navigator (ver MaterialApp.builder em main.dart).
///
/// Cuida de quatro coisas ligadas ao tempo do dia:
///  1. Conta o tempo só com o app à frente (pausa em segundo plano).
///  2. Mostra os avisos da Ik AI (metade da meta, lembrete de foco) sem
///     bloquear nada.
///  3. Quando a meta acaba, troca o app pela conversa de fim de tempo
///     ([TelaFimDoDia]); quando a pessoa encerra o dia, por [TelaEncerrado].
///  4. Mantém o botão flutuante da Ik AI sempre à mão.
///
/// Como está acima do Navigator, não há Overlay nem Navigator aqui: os
/// widgets daqui só usam Material, nunca Tooltip, diálogo ou menu.
class SessaoGuard extends StatefulWidget {
  final Widget child;

  const SessaoGuard({super.key, required this.child});

  @override
  State<SessaoGuard> createState() => _SessaoGuardState();
}

class _SessaoGuardState extends State<SessaoGuard>
    with WidgetsBindingObserver {
  final TempoDiarioService _t = TempoDiarioService.instance;

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

  /// Em segundo plano o tempo não conta; ao voltar, a contagem retoma.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (AuthService.instance.logado && _t.metaDefinida) {
        _t.iniciarContagem();
      }
    } else {
      _t.pausarContagem();
    }
  }

  void _abrirIkAi() => abrirIkAi();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        _t,
        AuthService.instance,
        NavegadorIk.observador.botaoPermitido,
      ]),
      builder: (context, _) {
        if (AuthService.instance.logado) {
          // O Navigator sai da árvore: nenhuma tela, diálogo ou menu aberto
          // sobrevive ao fim do tempo, e ele volta do zero depois.
          if (_t.fase == FaseDoDia.fimDeTempo) {
            NavegadorIk.observador.reiniciar();
            return const TelaFimDoDia();
          }
          if (_t.fase == FaseDoDia.encerrado) {
            NavegadorIk.observador.reiniciar();
            return const TelaEncerrado();
          }
        }

        final logado = AuthService.instance.logado;
        final tecladoAberto = MediaQuery.of(context).viewInsets.bottom > 0;
        final mostrarBotao = logado &&
            _t.metaDefinida &&
            NavegadorIk.observador.botaoPermitido.value &&
            !tecladoAberto;
        final aviso = logado ? _t.aviso : null;

        return Stack(
          children: [
            Positioned.fill(child: widget.child),
            if (aviso != null)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _BannerIk(
                  key: ValueKey('${aviso.tipo}-${aviso.texto}'),
                  aviso: aviso,
                  aoConversar: _abrirIkAi,
                ),
              ),
            if (mostrarBotao)
              Positioned.fill(child: BotaoIkFlutuante(aoTocar: _abrirIkAi)),
          ],
        );
      },
    );
  }
}

/// Aviso da Ik AI no topo da tela: some sozinho depois de alguns segundos,
/// e a pessoa pode dispensar ou conversar. Nunca bloqueia o app.
class _BannerIk extends StatefulWidget {
  final AvisoIk aviso;
  final VoidCallback aoConversar;

  const _BannerIk({super.key, required this.aviso, required this.aoConversar});

  @override
  State<_BannerIk> createState() => _BannerIkState();
}

class _BannerIkState extends State<_BannerIk> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 20), _dispensar);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _dispensar() => TempoDiarioService.instance.consumirAviso();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: Material(
          color: Cores.tituloVerde,
          elevation: 8,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.auto_awesome, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.aviso.texto,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        _dispensar();
                        widget.aoConversar();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Falar com a Ik AI'),
                    ),
                    TextButton(
                      onPressed: _dispensar,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Entendi'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
