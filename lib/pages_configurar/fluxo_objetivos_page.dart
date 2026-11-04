import 'package:flutter/material.dart';

import '../pages_home/home.dart';
import '../services/gemini_service.dart';
import '../widgets/estilo.dart';
import 'controle_objetivo.dart';

// =====================================================
// CARTÕES DE OPÇÃO
// =====================================================

/// Card de opção usado nas etapas. Três estados visuais:
/// normal (borda cinza), sugerido (borda azulada + selo "Sugestão")
/// e selecionado (fundo verde claro, borda laranja, check).
class OpcaoCard extends StatelessWidget {
  final String titulo;
  final IconData icone;
  final bool selecionado;
  final bool sugerido;
  final VoidCallback onTap;

  const OpcaoCard({
    super.key,
    required this.titulo,
    required this.icone,
    required this.selecionado,
    required this.sugerido,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final mostrarSugestao = sugerido && !selecionado;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selecionado ? const Color(0xFFE4EFE5) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selecionado
                ? Cores.laranja
                : mostrarSugestao
                    ? const Color(0xFF8FA3B5)
                    : const Color(0xFFE0E5DF),
            width: (selecionado || mostrarSugestao) ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: selecionado
                    ? const Color(0xFFD0E3D2)
                    : const Color(0xFFF0F3EE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icone, color: Cores.laranja, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                titulo,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Cores.tituloVerde,
                ),
              ),
            ),
            if (mostrarSugestao)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDF1F3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Sugestão',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4F6275),
                  ),
                ),
              ),
            Icon(
              selecionado ? Icons.check_circle : Icons.circle_outlined,
              color: selecionado ? Cores.laranja : Colors.grey.shade400,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

/// Lista rolável de categorias.
class ListaCategorias extends StatelessWidget {
  final List<Categoria> categorias;
  final String? selecionadaId;
  final String? sugeridaId;
  final ValueChanged<Categoria> aoSelecionar;

  const ListaCategorias({
    super.key,
    required this.categorias,
    required this.selecionadaId,
    required this.sugeridaId,
    required this.aoSelecionar,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: categorias.length,
      separatorBuilder: (context, indice) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final cat = categorias[i];
        return OpcaoCard(
          titulo: cat.titulo,
          icone: cat.icone,
          selecionado: selecionadaId == cat.id,
          sugerido: sugeridaId == cat.id,
          onTap: () => aoSelecionar(cat),
        );
      },
    );
  }
}

// =====================================================
// FLUXO: OBJETIVO -> CATEGORIA -> DURAÇÃO -> IK AI
// =====================================================

class FluxoObjetivosPage extends StatefulWidget {
  const FluxoObjetivosPage({super.key});

  @override
  State<FluxoObjetivosPage> createState() => _FluxoObjetivosPageState();
}

class _FluxoObjetivosPageState extends State<FluxoObjetivosPage> {
  final ControleObjetivos c = ControleObjetivos.instance;

  static const int _totalEtapas = ControleObjetivos.ultimaEtapa + 1;

  @override
  void initState() {
    super.initState();
    c.carregarHistorico();
  }

  /// A sessão já está rodando: vai direto para a Home, sem tela de espera
  /// que gaste o tempo que o usuário escolheu.
  void _irParaHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomePage()),
    );
  }

  bool get _temSugestao {
    switch (c.etapa) {
      case 0:
        return c.sugestaoObjetivoId != null;
      case 1:
        return c.sugestaoCategoriaId != null;
      case 2:
        return c.sugestaoDuracao != null;
      default:
        return c.sugestaoTexto != null;
    }
  }

  String get _titulo {
    switch (c.etapa) {
      case 0:
        return 'Qual é o seu objetivo?';
      case 1:
        return 'Qual categoria você quer?';
      case 2:
        return 'Por quanto tempo?';
      default:
        return 'Quer contar algo à Ik AI?';
    }
  }

  String get _subtitulo {
    if (c.etapa == ControleObjetivos.ultimaEtapa) {
      return 'É opcional. Quando o tempo acabar, a Ik AI usa só o que você '
          'escrever aqui para sugerir no que investir sua energia.';
    }
    return _temSugestao
        ? 'Sua última escolha aparece como sugestão. '
            'Toque nela para usar ou escolha outra.'
        : 'Toque em uma opção para selecionar.';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        if (!c.historicoCarregado) {
          return const Scaffold(
            backgroundColor: Cores.fundoEtapas,
            body: Center(
              child: CircularProgressIndicator(color: Cores.laranja),
            ),
          );
        }

        return PopScope(
          canPop: c.etapa == 0,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) c.voltar();
          },
          child: Scaffold(
            backgroundColor: Cores.fundoEtapas,
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      color: const Color(0xFFEDF1F3),
                      child: Text(
                        'Etapa ${c.etapa + 1} de $_totalEtapas',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _titulo,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Cores.tituloVerde,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _subtitulo,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Cores.subtitulo,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Expanded(child: _conteudo()),
                    const SizedBox(height: 16),
                    _rodape(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _conteudo() {
    switch (c.etapa) {
      case 0:
        final lista = todosOsObjetivos;
        return ListView.separated(
          itemCount: lista.length,
          separatorBuilder: (context, indice) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final o = lista[i];
            return OpcaoCard(
              titulo: o.titulo,
              icone: o.icone,
              selecionado: c.objetivo?.id == o.id,
              sugerido: c.sugestaoObjetivoId == o.id,
              onTap: () => c.selecionarObjetivo(o),
            );
          },
        );
      case 1:
        return ListaCategorias(
          categorias: c.objetivo!.categorias,
          selecionadaId: c.categoria?.id,
          sugeridaId: c.sugestaoCategoriaId,
          aoSelecionar: c.selecionarCategoria,
        );
      case 2:
        return const _PassoDuracao();
      default:
        return const _PassoIkAi();
    }
  }

  Widget _rodape() {
    final ultima = c.etapa == ControleObjetivos.ultimaEtapa;
    return Row(
      children: [
        if (c.etapa > 0) ...[
          SizedBox(
            height: 54,
            child: OutlinedButton(
              onPressed: c.voltar,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFE0E5DF)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Icon(Icons.arrow_back, color: Cores.tituloVerde),
            ),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: c.podeAvancar
                  ? () async {
                      if (!ultima) {
                        c.avancar();
                        return;
                      }
                      final ok = await c.confirmar();
                      if (ok && mounted) _irParaHome();
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Cores.laranja,
                disabledBackgroundColor: const Color(0xFFCAD5CA),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                ultima ? 'Confirmar e entrar' : 'Continuar',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// =====================================================
// ETAPA 3: DURAÇÃO
// =====================================================

/// Opções rápidas + ajuste fino (horas 0 a 3, minutos e segundos).
class _PassoDuracao extends StatelessWidget {
  const _PassoDuracao();

  static const List<(int, String)> _rapidas = [
    (300, '5 min'),
    (600, '10 min'),
    (900, '15 min'),
    (1800, '30 min'),
    (2700, '45 min'),
    (3600, '1 h'),
    (7200, '2 h'),
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ControleObjetivos.instance,
      builder: (context, _) => _conteudo(),
    );
  }

  Widget _conteudo() {
    final c = ControleObjetivos.instance;
    final total = c.duracaoSegundos;
    final sugestao = c.sugestaoDuracao;

    String? erro;
    if (total == 0) {
      erro = 'Escolha uma duração maior que zero.';
    } else if (total > duracaoMaximaSegundos) {
      erro = 'O máximo permitido é 3 horas.';
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE0E5DF)),
            ),
            child: Column(
              children: [
                const Text(
                  'Duração selecionada',
                  style: TextStyle(fontSize: 13, color: Cores.subtitulo),
                ),
                const SizedBox(height: 6),
                Text(
                  formatarDuracao(total),
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: erro == null ? Cores.laranja : Colors.red.shade400,
                  ),
                ),
                if (erro != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    erro,
                    style: TextStyle(fontSize: 13, color: Colors.red.shade400),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (segundos, rotulo) in _rapidas)
                ChoiceChip(
                  label: Text(rotulo),
                  selected: total == segundos,
                  selectedColor: const Color(0xFFE4EFE5),
                  onSelected: (_) => c.definirDuracaoTotal(segundos),
                ),
            ],
          ),
          if (sugestao != null && sugestao != total) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: c.aplicarSugestaoDuracao,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF8FA3B5),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.history, color: Color(0xFF4F6275)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Sugestão: ${formatarDuracao(sugestao)} '
                        '(toque para usar)',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4F6275),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          const Text(
            'Ajuste fino',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Cores.subtitulo,
            ),
          ),
          _linhaSlider(
            'Horas',
            c.horas,
            3,
            (v) => c.definirDuracao(v, c.minutos, c.segundos),
          ),
          _linhaSlider(
            'Minutos',
            c.minutos,
            59,
            (v) => c.definirDuracao(c.horas, v, c.segundos),
          ),
          _linhaSlider(
            'Segundos',
            c.segundos,
            59,
            (v) => c.definirDuracao(c.horas, c.minutos, v),
          ),
          const SizedBox(height: 8),
          const Text(
            'Depois de confirmar, o limite não pode ser estendido. '
            'Para continuar, você começa uma nova sessão.',
            style: TextStyle(fontSize: 12, color: Cores.subtitulo),
          ),
        ],
      ),
    );
  }

  Widget _linhaSlider(
    String rotulo,
    int valor,
    int max,
    ValueChanged<int> aoMudar,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 74,
          child: Text(
            rotulo,
            style: const TextStyle(fontSize: 14, color: Cores.tituloVerde),
          ),
        ),
        Expanded(
          child: Slider(
            value: valor.toDouble(),
            min: 0,
            max: max.toDouble(),
            divisions: max,
            activeColor: Cores.laranja,
            onChanged: (v) => aoMudar(v.round()),
          ),
        ),
        SizedBox(
          width: 28,
          child: Text(
            '$valor',
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Cores.tituloVerde,
            ),
          ),
        ),
      ],
    );
  }
}

// =====================================================
// ETAPA 4: IK AI (OPCIONAL)
// =====================================================

class _PassoIkAi extends StatefulWidget {
  const _PassoIkAi();

  @override
  State<_PassoIkAi> createState() => _PassoIkAiState();
}

class _PassoIkAiState extends State<_PassoIkAi> {
  final ControleObjetivos c = ControleObjetivos.instance;
  late final TextEditingController _texto =
      TextEditingController(text: c.textoIkAi);

  static const List<String> _exemplos = [
    'lendo um livro',
    'treinando em casa',
    'aprendendo um idioma',
  ];

  @override
  void initState() {
    super.initState();
    c.addListener(_sincronizar);
  }

  @override
  void dispose() {
    c.removeListener(_sincronizar);
    _texto.dispose();
    super.dispose();
  }

  /// Mantém o campo igual ao controlador (ex.: ao tocar na sugestão).
  void _sincronizar() {
    if (_texto.text == c.textoIkAi) return;
    _texto.value = TextEditingValue(
      text: c.textoIkAi,
      selection: TextSelection.collapsed(offset: c.textoIkAi.length),
    );
  }

  void _anexar(String frase) {
    final atual = c.textoIkAi.trim();
    c.definirTextoIkAi(atual.isEmpty ? frase : '$atual, $frase');
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        final temTexto = c.textoIkAi.trim().isNotEmpty;
        final geminiPronto = GeminiService.padrao.configurado;
        final sugestao = c.sugestaoTexto;

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _texto,
                maxLength: ControleObjetivos.limiteTextoIkAi,
                minLines: 3,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                onChanged: c.definirTextoIkAi,
                decoration: InputDecoration(
                  hintText: 'Ex.: estou lendo Capitães da Areia, treinando '
                      'em casa e aprendendo francês',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE0E5DF)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE0E5DF)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide:
                        const BorderSide(color: Cores.laranja, width: 1.5),
                  ),
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final e in _exemplos)
                    ActionChip(
                      label: Text(e),
                      onPressed: () => _anexar(e),
                    ),
                ],
              ),
              if (sugestao != null && sugestao != c.textoIkAi.trim()) ...[
                const SizedBox(height: 12),
                InkWell(
                  onTap: c.aplicarSugestaoTexto,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF8FA3B5),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.history, color: Color(0xFF4F6275)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Sugestão: "$sugestao" (toque para usar)',
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4F6275),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE0E5DF)),
                ),
                child: SwitchListTile(
                  value: c.permitirGemini,
                  onChanged: (temTexto && geminiPronto)
                      ? c.definirPermissaoGemini
                      : null,
                  activeTrackColor: Cores.verde,
                  title: const Text(
                    'Usar o Gemini (Google) nas sugestões',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Cores.tituloVerde,
                    ),
                  ),
                  subtitle: Text(
                    geminiPronto
                        ? 'Só ao final da sessão, o texto acima, o modo e a '
                            'duração são enviados ao Gemini. Seu nome e '
                            'e-mail nunca são enviados. Desligado, as '
                            'sugestões são geradas no seu aparelho.'
                        : 'O Gemini ainda não foi configurado neste '
                            'aplicativo. As sugestões serão geradas no '
                            'seu aparelho.',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'A Ik AI não deduz nada sobre você: ela usa exatamente o '
                'que você escrever.',
                style: TextStyle(fontSize: 12, color: Cores.subtitulo),
              ),
            ],
          ),
        );
      },
    );
  }
}
