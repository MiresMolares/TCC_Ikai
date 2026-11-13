import 'package:flutter/material.dart';

import '../services/conteudo_usuario.dart';
import '../widgets/artigo_card.dart';
import '../widgets/estilo.dart';
import 'escrever_artigo.dart';

/// Os artigos que a própria pessoa escreveu: abrir, escrever outro, apagar.
class MeusArtigosPage extends StatelessWidget {
  const MeusArtigosPage({super.key});

  Future<void> _apagar(BuildContext context, String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Apagar este artigo?'),
        content: const Text('Isso não pode ser desfeito.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Apagar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true) await ConteudoUsuarioService.instance.apagarArtigo(id);
  }

  @override
  Widget build(BuildContext context) {
    final s = ConteudoUsuarioService.instance;
    return Scaffold(
      backgroundColor: Cores.fundo,
      appBar: AppBar(
        title: const Text('Meus artigos'),
        backgroundColor: Cores.fundo,
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: s,
          builder: (context, _) {
            final meus = s.meusArtigos.reversed.toList();
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
              children: [
                ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EscreverArtigoPage(),
                    ),
                  ),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Escrever um artigo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Cores.laranja,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
                const SizedBox(height: 16),
                if (meus.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Text(
                      'Você ainda não escreveu nada. O que você sabe e '
                      'gostaria de contar a outras pessoas?',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Cores.subtitulo),
                    ),
                  )
                else
                  for (final a in meus)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          ArtigoCard(artigo: a),
                          TextButton.icon(
                            onPressed: () => _apagar(context, a.id),
                            icon: const Icon(Icons.delete_outline, size: 18),
                            label: const Text('Apagar'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
              ],
            );
          },
        ),
      ),
    );
  }
}
