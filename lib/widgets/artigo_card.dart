import 'package:flutter/material.dart';

import '../data/artigo.dart';
import '../pages_configurar/controle_objetivo.dart' show buscarObjetivo;
import '../pages_home/artigo_page.dart';
import '../services/biblioteca_service.dart';
import '../services/progresso_service.dart';
import 'estilo.dart';
import 'paisagem.dart';
import 'salvar_em_pasta.dart';

/// Cartão de artigo usado no feed, na busca, na biblioteca e nas comunidades.
class ArtigoCard extends StatelessWidget {
  final Artigo artigo;

  const ArtigoCard({super.key, required this.artigo});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        BibliotecaService.instance,
        ProgressoService.instance,
      ]),
      builder: (context, _) {
        final salvo = BibliotecaService.instance.estaSalvo(artigo.id);
        final lido = ProgressoService.instance.foiLido(artigo.id);
        final tema = temaDoObjetivo(artigo.objetivoId);
        final categoria = buscarObjetivo(artigo.objetivoId)
            ?.buscarCategoria(artigo.categoriaId)
            ?.titulo;

        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => abrirArtigo(context, artigo),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 6, 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Cores.borda),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 60,
                    child: PaisagemView(
                      paisagem: tema.paisagem,
                      altura: 60,
                      raio: BorderRadius.circular(14),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (categoria != null) ...[
                          Text(
                            categoria.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.6,
                              color: tema.principal,
                            ),
                          ),
                          const SizedBox(height: 3),
                        ],
                        Text(
                          artigo.titulo,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Cores.titulo,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${artigo.doUsuario ? '${artigo.autor} (leitor)' : artigo.autor}  ·  ${artigo.minutosLeitura} min  ·  ${Artigo.nomeDoNivel(artigo.nivel)}'
                          '${lido ? '  ·  Lido' : ''}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Cores.subtitulo,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          artigo.resumo,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: Cores.titulo,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final t in artigo.tags.take(3))
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: tema.claro,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  t,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: tema.escuro,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: salvo ? 'Salvo na biblioteca' : 'Salvar',
                    onPressed: () => mostrarSalvarEmPasta(context, artigo),
                    icon: Icon(
                      salvo ? Icons.bookmark : Icons.bookmark_border,
                      color: salvo ? tema.principal : Cores.subtitulo,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Lista de cartões com espaçamento. Usada por todas as telas.
class ListaDeArtigos extends StatelessWidget {
  final List<Artigo> artigos;

  const ListaDeArtigos({super.key, required this.artigos});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final a in artigos)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ArtigoCard(artigo: a),
          ),
      ],
    );
  }
}
