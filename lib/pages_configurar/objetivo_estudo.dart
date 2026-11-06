import 'package:flutter/material.dart';
import './controle_objetivo.dart';

/// Matérias de "Estudar". Para adicionar uma, inclua uma linha aqui.
const List<Categoria> _materias = [
  Categoria(
    id: 'estudar_matematica',
    titulo: 'Matemática',
    icone: Icons.calculate_outlined,
  ),
  Categoria(
    id: 'estudar_lp',
    titulo: 'LP: Língua Portuguesa',
    icone: Icons.menu_book_outlined,
  ),
  Categoria(
    id: 'estudar_ingles',
    titulo: 'Inglês',
    icone: Icons.translate_outlined,
  ),
  Categoria(
    id: 'estudar_artes',
    titulo: 'Artes',
    icone: Icons.palette_outlined,
  ),
  Categoria(
    id: 'estudar_historia',
    titulo: 'História',
    icone: Icons.account_balance_outlined,
  ),
  Categoria(
    id: 'estudar_geografia',
    titulo: 'Geografia',
    icone: Icons.public_outlined,
  ),
  Categoria(
    id: 'estudar_filosofia',
    titulo: 'Filosofia',
    icone: Icons.psychology_outlined,
  ),
  Categoria(
    id: 'estudar_sociologia',
    titulo: 'Sociologia',
    icone: Icons.groups_outlined,
  ),
  Categoria(
    id: 'estudar_ef',
    titulo: 'Educação Física',
    icone: Icons.fitness_center_outlined,
  ),
  Categoria(
    id: 'estudar_biologia',
    titulo: 'Biologia',
    icone: Icons.eco_outlined,
  ),
  Categoria(
    id: 'estudar_fisica',
    titulo: 'Física',
    icone: Icons.bolt_outlined,
  ),
  Categoria(
    id: 'estudar_quimica',
    titulo: 'Química',
    icone: Icons.science_outlined,
  ),
];

final Objetivo objetivoEstudo = Objetivo(
  id: 'estudar',
  titulo: 'Estudar',
  icone: Icons.school_outlined,
  categorias: _materias,
);
