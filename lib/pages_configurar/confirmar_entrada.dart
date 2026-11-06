import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../pages_login/login.dart';
import '../services/sessao_usuario.dart';
import '../widgets/estilo.dart';
import '../pages_home/home.dart';
import 'controle_objetivo.dart';
import 'fluxo_objetivos_page.dart';

/// Pilar 1: ao abrir o Ikai, ele pergunta se a pessoa realmente quer
/// entrar naquele momento. Nada é aberto automaticamente.
class ConfirmarEntradaPage extends StatefulWidget {
  const ConfirmarEntradaPage({super.key});

  @override
  State<ConfirmarEntradaPage> createState() => _ConfirmarEntradaPageState();
}

class _ConfirmarEntradaPageState extends State<ConfirmarEntradaPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _perguntar();
    });
  }

  Future<void> _perguntar() async {
    final resposta = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false, // o botão voltar não fecha a pergunta
        child: AlertDialog(
          backgroundColor: Cores.fundoEtapas,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Bem-vindo ao Ikai!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Cores.tituloVerde,
            ),
          ),
          content: const Text(
            'Você realmente quer entrar agora?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Cores.subtitulo),
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Cores.laranja,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Sim, continuar'),
            ),
            OutlinedButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              style: OutlinedButton.styleFrom(
                foregroundColor: Cores.tituloVerde,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Não, sair'),
            ),
          ],
        ),
      ),
    );

    if (!mounted) return;

    if (resposta == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ControleObjetivos.instance.estado == EstadoSessao.ativa
                  ? const HomePage() // sessão que continuava correndo
                  : const FluxoObjetivosPage(),
        ),
      );
      return;
    }

    // "Não, sair": encerra a conta no app e fecha. Em plataformas que não
    // permitem fechar o app (web, iOS), volta para o login.
    SessaoUsuario.aoSair();
    await SystemNavigator.pop();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (rota) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Cores.bege,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Image.asset(
            'assets/ikai.png',
            height: 350,
            fit: BoxFit.contain,
            errorBuilder: (context, erro, pilha) => const Text(
              'Ikai',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Cores.laranja,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
