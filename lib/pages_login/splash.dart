import 'dart:async';

import 'package:flutter/material.dart';

import '../widgets/estilo.dart';
import '../widgets/paisagem.dart';
import 'login.dart';

/// Tela de abertura com a logo. Segue para o login sozinha.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 3), _seguir);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _seguir() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Cores.bege,
      body: SizedBox.expand(
        child: PaisagemView(
          paisagem: Paisagem.alvorecer,
          ajuste: AjustePaisagem.largura,
          child: SafeArea(
            child: Align(
              alignment: const Alignment(0, -0.35),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 1100),
                curve: Curves.easeOut,
                builder: (context, v, filho) => Opacity(
                  opacity: v,
                  child: Transform.translate(
                    offset: Offset(0, (1 - v) * 16),
                    child: filho,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Image.asset(
                    'assets/ikai.png',
                    height: 300,
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
            ),
          ),
        ),
      ),
    );
  }
}
