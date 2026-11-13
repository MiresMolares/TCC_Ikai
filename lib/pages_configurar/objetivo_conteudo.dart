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
  Categoria(
    id: 'ver_natureza',
    titulo: 'Natureza e animais',
    icone: Icons.eco_outlined,
  ),
  Categoria(
    id: 'ver_tecnologia',
    titulo: 'Tecnologia',
    icone: Icons.computer_outlined,
  ),
  Categoria(
    id: 'ver_espaco',
    titulo: 'Espaço',
    icone: Icons.rocket_launch_outlined,
  ),
  Categoria(
    id: 'ver_musica',
    titulo: 'Música',
    icone: Icons.library_music_outlined,
  ),
  Categoria(
    id: 'ver_cinema',
    titulo: 'Cinema e séries',
    icone: Icons.movie_outlined,
  ),
  Categoria(
    id: 'ver_gastronomia',
    titulo: 'Gastronomia',
    icone: Icons.restaurant_outlined,
  ),
  Categoria(
    id: 'ver_viagens',
    titulo: 'Viagens e lugares',
    icone: Icons.flight_outlined,
  ),
  Categoria(
    id: 'ver_arquitetura',
    titulo: 'Arquitetura e cidades',
    icone: Icons.apartment_outlined,
  ),
  Categoria(
    id: 'ver_saude',
    titulo: 'Saúde e bem-estar',
    icone: Icons.spa_outlined,
  ),
  Categoria(
    id: 'ver_economia',
    titulo: 'Dinheiro e economia',
    icone: Icons.savings_outlined,
  ),
];

final Objetivo objetivoConteudo = Objetivo(
  id: 'ver_conteudo',
  titulo: 'Ver conteúdo',
  icone: Icons.play_circle_outline,
  categorias: _categoriasConteudo,
);
