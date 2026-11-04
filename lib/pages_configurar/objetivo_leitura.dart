import 'package:flutter/material.dart';
import './controle_objetivo.dart';

/// Categorias de "Ler".
/// Para adicionar outra, inclua uma linha `Categoria(...)` aqui.
const List<Categoria> _categoriasLeitura = [
  Categoria(
    id: 'ler_romance',
    titulo: 'Romance',
    icone: Icons.favorite_border,
  ),
  Categoria(
    id: 'ler_fantasia',
    titulo: 'Fantasia',
    icone: Icons.auto_awesome_outlined,
  ),
  Categoria(
    id: 'ler_suspense',
    titulo: 'Suspense',
    icone: Icons.visibility_outlined,
  ),
  Categoria(
    id: 'ler_fc',
    titulo: 'Ficção Científica',
    icone: Icons.rocket_launch_outlined,
  ),
  Categoria(
    id: 'ler_horror',
    titulo: 'Horror',
    icone: Icons.nights_stay_outlined,
  ),
  Categoria(
    id: 'ler_terror',
    titulo: 'Terror',
    icone: Icons.warning_amber_outlined,
  ),
  Categoria(
    id: 'ler_religioso',
    titulo: 'Religioso',
    icone: Icons.menu_book_outlined,
  ),
  Categoria(
    id: 'ler_distopia',
    titulo: 'Distopia',
    icone: Icons.public_off_outlined,
  ),
  Categoria(
    id: 'ler_aventura',
    titulo: 'Aventura',
    icone: Icons.explore_outlined,
  ),
  Categoria(
    id: 'ler_dp',
    titulo: 'Desenvolvimento Pessoal',
    icone: Icons.psychology_outlined,
  ),
  Categoria(
    id: 'ler_tecnico',
    titulo: 'Técnico',
    icone: Icons.build_outlined,
  ),
  Categoria(
    id: 'ler_biografia',
    titulo: 'Biografia',
    icone: Icons.person_outline,
  ),
];

final Objetivo objetivoLeitura = Objetivo(
  id: 'ler',
  titulo: 'Ler',
  icone: Icons.menu_book_outlined,
  categorias: _categoriasLeitura,
);
