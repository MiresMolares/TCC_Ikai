import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'pages_configurar/fluxo_objetivos_page.dart';
import 'pages_configurar/sessao_guard.dart';
import 'pages_login/splash.dart';
import 'services/auth_service.dart';
import 'services/config_service.dart';
import 'widgets/estilo.dart';

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
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Cores.laranja),
            useMaterial3: true,
          ),
          // O SessaoGuard fica ACIMA do Navigator: quando o tempo acaba,
          // todas as telas, diálogos e menus saem da árvore.
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

/// Primeira tela do Navigator. Também é a tela que volta quando o usuário
/// inicia uma nova sessão depois do bloqueio: se já está conectado, vai
/// direto para a escolha da nova sessão, sem repetir splash e login.
class RaizApp extends StatelessWidget {
  const RaizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthService.instance.logado
        ? const FluxoObjetivosPage()
        : const SplashPage();
  }
}
