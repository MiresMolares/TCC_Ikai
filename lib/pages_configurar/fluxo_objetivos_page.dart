import 'package:flutter/material.dart';

import '../pages_home/home.dart';
import '../services/artigos_repositorio.dart' show conteudosPorSessao;
import '../services/gemini_service.dart';
import '../services/tempo_diario.dart';
import '../widgets/cartao_checkin.dart';
import '../widgets/cartao_uso_semanal.dart';
import '../widgets/estilo.dart';
import '../widgets/paisagem.dart';
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

/// Categoria em QUADRADO: ícone grande, título embaixo, várias podem estar
/// marcadas ao mesmo tempo. Vira o item da grade de 2 por fileira.
class CategoriaQuadrada extends StatelessWidget {
  final Categoria categoria;
  final bool selecionada;
  final bool sugerida;
  final VoidCallback onTap;

  /// Cores do objetivo a que a categoria pertence.
  final TemaObjetivo tema;

  const CategoriaQuadrada({
    super.key,
    required this.categoria,
    required this.selecionada,
    required this.sugerida,
    required this.onTap,
    this.tema = temaPadrao,
  });

  @override
  Widget build(BuildContext context) {
    final mostrarSugestao = sugerida && !selecionada;
    return Semantics(
      button: true,
      selected: selecionada,
      label: categoria.titulo,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: selecionada ? tema.claro : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selecionada
                  ? tema.principal
                  : mostrarSugestao
                      ? const Color(0xFF8FA3B5)
                      : const Color(0xFFE0E5DF),
              width: (selecionada || mostrarSugestao) ? 2 : 1,
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          color: selecionada ? Colors.white : tema.suave,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(
                          categoria.icone,
                          color: tema.principal,
                          size: 42,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        categoria.titulo,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: tema.escuro,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Icon(
                  selecionada ? Icons.check_circle : Icons.circle_outlined,
                  color: selecionada ? tema.principal : Colors.grey.shade400,
                  size: 24,
                ),
              ),
              if (mostrarSugestao)
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDF1F3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Sugestão',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4F6275),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Grade de categorias: 2 por fileira, quadradas, seleção múltipla.
class GradeCategorias extends StatelessWidget {
  final List<Categoria> categorias;
  final bool Function(String id) estaSelecionada;
  final Set<String> sugeridas;
  final ValueChanged<Categoria> aoAlternar;
  final TemaObjetivo tema;

  /// false: a grade não rola sozinha (fica dentro de uma lista maior).
  final bool rolavel;

  const GradeCategorias({
    super.key,
    required this.categorias,
    required this.estaSelecionada,
    required this.sugeridas,
    required this.aoAlternar,
    this.tema = temaPadrao,
    this.rolavel = true,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: !rolavel,
      physics: rolavel ? null : const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: categorias.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, i) {
        final cat = categorias[i];
        return CategoriaQuadrada(
          categoria: cat,
          selecionada: estaSelecionada(cat.id),
          sugerida: sugeridas.contains(cat.id),
          onTap: () => aoAlternar(cat),
          tema: tema,
        );
      },
    );
  }
}

/// Objetivo como um lugar: a paisagem em cima, o nome embaixo. Escolher um
/// objetivo é escolher para onde ir hoje.
class ObjetivoCartao extends StatelessWidget {
  final Objetivo objetivo;
  final bool selecionado;
  final bool sugerido;
  final VoidCallback onTap;

  const ObjetivoCartao({
    super.key,
    required this.objetivo,
    required this.selecionado,
    required this.sugerido,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tema = temaDoObjetivo(objetivo.id);
    final mostrarSugestao = sugerido && !selecionado;
    final destaque = selecionado || mostrarSugestao;

    return Semantics(
      button: true,
      selected: selecionado,
      label: objetivo.titulo,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selecionado
                  ? tema.principal
                  : mostrarSugestao
                      ? const Color(0xFF8FA3B5)
                      : Cores.bordaQuente,
              width: destaque ? 3 : 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(19),
            child: Column(
              children: [
                Expanded(
                  flex: 11,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      PaisagemView(paisagem: tema.paisagem),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            selecionado
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            color: selecionado
                                ? tema.principal
                                : Colors.grey.shade400,
                            size: 24,
                          ),
                        ),
                      ),
                      if (mostrarSugestao)
                        Positioned(
                          top: 10,
                          left: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Sugestão',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4F6275),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 9,
                  child: Container(
                    width: double.infinity,
                    color: selecionado ? tema.claro : Colors.white,
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(objetivo.icone, size: 18, color: tema.principal),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                objetivo.titulo,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  height: 1.15,
                                  color: tema.escuro,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${objetivo.categorias.length} categorias',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Cores.subtitulo,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Faixa de progresso das etapas: segmentos que se enchem na cor do objetivo,
/// como um broto que vai crescendo.
class _TrilhaEtapas extends StatelessWidget {
  final int atual;
  final int total;
  final Color cor;

  const _TrilhaEtapas({
    required this.atual,
    required this.total,
    required this.cor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 0; i < total; i++)
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 6,
                  margin: EdgeInsets.only(right: i == total - 1 ? 0 : 6),
                  decoration: BoxDecoration(
                    color: i <= atual ? cor : Cores.bordaQuente,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Etapa ${atual + 1} de $total',
          style: const TextStyle(fontSize: 13, color: Cores.subtitulo),
        ),
      ],
    );
  }
}

// =====================================================
// FLUXO: OBJETIVO -> CATEGORIAS -> (FOCO -> IK AI no modo avançado)
// =====================================================

class FluxoObjetivosPage extends StatefulWidget {
  const FluxoObjetivosPage({super.key});

  @override
  State<FluxoObjetivosPage> createState() => _FluxoObjetivosPageState();
}

class _FluxoObjetivosPageState extends State<FluxoObjetivosPage> {
  final ControleObjetivos c = ControleObjetivos.instance;

  @override
  void initState() {
    super.initState();
    c.carregarHistorico();
  }

  /// A escolha foi feita: vai direto para a Home, limpando a pilha (a tela
  /// pode ter sido aberta de dentro da Home, por "Trocar categorias").
  void _irParaHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomePage()),
      (rota) => false,
    );
  }

  bool get _temSugestao {
    switch (c.etapaAtual) {
      case EtapaFluxo.objetivo:
        return c.sugestaoObjetivoId != null;
      case EtapaFluxo.categorias:
        return c.sugestaoCategoriaIds.isNotEmpty;
      case EtapaFluxo.foco:
        return c.sugestaoFoco != null;
      case EtapaFluxo.ikai:
        return c.sugestaoTexto != null;
    }
  }

  String get _titulo {
    switch (c.etapaAtual) {
      case EtapaFluxo.objetivo:
        return 'Qual é o seu objetivo?';
      case EtapaFluxo.categorias:
        return 'O que você quer ver?';
      case EtapaFluxo.foco:
        return 'Quer um lembrete de foco?';
      case EtapaFluxo.ikai:
        return 'Quer contar algo à Ik AI?';
    }
  }

  String get _subtitulo {
    switch (c.etapaAtual) {
      case EtapaFluxo.ikai:
        return 'É opcional. Quando o seu tempo do dia acabar, a Ik AI usa só '
            'o que você escrever aqui para sugerir no que investir sua '
            'energia.';
      case EtapaFluxo.foco:
        return 'É opcional e não bloqueia nada: a Ik AI só avisa quando esse '
            'tempo passar, para você decidir se faz uma pausa.';
      case EtapaFluxo.categorias:
        return 'Escolha uma ou mais categorias (até '
            '${ControleObjetivos.maxCategorias}). O feed continua com '
            '$conteudosPorSessao conteúdos, não importa quantas escolher.';
      case EtapaFluxo.objetivo:
        return _temSugestao
            ? 'Sua última escolha aparece como sugestão. '
                'Toque nela para usar ou escolha outra.'
            : 'Toque em uma opção para selecionar.';
    }
  }

  Widget _cabecalho() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
          style: const TextStyle(fontSize: 15, color: Cores.subtitulo),
        ),
        const SizedBox(height: 20),
      ],
    );
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

        final tema = temaDoObjetivo(c.objetivo?.id);
        return PopScope(
          canPop: c.etapa == 0,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) c.voltar();
          },
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              color: c.objetivo == null ? Cores.fundo : tema.suave,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TrilhaEtapas(
                        atual: c.etapa,
                        total: c.etapas.length,
                        cor: tema.principal,
                      ),
                      const SizedBox(height: 16),
                      Expanded(child: _corpo(tema)),
                      const SizedBox(height: 16),
                      _rodape(tema),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _corpo(TemaObjetivo tema) {
    switch (c.etapaAtual) {
      case EtapaFluxo.objetivo:
        final lista = todosOsObjetivos;
        // Com texto maior, os cartões ficam mais altos para o título caber.
        final fatorTexto = MediaQuery.textScalerOf(context).scale(10) / 10;
        // Primeira etapa rola inteira: traz o combinado pendente e, para
        // quem já usa de forma recorrente, os dados de uso.
        return ListView(
          children: [
            const CartaoCheckIn(),
            const CartaoUsoSemanal(),
            _cabecalho(),
            GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.82 / fatorTexto.clamp(1.0, 1.6).toDouble(),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              children: [
                for (final o in lista)
                  ObjetivoCartao(
                    objetivo: o,
                    selecionado: c.objetivo?.id == o.id,
                    sugerido: c.sugestaoObjetivoId == o.id,
                    onTap: () => c.selecionarObjetivo(o),
                  ),
              ],
            ),
          ],
        );
      case EtapaFluxo.categorias:
        final sugeridas = c.sugestaoCategoriaIds;
        final semEscolha = c.categorias.isEmpty;
        return ListView(
          children: [
            PaisagemView(
              paisagem: tema.paisagem,
              altura: 96,
              raio: BorderRadius.circular(22),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${c.objetivo!.titulo} · ${tema.lugar}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: tema.escuro,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _cabecalho(),
            Row(
              children: [
                Expanded(
                  child: Text(
                    semEscolha
                        ? 'Nenhuma categoria escolhida'
                        : '${c.categorias.length} de '
                            '${ControleObjetivos.maxCategorias} escolhidas',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Cores.subtitulo,
                    ),
                  ),
                ),
                if (sugeridas.isNotEmpty &&
                    !(sugeridas.length == c.categorias.length &&
                        sugeridas.every(c.temCategoria)))
                  TextButton.icon(
                    onPressed: c.aplicarSugestaoCategorias,
                    icon: const Icon(Icons.history, size: 18),
                    label: const Text('Usar a última escolha'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            GradeCategorias(
              rolavel: false,
              categorias: c.objetivo!.categorias,
              tema: tema,
              estaSelecionada: c.temCategoria,
              sugeridas: sugeridas,
              aoAlternar: (cat) {
                final ok = c.alternarCategoria(cat);
                if (!ok) {
                  mostrarAviso(
                    context,
                    'No máximo ${ControleObjetivos.maxCategorias} '
                    'categorias. Desmarque uma para trocar.',
                  );
                }
              },
            ),
          ],
        );
      case EtapaFluxo.foco:
        return ListView(
          children: [
            _cabecalho(),
            const _PassoFoco(),
          ],
        );
      case EtapaFluxo.ikai:
        return ListView(
          children: [
            _cabecalho(),
            const _PassoIkAi(),
          ],
        );
    }
  }

  Widget _rodape(TemaObjetivo tema) {
    final ultima = c.etapa == c.ultimaEtapa;
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
                backgroundColor: tema.principal,
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
// ETAPA (AVANÇADO): FOCO DA LEITURA
// =====================================================

/// Lembrete opcional de foco. Não limita nada: a meta do dia é o limite
/// real; este aviso só ajuda a pessoa a perceber o tempo.
class _PassoFoco extends StatelessWidget {
  const _PassoFoco();

  @override
  Widget build(BuildContext context) {
    final c = ControleObjetivos.instance;
    final meta = TempoDiarioService.instance.metaMin;
    final sugestao = c.sugestaoFoco;

    return ListenableBuilder(
      listenable: c,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE0E5DF)),
            ),
            child: Text(
              'Sua meta de hoje é $meta min no Ikai. O lembrete abaixo é '
              'só dentro dela.',
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
                color: Cores.tituloVerde,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Sem lembrete'),
                selected: c.focoMin == 0,
                selectedColor: const Color(0xFFE4EFE5),
                onSelected: (_) => c.definirFoco(0),
              ),
              for (final m in ControleObjetivos.opcoesFoco)
                ChoiceChip(
                  label: Text('$m min'),
                  selected: c.focoMin == m,
                  selectedColor: const Color(0xFFE4EFE5),
                  onSelected: (_) => c.definirFoco(m),
                ),
            ],
          ),
          if (sugestao != null && sugestao != c.focoMin) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: c.aplicarSugestaoFoco,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: const Color(0xFF8FA3B5), width: 2),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.history, color: Color(0xFF4F6275)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Sugestão: $sugestao min (toque para usar)',
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
        ],
      ),
    );
  }
}

// =====================================================
// ETAPA (AVANÇADO): IK AI (OPCIONAL)
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

        return Column(
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
                        ? 'Só quando o seu tempo do dia acabar, o texto '
                            'acima, o modo e as categorias são enviados ao '
                            'Gemini. Seu nome e e-mail nunca são enviados. '
                            'Desligado, as sugestões são geradas no seu '
                            'aparelho.'
                        : 'O Gemini ainda não está ativo neste aplicativo '
                            '(falta a chave de acesso). Por enquanto, as '
                            'sugestões são geradas no seu aparelho.',
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
        );
      },
    );
  }
}
