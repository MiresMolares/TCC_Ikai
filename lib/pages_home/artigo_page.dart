import 'package:flutter/material.dart';

import '../data/artigo.dart';
import '../services/biblioteca_service.dart';
import '../services/progresso_service.dart';
import '../widgets/estilo.dart';
import '../widgets/salvar_em_pasta.dart';

void abrirArtigo(BuildContext context, Artigo artigo) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => ArtigoPage(artigo: artigo)),
  );
}

/// Leitura de um artigo. O Ikai nunca marca como lido sozinho: quem decide
/// que terminou é a pessoa, no botão "Concluir leitura".
class ArtigoPage extends StatelessWidget {
  final Artigo artigo;

  const ArtigoPage({super.key, required this.artigo});

  Future<void> _concluir(BuildContext context) async {
    final primeira = await ProgressoService.instance.registrarLeitura(artigo);
    if (!context.mounted) return;
    mostrarAviso(
      context,
      primeira ? 'Leitura registrada no seu progresso.' : 'Você já tinha '
          'concluído este artigo.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Cores.fundo,
      appBar: AppBar(
        backgroundColor: Cores.fundo,
        actions: [
          ListenableBuilder(
            listenable: BibliotecaService.instance,
            builder: (context, _) {
              final salvo = BibliotecaService.instance.estaSalvo(artigo.id);
              return IconButton(
                tooltip: salvo ? 'Salvo na biblioteca' : 'Salvar',
                onPressed: () => mostrarSalvarEmPasta(context, artigo),
                icon: Icon(
                  salvo ? Icons.bookmark : Icons.bookmark_border,
                  color: salvo ? Cores.laranja : Cores.titulo,
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            Text(
              artigo.titulo,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                height: 1.25,
                color: Cores.titulo,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${artigo.autor}  ·  ${artigo.minutosLeitura} min de leitura',
              style: const TextStyle(fontSize: 13, color: Cores.subtitulo),
            ),
            const SizedBox(height: 20),
            for (final p in artigo.paragrafos)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  p,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.6,
                    color: Cores.titulo,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final t in artigo.tags)
                  Chip(
                    label: Text(t, style: const TextStyle(fontSize: 12)),
                    backgroundColor: Cores.verdeClaro,
                    side: BorderSide.none,
                  ),
              ],
            ),
            const SizedBox(height: 24),
            ListenableBuilder(
              listenable: ProgressoService.instance,
              builder: (context, _) {
                final lido = ProgressoService.instance.foiLido(artigo.id);
                return SizedBox(
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: lido ? null : () => _concluir(context),
                    icon: Icon(lido ? Icons.check_circle : Icons.check),
                    label: Text(
                      lido ? 'Leitura concluída' : 'Concluir leitura',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Cores.laranja,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Cores.verdeClaro,
                      disabledForegroundColor: Cores.verde,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
