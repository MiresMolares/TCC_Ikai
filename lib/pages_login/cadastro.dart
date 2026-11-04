import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/auth_service.dart';
import '../widgets/estilo.dart';
import 'widgets_login.dart';

class CadastroPage extends StatefulWidget {
  const CadastroPage({super.key});

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  final TextEditingController nomeController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController senhaController = TextEditingController();
  final TextEditingController confirmaSenhaController =
      TextEditingController();

  bool esconderSenha = true;
  bool esconderConfirmaSenha = true;

  @override
  void dispose() {
    nomeController.dispose();
    emailController.dispose();
    senhaController.dispose();
    confirmaSenhaController.dispose();
    super.dispose();
  }

  void cadastrar() {
    if (nomeController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        senhaController.text.isEmpty ||
        confirmaSenhaController.text.isEmpty) {
      mostrarAviso(context, 'Preencha todos os campos.');
      return;
    }
    if (senhaController.text != confirmaSenhaController.text) {
      mostrarAviso(context, 'As senhas não coincidem.');
      return;
    }

    final erro = AuthService.instance.cadastrar(
      nome: nomeController.text,
      email: emailController.text,
      senha: senhaController.text,
    );
    if (erro != null) {
      mostrarAviso(context, erro);
      return;
    }

    // Volta ao login com o e-mail já preenchido.
    final email = emailController.text.trim().toLowerCase();
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context, email);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Conta criada! Agora é só entrar.')),
      );
  }

  void _loginSocial() => mostrarAviso(context, avisoLoginSocial);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastro'),
        backgroundColor: fundoLogin,
      ),
      backgroundColor: fundoLogin,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const LogoIkai(),
              const SizedBox(height: 30),
              Text(
                'Crie sua conta',
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Preencha os dados abaixo para se cadastrar',
                style: GoogleFonts.inter(fontSize: 15),
              ),
              const SizedBox(height: 30),
              CampoLogin(
                controller: nomeController,
                rotulo: 'Nome completo',
                icone: Icons.person,
                acao: TextInputAction.next,
              ),
              const SizedBox(height: 15),
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
                acao: TextInputAction.next,
              ),
              const SizedBox(height: 15),
              CampoLogin(
                controller: confirmaSenhaController,
                rotulo: 'Confirmar senha',
                icone: Icons.lock,
                senha: true,
                esconder: esconderConfirmaSenha,
                aoAlternarVisibilidade: () => setState(
                  () => esconderConfirmaSenha = !esconderConfirmaSenha,
                ),
                acao: TextInputAction.done,
                aoEnviar: cadastrar,
              ),
              const SizedBox(height: 25),
              BotaoPrincipal(texto: 'Cadastrar', onPressed: cadastrar),
              const SizedBox(height: 15),
              const DivisorOu(),
              const SizedBox(height: 15),
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
                    'Já tem uma conta?',
                    style: GoogleFonts.inter(fontSize: 14),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.only(left: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Entrar',
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
