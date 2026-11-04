import '../pages_configurar/controle_objetivo.dart';
import 'auth_service.dart';
import 'biblioteca_service.dart';
import 'progresso_service.dart';

/// O que acontece quando alguém entra ou sai da conta.
/// Garante que nenhum dado de um usuário apareça para o próximo.
class SessaoUsuario {
  SessaoUsuario._();

  /// Chame logo depois de `AuthService.entrar` dar certo.
  static Future<void> aoEntrar() async {
    final u = AuthService.instance.usuarioAtual;
    if (u == null) return;
    ControleObjetivos.instance.reiniciarSessao();
    ControleObjetivos.instance.descartarHistoricoEmMemoria();
    await Future.wait([
      BibliotecaService.instance.carregarPara(u.email),
      ProgressoService.instance.carregarPara(u.email),
    ]);
  }

  /// Sair da conta também encerra a sessão (Pilar 1) e limpa a memória.
  static void aoSair() {
    ControleObjetivos.instance.reiniciarSessao();
    ControleObjetivos.instance.descartarHistoricoEmMemoria();
    BibliotecaService.instance.limpar();
    ProgressoService.instance.limpar();
    AuthService.instance.sair();
  }

  /// Exclui a conta (de teste) e limpa tudo.
  static void aoExcluirConta() {
    ControleObjetivos.instance.reiniciarSessao();
    ControleObjetivos.instance.descartarHistoricoEmMemoria();
    BibliotecaService.instance.limpar();
    ProgressoService.instance.limpar();
    AuthService.instance.excluirConta();
  }
}
