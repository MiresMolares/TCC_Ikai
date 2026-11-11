import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'pages_configurar/destino_inicial.dart';
import 'pages_configurar/sessao_guard.dart';
import 'pages_login/splash.dart';
import 'services/auth_service.dart';
import 'services/config_service.dart';
import 'widgets/estilo.dart';
import 'widgets/navegador.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ConfigService.instance.carregar();
  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ConfigService.instance,
      builder: (context, _) {
        final escalaTexto = ConfigService.instance.tamanhoTexto;
        return MaterialApp(
          locale: DevicePreview.locale(context),
          debugShowCheckedModeBanner: false,
          title: 'Ikai',
          navigatorKey: NavegadorIk.chave,
          navigatorObservers: [NavegadorIk.observador],
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Cores.laranja),
            useMaterial3: true,
          ),
          // O SessaoGuard fica ACIMA do Navigator: conta o tempo do dia,
          // mostra os avisos e o botão da Ik AI e, quando a meta acaba,
          // troca o app pela conversa de fim de tempo.
          builder: (context, child) => DevicePreview.appBuilder(
            context,
            Builder(
              builder: (context) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(escalaTexto),
                ),
                child: SessaoGuard(child: child ?? const SizedBox.shrink()),
              ),
            ),
          ),
          home: const RaizApp(),
        );
      },
    );
  }
}

/// Primeira tela do Navigator. Também é a que volta quando o Navigator é
/// recriado (depois da conversa de fim de tempo): se já está conectado, vai
/// direto para onde a pessoa estava, sem repetir splash e login.
class RaizApp extends StatelessWidget {
  const RaizApp({super.key});

  @override
  Widget build(BuildContext context) {
    if (!AuthService.instance.logado) return const SplashPage();
    return destinoInicial();
  }
}
