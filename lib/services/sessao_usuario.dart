import '../pages_configurar/controle_objetivo.dart';
import 'auth_service.dart';
import 'biblioteca_service.dart';
import 'compromisso_service.dart';
import 'conteudo_usuario.dart';
import 'ik_ai_service.dart';
import 'progresso_service.dart';
import 'tempo_diario.dart';

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
      TempoDiarioService.instance.carregarPara(u.email),
      ConteudoUsuarioService.instance.carregar(),
    ]);
    // Se a pessoa já escolheu o que ver hoje, a escolha volta (vale só no
    // dia). O tempo usado hoje também volta: sair e entrar não zera a meta.
    await ControleObjetivos.instance.restaurarSelecao();
    TempoDiarioService.instance.iniciarContagem();
  }

  /// Sair da conta limpa a memória do aparelho. O tempo usado e a escolha
  /// do dia ficam gravados: sair e entrar não reinicia a meta.
  static void aoSair() {
    TempoDiarioService.instance.limpar(); // pausa, grava e esquece a memória
    ControleObjetivos.instance.descartarSessaoEmMemoria();
    ControleObjetivos.instance.descartarHistoricoEmMemoria();
    BibliotecaService.instance.limpar();
    ProgressoService.instance.limpar();
    IkAiService.limpar();
    CompromissoService.instance.limpar();
    ConteudoUsuarioService.instance.limpar();
    AuthService.instance.sair();
  }

  /// Exclui a conta e limpa tudo. Com a API, o servidor apaga primeiro: se
  /// falhar, devolve o erro e nada é apagado do aparelho.
  static Future<String?> aoExcluirConta() async {
    final erro = await AuthService.instance.apagarNoServidor();
    if (erro != null) return erro;
    TempoDiarioService.instance.apagarDaConta(); // lê o e-mail antes
    ControleObjetivos.instance.reiniciarSessao();
    ControleObjetivos.instance.descartarHistoricoEmMemoria();
    BibliotecaService.instance.limpar();
    ProgressoService.instance.limpar();
    IkAiService.apagarDaConta(); // lê o e-mail antes da conta sair
    CompromissoService.instance.apagarDaConta();
    final email = AuthService.instance.usuarioAtual?.email;
    if (email != null) ConteudoUsuarioService.instance.apagarDaConta(email);
    return AuthService.instance.excluirConta();
  }
}
