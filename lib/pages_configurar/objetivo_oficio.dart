import 'package:flutter/material.dart';
import './controle_objetivo.dart';

/// Categorias de "Aprender um ofício": habilidades que se aprendem com as
/// mãos. Para adicionar outra, inclua uma linha `Categoria(...)` aqui.
const List<Categoria> _categoriasOficio = [
  Categoria(
    id: 'oficio_marcenaria',
    titulo: 'Marcenaria',
    icone: Icons.carpenter_outlined,
  ),
  Categoria(
    id: 'oficio_eletrica',
    titulo: 'Elétrica residencial',
    icone: Icons.electrical_services_outlined,
  ),
  Categoria(
    id: 'oficio_hidraulica',
    titulo: 'Hidráulica',
    icone: Icons.plumbing_outlined,
  ),
  Categoria(
    id: 'oficio_culinaria',
    titulo: 'Culinária',
    icone: Icons.restaurant_menu_outlined,
  ),
  Categoria(
    id: 'oficio_panificacao',
    titulo: 'Panificação',
    icone: Icons.bakery_dining_outlined,
  ),
  Categoria(
    id: 'oficio_costura',
    titulo: 'Costura',
    icone: Icons.checkroom_outlined,
  ),
  Categoria(
    id: 'oficio_jardinagem',
    titulo: 'Jardinagem',
    icone: Icons.yard_outlined,
  ),
  Categoria(
    id: 'oficio_mecanica',
    titulo: 'Mecânica',
    icone: Icons.car_repair_outlined,
  ),
  Categoria(
    id: 'oficio_fotografia',
    titulo: 'Fotografia',
    icone: Icons.photo_camera_outlined,
  ),
  Categoria(
    id: 'oficio_desenho',
    titulo: 'Desenho',
    icone: Icons.draw_outlined,
  ),
  Categoria(
    id: 'oficio_artesanato',
    titulo: 'Artesanato',
    icone: Icons.brush_outlined,
  ),
  Categoria(
    id: 'oficio_instrumento',
    titulo: 'Tocar um instrumento',
    icone: Icons.piano_outlined,
  ),
];

final Objetivo objetivoOficio = Objetivo(
  id: 'oficio',
  titulo: 'Aprender um ofício',
  icone: Icons.handyman_outlined,
  categorias: _categoriasOficio,
);
