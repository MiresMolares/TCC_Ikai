import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';

import '../data/artigo.dart';
import '../pages_configurar/controle_objetivo.dart';
import '../services/artigos_repositorio.dart';
import '../services/config_service.dart';
import '../widgets/artigo_card.dart';
import '../widgets/estilo.dart';
import '../widgets/seletor_nivel.dart';

/// Busca DENTRO do modo da sessão: o que está fora do modo escolhido não
/// aparece aqui.
class ExplorarPage extends StatefulWidget {
  /// Cada mudança de valor pede o foco no campo de busca.
  final ValueListenable<int> pedidoDeBusca;

  const ExplorarPage({super.key, required this.pedidoDeBusca});

  @override
  State<ExplorarPage> createState() => _ExplorarPageState();
}

class _ExplorarPageState extends State<ExplorarPage> {
  final TextEditingController _busca = TextEditingController();
  final FocusNode _foco = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.pedidoDeBusca.addListener(_focar);
  }

  @override
  void dispose() {
    widget.pedidoDeBusca.removeListener(_focar);
    _busca.dispose();
    _foco.dispose();
    super.dispose();
  }

  void _focar() => _foco.requestFocus();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ConfigService.instance,
      builder: (context, _) => _construir(context),
    );
  }

  Widget _construir(BuildContext context) {
    final c = ControleObjetivos.instance;
    final base = ArtigosRepositorio.doNivel(
      ArtigosRepositorio.doModo(c.objetivo?.id, c.categoria?.id),
      ConfigService.instance.nivelConteudo,
    );
    final consulta = _busca.text.trim();
    final List<Artigo> resultado = ArtigosRepositorio.buscar(consulta, base);
    final tags = ArtigosRepositorio.tagsDe(base);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        const Text(
          'Explorar',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Cores.titulo,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Buscando em ${c.categoria?.titulo ?? 'sua sessão'}.',
          style: const TextStyle(fontSize: 13, color: Cores.subtitulo),
        ),
        const SizedBox(height: 12),
        const SeletorNivel(),
        const SizedBox(height: 14),
        TextField(
          controller: _busca,
          focusNode: _foco,
          onChanged: (_) => setState(() {}),
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            suffixIcon: consulta.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Limpar',
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(_busca.clear),
                  ),
            hintText: 'Título, autor ou assunto',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(19),
              borderSide: const BorderSide(color: Cores.borda),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(19),
              borderSide: const BorderSide(color: Cores.borda),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (consulta.isEmpty && tags.isNotEmpty) ...[
          const Text(
            'Assuntos',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Cores.titulo,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in tags)
                ActionChip(
                  label: Text(t),
                  onPressed: () => setState(() => _busca.text = t),
                ),
            ],
          ),
        ] else if (resultado.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 32),
            child: Text(
              'Nada encontrado. Tente outra palavra.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Cores.subtitulo),
            ),
          )
        else ...[
          Text(
            resultado.length == 1
                ? '1 resultado'
                : '${resultado.length} resultados',
            style: const TextStyle(fontSize: 13, color: Cores.subtitulo),
          ),
          const SizedBox(height: 10),
          ListaDeArtigos(artigos: resultado),
        ],
      ],
    );
  }
}
