import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../pages_login/login.dart';
import '../../services/auth_service.dart';
import '../../services/biblioteca_service.dart';
import '../../services/config_service.dart';
import '../../services/progresso_service.dart';
import '../../services/sessao_usuario.dart';
import '../../widgets/estilo.dart';
import '../../widgets/textos_app.dart';
import '../perfil.dart';

/// Só tem o que funciona de verdade. Tudo aqui é aplicado e salvo.
class ConfiguracoesPage extends StatelessWidget {
  const ConfiguracoesPage({super.key});

  void _abrir(BuildContext context, Widget pagina) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => pagina));
  }

  Future<void> _exportar(BuildContext context) async {
    final u = AuthService.instance.usuarioAtual;
    final json = '{"conta":{"nome":${_aspas(u?.nome ?? '')},'
        '"email":${_aspas(u?.email ?? '')}},'
        '"biblioteca":${BibliotecaService.instance.exportarJson()},'
        '"progresso":${ProgressoService.instance.exportarJson()}}';
    await Clipboard.setData(ClipboardData(text: json));
    if (context.mounted) {
      mostrarAviso(context, 'Seus dados foram copiados. Cole onde quiser.');
    }
  }

  static String _aspas(String s) =>
      '"${s.replaceAll(r'\', r'\\').replaceAll('"', r'\"')}"';

  Future<void> _excluir(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir conta?'),
        content: const Text(
          'Sua conta será removida deste aparelho. Isso não pode ser '
          'desfeito.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    SessaoUsuario.aoExcluirConta();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (rota) => false,
    );
  }

  Future<void> _sair(BuildContext context) async {
    SessaoUsuario.aoSair();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (rota) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cfg = ConfigService.instance;
    return Scaffold(
      backgroundColor: Cores.fundo,
      appBar: AppBar(
        title: const Text('Configurações'),
        backgroundColor: Cores.fundo,
      ),
      body: ListenableBuilder(
        listenable: cfg,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
          children: [
            const _Secao('Conta'),
            _Cartao([
              _Item(
                icone: Icons.badge_outlined,
                titulo: 'Dados pessoais',
                aoTocar: () => _abrir(context, const EditarPerfilPage()),
              ),
              _Item(
                icone: Icons.lock_outline,
                titulo: 'Alterar senha',
                aoTocar: () => _abrir(context, const _AlterarSenhaPage()),
              ),
            ]),
            const _Secao('Preferências'),
            _Cartao([
              SwitchListTile(
                value: cfg.notificacoes,
                onChanged: cfg.definirNotificacoes,
                activeTrackColor: Cores.verde,
                title: const Text('Notificações'),
                subtitle: const Text('Desligadas por padrão.'),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tamanho do texto'),
                    Slider(
                      value: cfg.tamanhoTexto,
                      min: ConfigService.textoMinimo,
                      max: ConfigService.textoMaximo,
                      divisions: 6,
                      label: '${(cfg.tamanhoTexto * 100).round()}%',
                      activeColor: Cores.laranja,
                      onChanged: cfg.definirTamanhoTexto,
                    ),
                  ],
                ),
              ),
            ]),
            const _Secao('Privacidade e dados'),
            _Cartao([
              _Item(
                icone: Icons.privacy_tip_outlined,
                titulo: 'Política de privacidade',
                aoTocar: () => _abrir(
                  context,
                  const PaginaTexto(
                    titulo: 'Privacidade',
                    texto: TextosApp.privacidade,
                    preliminar: true,
                  ),
                ),
              ),
              _Item(
                icone: Icons.description_outlined,
                titulo: 'Termos de uso',
                aoTocar: () => _abrir(
                  context,
                  const PaginaTexto(
                    titulo: 'Termos de uso',
                    texto: TextosApp.termos,
                    preliminar: true,
                  ),
                ),
              ),
              _Item(
                icone: Icons.download_outlined,
                titulo: 'Exportar meus dados',
                aoTocar: () => _exportar(context),
              ),
            ]),
            const _Secao('Sobre'),
            _Cartao([
              _Item(
                icone: Icons.help_outline,
                titulo: 'Ajuda e suporte',
                aoTocar: () => _abrir(
                  context,
                  const PaginaTexto(
                    titulo: 'Ajuda e suporte',
                    texto: TextosApp.ajuda,
                  ),
                ),
              ),
              _Item(
                icone: Icons.info_outline,
                titulo: 'Sobre o Ikai',
                aoTocar: () => _abrir(
                  context,
                  const PaginaTexto(titulo: 'Sobre o Ikai', texto: TextosApp.sobre),
                ),
              ),
            ]),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () => _sair(context),
              icon: const Icon(Icons.logout),
              label: const Text('Sair da conta'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Cores.laranja,
                side: const BorderSide(color: Cores.laranja),
                minimumSize: const Size.fromHeight(50),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => _excluir(context),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Excluir conta'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Secao extends StatelessWidget {
  final String titulo;
  const _Secao(this.titulo);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
        child: Text(
          titulo,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Cores.subtitulo,
          ),
        ),
      );
}

class _Cartao extends StatelessWidget {
  final List<Widget> filhos;
  const _Cartao(this.filhos);

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Cores.bordaQuente),
        ),
        child: Column(children: filhos),
      );
}

class _Item extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final VoidCallback aoTocar;

  const _Item({
    required this.icone,
    required this.titulo,
    required this.aoTocar,
  });

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icone, color: Cores.laranja),
        title: Text(titulo),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: aoTocar,
      );
}

class _AlterarSenhaPage extends StatefulWidget {
  const _AlterarSenhaPage();

  @override
  State<_AlterarSenhaPage> createState() => _AlterarSenhaPageState();
}

class _AlterarSenhaPageState extends State<_AlterarSenhaPage> {
  final _atual = TextEditingController();
  final _nova = TextEditingController();
  final _confirma = TextEditingController();

  @override
  void dispose() {
    _atual.dispose();
    _nova.dispose();
    _confirma.dispose();
    super.dispose();
  }

  void _salvar() {
    if (_nova.text != _confirma.text) {
      mostrarAviso(context, 'As senhas não coincidem.');
      return;
    }
    final erro = AuthService.instance
        .alterarSenha(atual: _atual.text, nova: _nova.text);
    if (erro != null) {
      mostrarAviso(context, erro);
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Senha alterada.')));
  }

  Widget _campo(TextEditingController c, String rotulo) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: TextField(
          controller: c,
          obscureText: true,
          decoration: InputDecoration(
            labelText: rotulo,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Cores.fundo,
      appBar: AppBar(
        title: const Text('Alterar senha'),
        backgroundColor: Cores.fundo,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _campo(_atual, 'Senha atual'),
          _campo(_nova, 'Nova senha'),
          _campo(_confirma, 'Confirmar nova senha'),
          ElevatedButton(
            onPressed: _salvar,
            style: ElevatedButton.styleFrom(
              backgroundColor: Cores.laranja,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
            ),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }
}
