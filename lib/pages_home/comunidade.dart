import 'package:flutter/material.dart';

import '../core/uso_diario.dart';
import '../data/artigo.dart';
import '../data/comunidade.dart';
import '../services/artigos_repositorio.dart';
import '../services/conteudo_usuario.dart';
import '../widgets/artigo_card.dart';
import '../widgets/estilo.dart';
import 'criar_comunidade.dart';
import 'icones_comunidade.dart';
import 'meus_artigos.dart';

class ComunidadePage extends StatelessWidget {
  const ComunidadePage({super.key});

  /// Pilar 6: entrar numa comunidade suspende os filtros pessoais, e isso
  /// precisa ser confirmado de forma explícita.
  Future<void> _entrar(BuildContext context, Comunidade c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Entrar em "${c.nome}"?'),
        content: const Text(
          'Dentro da comunidade, os filtros do seu dia ficam suspensos e '
          'você pode ver conteúdos de outras categorias. Ao sair, tudo '
          'volta ao que você escolheu.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Entrar'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => _ComunidadePage(comunidade: c)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final servico = ConteudoUsuarioService.instance;
    return ListenableBuilder(
      listenable: servico,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        children: [
          const Text(
            'Comunidades',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Cores.titulo,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Grupos pequenos, por assunto. Sem curtidas, sem ranking.',
            style: TextStyle(fontSize: 13, color: Cores.subtitulo),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CriarComunidadePage(),
                    ),
                  ),
                  icon: const Icon(Icons.group_add_outlined, size: 20),
                  label: const Text('Criar comunidade'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Cores.laranja,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(46),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MeusArtigosPage(),
                    ),
                  ),
                  icon: const Icon(Icons.edit_note_outlined, size: 20),
                  label: const Text('Meus artigos'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Cores.laranja,
                    side: const BorderSide(color: Cores.laranja),
                    minimumSize: const Size.fromHeight(46),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (final c in servico.comunidades)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _entrar(context, c),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Cores.borda),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Cores.rosado,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            iconeDaComunidade(c.iconeId),
                            color: Cores.laranja,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.nome,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Cores.titulo,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                servico.euCriei(c)
                                    ? '${c.descricao}  (criada por você)'
                                    : c.descricao,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Cores.subtitulo,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ComunidadePage extends StatefulWidget {
  final Comunidade comunidade;

  const _ComunidadePage({required this.comunidade});

  @override
  State<_ComunidadePage> createState() => _ComunidadePageState();
}

class _ComunidadePageState extends State<_ComunidadePage> {
  final _servico = ConteudoUsuarioService.instance;
  final _texto = TextEditingController();
  bool _enviando = false;
  String? _erro;

  Comunidade get _c => widget.comunidade;

  @override
  void initState() {
    super.initState();
    _servico.postsDe(_c.id).then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (_enviando) return;
    setState(() {
      _enviando = true;
      _erro = null;
    });
    final r = await _servico.postar(_c.id, _texto.text);
    if (!mounted) return;
    setState(() {
      _enviando = false;
      _erro = r.erro;
      if (r.ok) _texto.clear();
    });
  }

  Future<void> _apagarComunidade() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Apagar a comunidade?'),
        content: const Text(
          'A comunidade e todas as mensagens dela serão removidas.',
        ),
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
    if (ok != true) return;
    final apagou = await _servico.apagarComunidade(_c.id);
    if (apagou && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final List<Artigo> artigos =
        ArtigosRepositorio.dasCategorias(_c.categoriaIds);

    return Scaffold(
      backgroundColor: Cores.fundo,
      appBar: AppBar(
        title: Text(_c.nome),
        backgroundColor: Cores.fundo,
        actions: [
          if (_servico.euCriei(_c))
            IconButton(
              tooltip: 'Apagar comunidade',
              onPressed: _apagarComunidade,
              icon: const Icon(Icons.delete_outline),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Sair'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _servico,
          builder: (context, _) {
            final posts = _servico.postsEmMemoria(_c.id);
            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Cores.verdeClaro,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text(
                          'Seus filtros do dia estão suspensos enquanto você '
                          'está aqui.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Cores.tituloVerde,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Regras da comunidade',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Cores.titulo,
                        ),
                      ),
                      const SizedBox(height: 6),
                      for (final r in _c.regras)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '- $r',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Cores.subtitulo,
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                      const Text(
                        'Mural',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Cores.titulo,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (posts.isEmpty)
                        const Text(
                          'Ninguém escreveu ainda. Que tal começar?',
                          style: TextStyle(color: Cores.subtitulo),
                        )
                      else
                        for (final p in posts)
                          _PostCard(
                            post: p,
                            podeApagar:
                                _servico.euEscrevi(p) || _servico.euCriei(_c),
                            aoApagar: () =>
                                _servico.apagarPost(_c.id, p.id),
                          ),
                      const SizedBox(height: 20),
                      const Text(
                        'Leituras da comunidade',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Cores.titulo,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (artigos.isEmpty)
                        const Text(
                          'Ainda não há leituras aqui.',
                          style: TextStyle(color: Cores.subtitulo),
                        )
                      else
                        ListaDeArtigos(artigos: artigos),
                    ],
                  ),
                ),
                _caixaDeMensagem(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _caixaDeMensagem() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Cores.bordaQuente)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_erro != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                _erro!,
                style: TextStyle(fontSize: 12, color: Colors.red.shade700),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _texto,
                  maxLength: ConteudoUsuarioService.postMax,
                  minLines: 1,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Escreva para a comunidade',
                    counterText: '',
                    border: InputBorder.none,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Enviar',
                onPressed: _enviando ? null : _enviar,
                icon: const Icon(Icons.send_rounded, color: Cores.laranja),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final PostComunidade post;
  final bool podeApagar;
  final VoidCallback aoApagar;

  const _PostCard({
    required this.post,
    required this.podeApagar,
    required this.aoApagar,
  });

  @override
  Widget build(BuildContext context) {
    final quando = chaveDoDia(DateTime.fromMillisecondsSinceEpoch(post.criadoMs));
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Cores.borda),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${post.autorNome}  ·  $quando',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Cores.subtitulo,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  post.texto,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: Cores.titulo,
                  ),
                ),
              ],
            ),
          ),
          if (podeApagar)
            IconButton(
              tooltip: 'Apagar mensagem',
              onPressed: aoApagar,
              icon: const Icon(Icons.close, size: 18),
            ),
        ],
      ),
    );
  }
}
