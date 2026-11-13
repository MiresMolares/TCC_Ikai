import 'package:flutter/material.dart';

import '../data/artigo.dart';
import '../pages_configurar/controle_objetivo.dart';
import '../services/conteudo_usuario.dart';
import '../widgets/estilo.dart';

/// Formulário para o usuário escrever um artigo. O nível de dificuldade e a
/// categoria são escolhidos por quem escreve (o app nunca deduz).
class EscreverArtigoPage extends StatefulWidget {
  const EscreverArtigoPage({super.key});

  @override
  State<EscreverArtigoPage> createState() => _EscreverArtigoPageState();
}

class _EscreverArtigoPageState extends State<EscreverArtigoPage> {
  final _titulo = TextEditingController();
  final _resumo = TextEditingController();
  final _corpo = TextEditingController();
  final _tags = TextEditingController();

  Objetivo? _objetivo;
  Categoria? _categoria;
  int _nivel = 1;
  bool _enviando = false;
  String? _erro;

  @override
  void dispose() {
    _titulo.dispose();
    _resumo.dispose();
    _corpo.dispose();
    _tags.dispose();
    super.dispose();
  }

  Future<void> _publicar() async {
    if (_enviando) return;
    setState(() {
      _enviando = true;
      _erro = null;
    });
    final r = await ConteudoUsuarioService.instance.publicarArtigo(
      objetivoId: _objetivo?.id ?? '',
      categoriaId: _categoria?.id ?? '',
      nivel: _nivel,
      titulo: _titulo.text,
      resumo: _resumo.text,
      corpo: _corpo.text,
      tagsTexto: _tags.text,
    );
    if (!mounted) return;
    if (!r.ok) {
      setState(() {
        _enviando = false;
        _erro = r.erro;
      });
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context, r.valor);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Artigo publicado em "Meus artigos".')),
      );
  }

  InputDecoration _decoracao(String rotulo, {String? dica}) => InputDecoration(
    labelText: rotulo,
    hintText: dica,
    alignLabelWithHint: true,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
  );

  Widget _secao(String texto) => Padding(
    padding: const EdgeInsets.only(top: 18, bottom: 8),
    child: Text(
      texto,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Cores.tituloVerde,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Cores.fundo,
      appBar: AppBar(
        title: const Text('Escrever artigo'),
        backgroundColor: Cores.fundo,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
          children: [
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Cores.verdeClaro,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Por enquanto, o que você publica fica só neste aparelho. '
                'Quando o banco de dados existir, passa a aparecer para '
                'outras pessoas.',
                style: TextStyle(fontSize: 12, color: Cores.tituloVerde),
              ),
            ),
            _secao('Onde ele aparece'),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final o in todosOsObjetivos)
                  ChoiceChip(
                    label: Text(o.titulo),
                    selected: _objetivo?.id == o.id,
                    onSelected: (_) => setState(() {
                      if (_objetivo?.id != o.id) _categoria = null;
                      _objetivo = o;
                    }),
                  ),
              ],
            ),
            if (_objetivo != null) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final c in _objetivo!.categorias)
                    ChoiceChip(
                      label: Text(c.titulo),
                      selected: _categoria?.id == c.id,
                      onSelected: (_) => setState(() => _categoria = c),
                    ),
                ],
              ),
            ],
            _secao('Nível de dificuldade'),
            Wrap(
              spacing: 8,
              children: [
                for (var n = Artigo.nivelMinimo; n <= Artigo.nivelMaximo; n++)
                  ChoiceChip(
                    label: Text(Artigo.nomeDoNivel(n)),
                    selected: _nivel == n,
                    onSelected: (_) => setState(() => _nivel = n),
                  ),
              ],
            ),
            _secao('O texto'),
            TextField(
              controller: _titulo,
              maxLength: ConteudoUsuarioService.tituloMax,
              textCapitalization: TextCapitalization.sentences,
              decoration: _decoracao('Título'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _resumo,
              maxLength: ConteudoUsuarioService.resumoMax,
              minLines: 2,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: _decoracao(
                'Resumo',
                dica: 'Uma ou duas frases para o cartão.',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _corpo,
              minLines: 8,
              maxLines: 20,
              textCapitalization: TextCapitalization.sentences,
              decoration: _decoracao(
                'Texto do artigo',
                dica: 'Separe os parágrafos com uma linha em branco.',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _tags,
              decoration: _decoracao(
                'Assuntos (opcional)',
                dica:
                    'Separados por vírgula, até '
                    '${ConteudoUsuarioService.maxTags}.',
              ),
            ),
            if (_erro != null) ...[
              const SizedBox(height: 12),
              Text(
                _erro!,
                style: TextStyle(fontSize: 13, color: Colors.red.shade700),
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _enviando ? null : _publicar,
              style: ElevatedButton.styleFrom(
                backgroundColor: Cores.laranja,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(_enviando ? 'Publicando...' : 'Publicar'),
            ),
          ],
        ),
      ),
    );
  }
}
