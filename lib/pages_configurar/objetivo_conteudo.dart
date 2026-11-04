import 'package:flutter/material.dart';
import './controle_objetivo.dart';

/// Categorias de "Ver conteúdo".
/// Para adicionar outra, inclua uma linha `Categoria(...)` aqui.
const List<Categoria> _categoriasConteudo = [
  Categoria(
    id: 'ver_cientifico',
    titulo: 'Científico',
    icone: Icons.science_outlined,
  ),
  Categoria(
    id: 'ver_cultura',
    titulo: 'Cultura',
    icone: Icons.museum_outlined,
  ),
  Categoria(
    id: 'ver_jogos',
    titulo: 'Jogos',
    icone: Icons.sports_esports_outlined,
  ),
  Categoria(
    id: 'ver_noticia',
    titulo: 'Notícias',
    icone: Icons.newspaper_outlined,
  ),
  Categoria(
    id: 'ver_esporte',
    titulo: 'Esporte',
    icone: Icons.sports_soccer_outlined,
  ),
  Categoria(
    id: 'ver_curiosidades',
    titulo: 'Curiosidades',
    icone: Icons.lightbulb_outline,
  ),
];

final Objetivo objetivoConteudo = Objetivo(
  id: 'ver_conteudo',
  titulo: 'Ver conteúdo',
  icone: Icons.play_circle_outline,
  categorias: _categoriasConteudo,
);
