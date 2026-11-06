import 'package:flutter/material.dart';

import '../data/artigo.dart';
import '../services/artigos_repositorio.dart';
import '../services/biblioteca_service.dart';
import '../widgets/artigo_card.dart';
import '../widgets/estilo.dart';
import '../widgets/salvar_em_pasta.dart';

/// Biblioteca pessoal: pastas de um único nível, criadas pelo usuário.
class BibliotecaPage extends StatelessWidget {
  const BibliotecaPage({super.key});

  Future<void> _nova(BuildContext context) async {
    final nome = await pedirNomePasta(context, titulo: 'Nova pasta');
    if (nome == null) return;
    final erro = await BibliotecaService.instance.criarPasta(nome);
    if (erro != null && context.mounted) mostrarAviso(context, erro);
  }

  Future<void> _renomear(BuildContext context, Pasta p) async {
    final nome = await pedirNomePasta(
      context,
      titulo: 'Renomear pasta',
      inicial: p.nome,
      ignorarId: p.id,
    );
    if (nome == null) return;
    final erro = await BibliotecaService.instance.renomear(p.id, nome);
    if (erro != null && context.mounted) mostrarAviso(context, erro);
  }

  Future<void> _excluir(BuildContext context, Pasta p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir pasta?'),
        content: Text(
          'A pasta "${p.nome}" será removida da sua biblioteca. Os artigos '
          'continuam disponíveis no Ikai.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (ok == true) await BibliotecaService.instance.excluir(p.id);
  }

  @override
  Widget build(BuildContext context) {
    final b = BibliotecaService.instance;
    return Scaffold(
      backgroundColor: Cores.fundo,
      appBar: AppBar(
        title: const Text('Biblioteca'),
        backgroundColor: Cores.fundo,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _nova(context),
        backgroundColor: Cores.laranja,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.create_new_folder_outlined),
        label: const Text('Nova pasta'),
      ),
      body: ListenableBuilder(
        listenable: b,
        builder: (context, _) {
          final pastas = b.pastas;
          if (pastas.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Nenhuma pasta ainda. Crie uma para guardar seus artigos.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Cores.subtitulo),
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            itemCount: pastas.length,
            separatorBuilder: (context, i) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final p = pastas[i];
              return Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PastaPage(pastaId: p.id),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Cores.borda),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.folder_outlined, color: Cores.laranja),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.nome,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Cores.titulo,
                                ),
                              ),
                              Text(
                                p.artigoIds.length == 1
                                    ? '1 artigo'
                                    : '${p.artigoIds.length} artigos',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Cores.subtitulo,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (v) {
                            if (v == 'renomear') _renomear(context, p);
                            if (v == 'excluir') _excluir(context, p);
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: 'renomear',
                              child: Text('Renomear'),
                            ),
                            PopupMenuItem(
                              value: 'excluir',
                              child: Text('Excluir'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Conteúdo de uma pasta, com busca interna.
class PastaPage extends StatefulWidget {
  final String pastaId;

  const PastaPage({super.key, required this.pastaId});

  @override
  State<PastaPage> createState() => _PastaPageState();
}

class _PastaPageState extends State<PastaPage> {
  final TextEditingController _busca = TextEditingController();

  @override
  void dispose() {
    _busca.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final b = BibliotecaService.instance;
    return ListenableBuilder(
      listenable: b,
      builder: (context, _) {
        final pasta = b.pastaPorId(widget.pastaId);
        final List<Artigo> todos = [];
        if (pasta != null) {
          for (final id in pasta.artigoIds) {
            final a = ArtigosRepositorio.porId(id);
            if (a != null) todos.add(a);
          }
        }
        final lista = ArtigosRepositorio.buscar(_busca.text, todos);

        return Scaffold(
          backgroundColor: Cores.fundo,
          appBar: AppBar(
            title: Text(pasta?.nome ?? 'Pasta'),
            backgroundColor: Cores.fundo,
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              if (todos.isNotEmpty) ...[
                TextField(
                  controller: _busca,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Buscar nesta pasta',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Cores.borda),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (todos.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 48),
                  child: Text(
                    'Esta pasta está vazia. Use o ícone de marcador em um '
                    'artigo para guardá-lo aqui.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Cores.subtitulo),
                  ),
                )
              else if (lista.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 48),
                  child: Text(
                    'Nada encontrado nesta pasta.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Cores.subtitulo),
                  ),
                )
              else
                ListaDeArtigos(artigos: lista),
            ],
          ),
        );
      },
    );
  }
}
