import 'package:flutter/widgets.dart';

import '../pages_home/home.dart';
import '../services/tempo_diario.dart';
import 'controle_objetivo.dart';
import 'fluxo_objetivos_page.dart';
import 'meta_diaria_page.dart';

/// Para onde ir depois de entrar (ou depois de o app ser recriado):
///  - primeiro uso: define a meta diária;
///  - já escolheu o que ver hoje: Home;
///  - senão: escolha de objetivo e categorias.
Widget destinoInicial() {
  if (!TempoDiarioService.instance.metaDefinida) {
    return const MetaDiariaPage();
  }
  return ControleObjetivos.instance.estado == EstadoSessao.ativa
      ? const HomePage()
      : const FluxoObjetivosPage();
}
