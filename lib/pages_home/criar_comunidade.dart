import 'package:flutter/material.dart';

import '../data/comunidade.dart';
import '../pages_configurar/controle_objetivo.dart';
import '../services/conteudo_usuario.dart';
import '../widgets/estilo.dart';
import 'icones_comunidade.dart';

/// Formulário para criar uma comunidade: nome, descrição, ícone, categorias
/// e regras. Quem cria pode apagar a comunidade e qualquer mensagem nela.
class CriarComunidadePage extends StatefulWidget {
  const CriarComunidadePage({super.key});

  @override
  State<CriarComunidadePage> createState() => _CriarComunidadePageState();
}

class _CriarComunidadePageState extends State<CriarComunidadePage> {
  final _nome = TextEditingController();
  final _descricao = TextEditingController();
  final _regras = TextEditingController();

  String _icone = iconesDeComunidade.keys.first;
  final Set<String> _categorias = {};
  bool _enviando = false;
  String? _erro;

  @override
  void dispose() {
    _nome.dispose();
    _descricao.dispose();
    _regras.dispose();
    super.dispose();
  }

  Future<void> _criar() async {
    if (_enviando) return;
    setState(() {
      _enviando = true;
      _erro = null;
    });
    final r = await ConteudoUsuarioService.instance.criarComunidade(
      nome: _nome.text,
      descricao: _descricao.text,
      iconeId: _icone,
      categoriaIds: _categorias,
      regrasTexto: _regras.text,
    );
    if (!mounted) return;
    if (!r.ok) {
      setState(() {
        _enviando = false;
        _erro = r.erro;
      });
      return;
    }
    Navigator.pop<Comunidade>(context, r.valor);
  }

  InputDecoration _decoracao(String rotulo, {String? dica}) => InputDecoration(
    labelText: rotulo,
    hintText: dica,
    alignLabelWithHint: true,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
  );

  Widget _secao(String texto, [String? ajuda]) => Padding(
    padding: const EdgeInsets.only(top: 18, bottom: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          texto,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Cores.tituloVerde,
          ),
        ),
        if (ajuda != null)
          Text(
            ajuda,
            style: const TextStyle(fontSize: 12, color: Cores.subtitulo),
          ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Cores.fundo,
      appBar: AppBar(
        title: const Text('Criar comunidade'),
        backgroundColor: Cores.fundo,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
          children: [
            Container(
              margin: const EdgeInsets.only(top: 4, bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Cores.verdeClaro,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Por enquanto, a comunidade existe só neste aparelho. '
                'Quando o banco de dados existir, outras pessoas poderão '
                'entrar.',
                style: TextStyle(fontSize: 12, color: Cores.tituloVerde),
              ),
            ),
            TextField(
              controller: _nome,
              maxLength: ConteudoUsuarioService.nomeMax,
              textCapitalization: TextCapitalization.sentences,
              decoration: _decoracao('Nome'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descricao,
              maxLength: ConteudoUsuarioService.descricaoMax,
              minLines: 2,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: _decoracao(
                'Descrição',
                dica: 'Sobre o que vocês conversam?',
              ),
            ),
            _secao('Ícone'),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final e in iconesDeComunidade.entries)
                  InkWell(
                    onTap: () => setState(() => _icone = e.key),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: _icone == e.key
                            ? const Color(0xFFE4EFE5)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _icone == e.key
                              ? Cores.laranja
                              : const Color(0xFFE0E5DF),
                          width: _icone == e.key ? 2 : 1,
                        ),
                      ),
                      child: Icon(e.value, color: Cores.laranja),
                    ),
                  ),
              ],
            ),
            _secao(
              'Categorias',
              'De 1 a ${ConteudoUsuarioService.maxCategoriasComunidade}. '
                  'São as leituras que a comunidade reúne.',
            ),
            for (final o in todosOsObjetivos) ...[
              Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 4),
                child: Text(
                  o.titulo,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Cores.subtitulo,
                  ),
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final c in o.categorias)
                    FilterChip(
                      label: Text(c.titulo),
                      selected: _categorias.contains(c.id),
                      onSelected: (marcar) => setState(() {
                        if (!marcar) {
                          _categorias.remove(c.id);
                        } else if (_categorias.length <
                            ConteudoUsuarioService.maxCategoriasComunidade) {
                          _categorias.add(c.id);
                        } else {
                          mostrarAviso(
                            context,
                            'No máximo '
                            '${ConteudoUsuarioService.maxCategoriasComunidade}'
                            ' categorias.',
                          );
                        }
                      }),
                    ),
                ],
              ),
            ],
            _secao(
              'Regras (opcional)',
              'Uma por linha, até ${ConteudoUsuarioService.maxRegras}. A '
                  'regra "${ConteudoUsuarioService.regraBase}" entra sempre.',
            ),
            TextField(
              controller: _regras,
              minLines: 3,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
              decoration: _decoracao('Regras'),
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
              onPressed: _enviando ? null : _criar,
              style: ElevatedButton.styleFrom(
                backgroundColor: Cores.laranja,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(_enviando ? 'Criando...' : 'Criar comunidade'),
            ),
          ],
        ),
      ),
    );
  }
}
