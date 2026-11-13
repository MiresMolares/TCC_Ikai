import 'package:flutter/material.dart';

/// Cores do Ikai em um só lugar.
class Cores {
  Cores._();

  static const Color laranja = Color(0xFFCB5A34);
  static const Color fundo = Color(0xFFFDFBF7);
  static const Color fundoEtapas = Color(0xFFF7F8F4);
  static const Color titulo = Color(0xFF243044);
  static const Color tituloVerde = Color(0xFF253D2D);
  static const Color subtitulo = Color(0xFF68756B);
  static const Color verde = Color(0xFF4B7F5A);
  static const Color verdeClaro = Color(0xFFEAF2EC);
  static const Color rosado = Color(0xFFFBEFEA);
  static const Color borda = Color(0xFFE7EDF1);
  static const Color bordaQuente = Color(0xFFF0ECE6);
  static const Color bege = Color(0xFFE8D5B1);
}

/// Mostra uma mensagem curta no rodapé, trocando a anterior.
void mostrarAviso(BuildContext context, String mensagem) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(mensagem),
        duration: const Duration(seconds: 3),
      ),
    );
}
