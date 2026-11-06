import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../pages_configurar/confirmar_entrada.dart';
import '../services/auth_service.dart';
import '../services/sessao_usuario.dart';
import '../widgets/estilo.dart';
import 'cadastro.dart';
import 'resgatar_senha.dart';
import 'widgets_login.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const String _kEmailLembrado = 'login_email_lembrado';

  final TextEditingController emailController = TextEditingController();
  final TextEditingController senhaController = TextEditingController();

  bool _lembrar = false;
  bool esconderSenha = true;
  bool _entrando = false;

  @override
  void initState() {
    super.initState();
    _carregarEmailLembrado();
  }

  @override
  void dispose() {
    emailController.dispose();
    senhaController.dispose();
    super.dispose();
  }

  /// "Lembrar de mim" guarda só o e-mail, nunca a senha.
  Future<void> _carregarEmailLembrado() async {
    try {
      final p = await SharedPreferences.getInstance();
      final email = p.getString(_kEmailLembrado);
      if (!mounted || email == null || email.isEmpty) return;
      setState(() {
        emailController.text = email;
        _lembrar = true;
      });
    } catch (_) {
      // Sem armazenamento, o campo só começa vazio.
    }
  }

  Future<void> _guardarEmailLembrado() async {
    try {
      final p = await SharedPreferences.getInstance();
      if (_lembrar) {
        await p.setString(_kEmailLembrado, emailController.text.trim());
      } else {
        await p.remove(_kEmailLembrado);
      }
    } catch (_) {}
  }

  Future<void> entrar() async {
    if (_entrando) return;
    final erro = AuthService.instance.entrar(
      emailController.text,
      senhaController.text,
    );
    if (erro != null) {
      mostrarAviso(context, erro);
      return;
    }

    setState(() => _entrando = true);
    await _guardarEmailLembrado();
    await SessaoUsuario.aoEntrar();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const ConfirmarEntradaPage()),
    );
  }

  Future<void> abrirCadastro() async {
    final email = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const CadastroPage()),
    );
    if (email != null && mounted) {
      setState(() => emailController.text = email);
    }
  }

  void abrirEsqueceuASenha() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ResgatarSenhaPage()),
    );
  }

  void _loginSocial() => mostrarAviso(context, avisoLoginSocial);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fundoLogin,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 25),
              const LogoIkai(),
              const SizedBox(height: 35),
              Text(
                'Entre na sua conta',
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Informe seu e-mail e sua senha para entrar',
                style: GoogleFonts.inter(fontSize: 14),
              ),
              const SizedBox(height: 30),
              CampoLogin(
                controller: emailController,
                rotulo: 'E-mail',
                dica: 'exemplo@gmail.com',
                icone: Icons.email,
                teclado: TextInputType.emailAddress,
                acao: TextInputAction.next,
              ),
              const SizedBox(height: 15),
              CampoLogin(
                controller: senhaController,
                rotulo: 'Senha',
                icone: Icons.lock,
                senha: true,
                esconder: esconderSenha,
                aoAlternarVisibilidade: () =>
                    setState(() => esconderSenha = !esconderSenha),
                acao: TextInputAction.done,
                aoEnviar: entrar,
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Checkbox(
                          value: _lembrar,
                          onChanged: (v) =>
                              setState(() => _lembrar = v ?? false),
                        ),
                        Flexible(
                          child: Text(
                            'Lembrar de mim',
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: abrirEsqueceuASenha,
                    child: Text(
                      'Esqueceu a senha?',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              BotaoPrincipal(
                texto: 'Entrar',
                onPressed: _entrando ? null : entrar,
              ),
              const SizedBox(height: 10),
              const DivisorOu(),
              const SizedBox(height: 10),
              BotaoSocial(
                texto: 'Continuar com Google',
                imagem: 'assets/logo_google.png',
                onPressed: _loginSocial,
              ),
              const SizedBox(height: 10),
              BotaoSocial(
                texto: 'Continuar com Facebook',
                imagem: 'assets/logo_facebook.png',
                onPressed: _loginSocial,
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Não tem uma conta?',
                    style: GoogleFonts.inter(fontSize: 14),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.only(left: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: abrirCadastro,
                    child: Text(
                      'Cadastre-se',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
