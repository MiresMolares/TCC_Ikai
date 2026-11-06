import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/auth_service.dart';
import '../widgets/estilo.dart';
import 'widgets_login.dart';

class ResgatarSenhaPage extends StatefulWidget {
  const ResgatarSenhaPage({super.key});

  @override
  State<ResgatarSenhaPage> createState() => _ResgatarSenhaPageState();
}

class _ResgatarSenhaPageState extends State<ResgatarSenhaPage> {
  final TextEditingController emailController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  void enviar() {
    final erro = AuthService.instance.recuperarSenha(emailController.text);
    if (erro != null) {
      mostrarAviso(context, erro);
      return;
    }

    // A resposta é a mesma exista o e-mail ou não, para não revelar quais
    // e-mails têm conta. O envio real depende do servidor (back-end).
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Se este e-mail estiver cadastrado, você receberá as '
            'instruções para criar uma nova senha.',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recuperar senha'),
        backgroundColor: fundoLogin,
      ),
      backgroundColor: fundoLogin,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 15),
              const LogoIkai(),
              const SizedBox(height: 50),
              Text(
                'Recuperar senha',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Informe o e-mail da sua conta.',
                style: GoogleFonts.inter(fontSize: 18),
              ),
              const SizedBox(height: 30),
              CampoLogin(
                controller: emailController,
                rotulo: 'E-mail',
                dica: 'exemplo@gmail.com',
                icone: Icons.email,
                teclado: TextInputType.emailAddress,
                acao: TextInputAction.done,
                aoEnviar: enviar,
              ),
              const SizedBox(height: 45),
              BotaoPrincipal(texto: 'Enviar', onPressed: enviar),
            ],
          ),
        ),
      ),
    );
  }
}
