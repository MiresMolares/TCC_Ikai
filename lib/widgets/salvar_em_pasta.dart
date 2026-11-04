import 'package:flutter/material.dart';

import '../data/artigo.dart';
import '../services/biblioteca_service.dart';
import 'estilo.dart';

/// Pede um nome de pasta. Devolve o nome já validado, ou null se cancelou.
Future<String?> pedirNomePasta(
  BuildContext context, {
  required String titulo,
  String inicial = '',
  String? ignorarId,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _NomePastaDialog(
      titulo: titulo,
      inicial: inicial,
      ignorarId: ignorarId,
    ),
  );
}

class _NomePastaDialog extends StatefulWidget {
  final String titulo;
  final String inicial;
  final String? ignorarId;

  const _NomePastaDialog({
    required this.titulo,
    required this.inicial,
    required this.ignorarId,
  });

  @override
  State<_NomePastaDialog> createState() => _NomePastaDialogState();
}

class _NomePastaDialogState extends State<_NomePastaDialog> {
  late final TextEditingController _c =
      TextEditingController(text: widget.inicial);
  String? _erro;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _salvar() {
    final erro = BibliotecaService.instance
        .validarNome(_c.text, ignorarId: widget.ignorarId);
    if (erro != null) {
      setState(() => _erro = erro);
      return;
    }
    Navigator.of(context).pop(_c.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.titulo),
      content: TextField(
        controller: _c,
        autofocus: true,
        maxLength: BibliotecaService.tamanhoMaximoNome,
        textCapitalization: TextCapitalization.sentences,
        onSubmitted: (_) => _salvar(),
        onChanged: (_) {
          if (_erro != null) setState(() => _erro = null);
        },
        decoration: InputDecoration(
          hintText: 'Nome da pasta',
          errorText: _erro,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: _salvar,
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

/// Folha inferior: escolhe em quais pastas o artigo fica. Um artigo pode
/// estar em várias pastas.
Future<void> mostrarSalvarEmPasta(BuildContext context, Artigo artigo) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    builder: (_) => _SalvarEmPastaSheet(artigo: artigo),
  );
}

class _SalvarEmPastaSheet extends StatelessWidget {
  final Artigo artigo;
  const _SalvarEmPastaSheet({required this.artigo});

  Future<void> _novaPasta(BuildContext context) async {
    final nome = await pedirNomePasta(context, titulo: 'Nova pasta');
    if (nome == null) return;
    final b = BibliotecaService.instance;
    final erro = await b.criarPasta(nome);
    if (erro != null) {
      if (context.mounted) mostrarAviso(context, erro);
      return;
    }
    // A pasta recém-criada é a última da lista: já guarda o artigo nela.
    await b.alternar(b.pastas.last.id, artigo.id);
  }

  @override
  Widget build(BuildContext context) {
    final b = BibliotecaService.instance;
    return SafeArea(
      child: ListenableBuilder(
        listenable: b,
        builder: (context, _) {
          final pastas = b.pastas;
          return ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Text(
                    'Salvar na biblioteca',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Cores.tituloVerde,
                    ),
                  ),
                ),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final p in pastas)
                        CheckboxListTile(
                          value: p.artigoIds.contains(artigo.id),
                          activeColor: Cores.laranja,
                          title: Text(p.nome),
                          subtitle: Text(
                            p.artigoIds.length == 1
                                ? '1 artigo'
                                : '${p.artigoIds.length} artigos',
                          ),
                          onChanged: (_) => b.alternar(p.id, artigo.id),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: OutlinedButton.icon(
                    onPressed: () => _novaPasta(context),
                    icon: const Icon(Icons.create_new_folder_outlined),
                    label: const Text('Nova pasta'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
