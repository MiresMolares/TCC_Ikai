import 'package:flutter/material.dart';

import '../data/artigo.dart';
import '../services/artigos_repositorio.dart';
import '../widgets/artigo_card.dart';
import '../widgets/estilo.dart';

class _Comunidade {
  final String id;
  final String nome;
  final String descricao;
  final IconData icone;
  final Set<String> categoriaIds;
  final List<String> regras;

  const _Comunidade({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.icone,
    required this.categoriaIds,
    required this.regras,
  });
}

/// Comunidades de exemplo. Quando houver banco de dados, vêm de lá.
const List<_Comunidade> _comunidades = [
  _Comunidade(
    id: 'historia',
    nome: 'História em pauta',
    descricao: 'Fatos, contextos e personagens que ajudam a entender o hoje.',
    icone: Icons.account_balance_outlined,
    categoriaIds: {'estudar_historia', 'ver_cultura'},
    regras: [
      'Cite sempre de onde veio a informação.',
      'Debata ideias, nunca pessoas.',
      'Sem conteúdo que incite ódio.',
    ],
  ),
  _Comunidade(
    id: 'leitores',
    nome: 'Clube de leitores',
    descricao: 'Romances, aventuras e clássicos para conversar com calma.',
    icone: Icons.menu_book_outlined,
    categoriaIds: {'ler_romance', 'ler_aventura', 'ler_biografia'},
    regras: [
      'Evite revelar o final sem avisar.',
      'Indique a leitura, não cobre a de ninguém.',
      'Respeite gostos diferentes.',
    ],
  ),
  _Comunidade(
    id: 'ciencia',
    nome: 'Curiosos da ciência',
    descricao: 'Do átomo ao cosmos, em textos curtos e sem pressa.',
    icone: Icons.science_outlined,
    categoriaIds: {
      'ver_cientifico',
      'ver_curiosidades',
      'estudar_fisica',
      'estudar_quimica',
      'estudar_biologia',
    },
    regras: [
      'Prefira fontes e estudos a opiniões soltas.',
      'Dúvida é bem-vinda; deboche não.',
    ],
  ),
  _Comunidade(
    id: 'ideias',
    nome: 'Filosofia e sociedade',
    descricao: 'Perguntas grandes, respostas abertas.',
    icone: Icons.psychology_alt_outlined,
    categoriaIds: {'estudar_filosofia', 'estudar_sociologia'},
    regras: [
      'Ouça antes de responder.',
      'Nenhum assunto vale uma ofensa.',
    ],
  ),
];

class ComunidadePage extends StatelessWidget {
  const ComunidadePage({super.key});

  /// Pilar 6: entrar numa comunidade suspende os filtros pessoais, e isso
  /// precisa ser confirmado de forma explícita.
  Future<void> _entrar(BuildContext context, _Comunidade c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Entrar em "${c.nome}"?'),
        content: const Text(
          'Dentro da comunidade, os filtros da sua sessão ficam suspensos e '
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
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
        const SizedBox(height: 16),
        for (final c in _comunidades)
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
                        child: Icon(c.icone, color: Cores.laranja),
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
                              c.descricao,
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
    );
  }
}

class _ComunidadePage extends StatelessWidget {
  final _Comunidade comunidade;

  const _ComunidadePage({required this.comunidade});

  @override
  Widget build(BuildContext context) {
    final List<Artigo> artigos =
        ArtigosRepositorio.dasCategorias(comunidade.categoriaIds);

    return Scaffold(
      backgroundColor: Cores.fundo,
      appBar: AppBar(
        title: Text(comunidade.nome),
        backgroundColor: Cores.fundo,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Sair'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Cores.verdeClaro,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              'Seus filtros de sessão estão suspensos enquanto você está '
              'aqui.',
              style: TextStyle(fontSize: 12, color: Cores.tituloVerde),
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
          for (final r in comunidade.regras)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '- $r',
                style: const TextStyle(fontSize: 13, color: Cores.subtitulo),
              ),
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
    );
  }
}
