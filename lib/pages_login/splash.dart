import 'dart:async';

import 'package:flutter/material.dart';

import '../widgets/estilo.dart';
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
