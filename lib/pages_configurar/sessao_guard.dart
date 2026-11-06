import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

import '../services/gemini_service.dart';
import '../widgets/estilo.dart';
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

/// Tela exibida quando a sessão acaba. A Ik AI sugere como redirecionar a
/// energia, usando só o que o usuário escreveu na etapa "Ik AI".
class TelaBloqueio extends StatefulWidget {
  const TelaBloqueio({super.key});

  @override
  State<TelaBloqueio> createState() => _TelaBloqueioState();
}

class _TelaBloqueioState extends State<TelaBloqueio> {
  Future<SugestoesIkAi>? _sugestoes;
  ResumoSessao? _resumo;

  @override
  void initState() {
    super.initState();
    _resumo = ControleObjetivos.instance.ultimoResumo;
    final r = _resumo;
    if (r != null) {
      // Uma única chamada por bloqueio (o Future é guardado no estado).
      _sugestoes = GeminiService.padrao.gerarSugestoes(
        ContextoSessao(
          objetivoTitulo: r.objetivoTitulo,
          categoriaTitulo: r.categoriaTitulo,
          textoDeclarado: r.textoIkAi,
          duracaoMinutos: (r.usadoSegundos / 60).round(),
          permitiuEnvio: r.permitiuEnvioGemini,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = _resumo;
    final peloUsuario = r?.encerradaPeloUsuario ?? false;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Cores.fundoEtapas,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.hourglass_bottom_rounded,
                      size: 56,
                      color: Cores.laranja,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      peloUsuario ? 'Sessão encerrada' : 'Seu tempo acabou!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Cores.tituloVerde,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      r == null
                          ? 'Bom descanso da tela.'
                          : 'Você usou ${formatarDuracao(r.usadoSegundos)} '
                              'em ${r.categoriaTitulo}. '
                              'Agora é hora de levar essa energia para fora '
                              'do aplicativo.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Cores.subtitulo,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_sugestoes != null) _blocoSugestoes(),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: ControleObjetivos.instance.reiniciarSessao,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Cores.laranja,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Iniciar nova sessão',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _blocoSugestoes() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E5DF)),
      ),
      child: FutureBuilder<SugestoesIkAi>(
        future: _sugestoes,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Cores.laranja,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'A Ik AI está pensando...',
                    style: TextStyle(color: Cores.subtitulo),
                  ),
                ],
              ),
            );
          }

          final itens = snap.data?.itens ?? const <String>[];
          final viaGemini = snap.data?.fonte == FonteSugestoes.gemini;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sugestões da Ik AI',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Cores.tituloVerde,
                ),
              ),
              const SizedBox(height: 12),
              for (var i = 0; i < itens.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Cores.verdeClaro,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Cores.verde,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          itens[i],
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: Cores.tituloVerde,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Text(
                viaGemini
                    ? 'Geradas pelo Gemini a partir do que você escreveu.'
                    : 'Geradas no seu aparelho, sem enviar nada.'
                        '${kDebugMode && snap.data?.motivoLocal != null ? '\n[debug] ${snap.data!.motivoLocal}' : ''}',
                style: const TextStyle(fontSize: 11, color: Cores.subtitulo),
              ),
            ],
          );
        },
      ),
    );
  }
}
