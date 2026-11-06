import '../pages_configurar/controle_objetivo.dart';
import 'auth_service.dart';
import 'biblioteca_service.dart';
import 'compromisso_service.dart';
import 'ik_ai_service.dart';
import 'progresso_service.dart';

/// O que acontece quando alguém entra ou sai da conta.
/// Garante que nenhum dado de um usuário apareça para o próximo.
class SessaoUsuario {
  SessaoUsuario._();

  /// Chame logo depois de `AuthService.entrar` dar certo.
  static Future<void> aoEntrar() async {
    final u = AuthService.instance.usuarioAtual;
    if (u == null) return;
    ControleObjetivos.instance.descartarSessaoEmMemoria();
    ControleObjetivos.instance.descartarHistoricoEmMemoria();
    await Future.wait([
      BibliotecaService.instance.carregarPara(u.email),
      ProgressoService.instance.carregarPara(u.email),
      IkAiService.carregarPara(u.email),
      CompromissoService.instance.carregarPara(u.email),
    ]);
    // Se esta conta tinha uma sessão em andamento (ou já vencida), ela volta
    // do ponto em que estava. Fechar o app não dá tempo novo.
    await ControleObjetivos.instance.restaurarSessao();
  }

  /// Sair da conta limpa a memória do aparelho. A sessão gravada continua
  /// valendo (o tempo segue correndo), então sair e entrar não reinicia o
  /// limite.
  static void aoSair() {
    ControleObjetivos.instance.descartarSessaoEmMemoria();
    ControleObjetivos.instance.descartarHistoricoEmMemoria();
    BibliotecaService.instance.limpar();
    ProgressoService.instance.limpar();
    IkAiService.limpar();
    CompromissoService.instance.limpar();
    AuthService.instance.sair();
  }

  /// Exclui a conta (de teste) e limpa tudo.
  static void aoExcluirConta() {
    ControleObjetivos.instance.reiniciarSessao();
    ControleObjetivos.instance.descartarHistoricoEmMemoria();
    BibliotecaService.instance.limpar();
    ProgressoService.instance.limpar();
    IkAiService.apagarDaConta(); // lê o e-mail antes da conta sair
    CompromissoService.instance.apagarDaConta();
    AuthService.instance.excluirConta();
  }
}
