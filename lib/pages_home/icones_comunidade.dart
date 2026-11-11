import 'package:flutter/material.dart';

/// Ícones que uma comunidade pode ter. O modelo guarda só o id (texto), o
/// que serve ao banco de dados; aqui o id vira o desenho.
const Map<String, IconData> iconesDeComunidade = {
  'historia': Icons.account_balance_outlined,
  'livro': Icons.menu_book_outlined,
  'ciencia': Icons.science_outlined,
  'ideias': Icons.psychology_alt_outlined,
  'musica': Icons.music_note_outlined,
  'arte': Icons.palette_outlined,
  'natureza': Icons.eco_outlined,
  'mundo': Icons.public_outlined,
  'escrita': Icons.edit_note_outlined,
  'estrela': Icons.star_outline,
  'conversa': Icons.forum_outlined,
  'lampada': Icons.lightbulb_outline,
};

IconData iconeDaComunidade(String id) =>
    iconesDeComunidade[id] ?? Icons.groups_outlined;
