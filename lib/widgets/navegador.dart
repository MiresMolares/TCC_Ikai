import 'package:flutter/material.dart';

/// Navegador global: o botão flutuante da Ik AI e o aviso de tempo ficam
/// ACIMA do Navigator (no SessaoGuard), então precisam deste atalho para
/// abrir telas, e de um observador para saber quando se esconder.
class NavegadorIk {
  NavegadorIk._();

  static final GlobalKey<NavigatorState> chave = GlobalKey<NavigatorState>();

  static final ObservadorDeRotas observador = ObservadorDeRotas();

  /// Nome da rota da conversa com a Ik AI (o botão some nela).
  static const String rotaIkAi = '/ik-ai';

  /// Abre uma tela por cima da atual.
  static Future<T?>? abrir<T>(Route<T> rota) => chave.currentState?.push(rota);
}

/// Acompanha a pilha de rotas e diz se o botão flutuante pode aparecer:
/// ele some sobre diálogos, menus inferiores e na própria conversa da Ik AI.
class ObservadorDeRotas extends NavigatorObserver {
  final List<Route<dynamic>> _pilha = [];

  /// true quando a rota do topo permite o botão flutuante.
  final ValueNotifier<bool> botaoPermitido = ValueNotifier<bool>(true);

  static bool permite(Route<dynamic>? topo) {
    if (topo == null) return true;
    if (topo is PopupRoute) return false;
    return topo.settings.name != NavegadorIk.rotaIkAi;
  }

  void _atualizar() {
    final novo = permite(_pilha.isEmpty ? null : _pilha.last);
    if (novo == botaoPermitido.value) return;
    // Pode ser chamado durante a construção da árvore: adia para depois.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      botaoPermitido.value = permite(_pilha.isEmpty ? null : _pilha.last);
    });
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _pilha.add(route);
    _atualizar();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _pilha.remove(route);
    _atualizar();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _pilha.remove(route);
    _atualizar();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final i = oldRoute == null ? -1 : _pilha.indexOf(oldRoute);
    if (i >= 0) {
      if (newRoute != null) {
        _pilha[i] = newRoute;
      } else {
        _pilha.removeAt(i);
      }
    } else if (newRoute != null) {
      _pilha.add(newRoute);
    }
    _atualizar();
  }

  /// Esquece a pilha quando o Navigator é recriado (o SessaoGuard o remove
  /// da árvore na tela de fim de tempo).
  void reiniciar() {
    _pilha.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      botaoPermitido.value = true;
    });
  }
}
