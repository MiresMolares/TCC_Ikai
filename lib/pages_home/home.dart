import 'package:flutter/material.dart';

import '../data/artigo.dart';
import '../pages_configurar/controle_objetivo.dart';
import '../pages_configurar/fluxo_objetivos_page.dart';
import '../services/artigos_repositorio.dart';
import '../services/auth_service.dart';
import '../services/config_service.dart';
import '../services/tempo_diario.dart';
import '../core/uso_diario.dart';
import '../widgets/artigo_card.dart';
import '../widgets/cartao_checkin.dart';
import '../widgets/cartao_uso_semanal.dart';
import '../widgets/estilo.dart';
import '../widgets/navegador.dart';
import '../widgets/paisagem.dart';
import '../widgets/seletor_nivel.dart';
import 'botoes_home/notificacao.dart';
import 'biblioteca.dart';
import 'comunidade.dart';
import 'explorar.dart';
import 'ik_ai_page.dart';
import 'perfil.dart';
import 'progresso.dart';

/// Estrutura do app: cinco abas. Todas ficam montadas (IndexedStack), então
/// buscas e filtros continuam onde a pessoa deixou.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _indice = 0;

  /// Cada incremento pede para o Explorar focar o campo de busca.
  final ValueNotifier<int> _pedidoDeBusca = ValueNotifier(0);

  Route<dynamic>? _rota;

  /// Só a Home mostra o botão flutuante da Ik AI.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final rota = ModalRoute.of(context);
    if (!identical(rota, _rota)) {
      NavegadorIk.desregistrarHome(_rota);
      _rota = rota;
      NavegadorIk.registrarHome(rota);
    }
  }

  @override
  void dispose() {
    NavegadorIk.desregistrarHome(_rota);
    _pedidoDeBusca.dispose();
    super.dispose();
  }

  void _irParaBusca() {
    setState(() => _indice = 1);
    _pedidoDeBusca.value++;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Cores.fundo,
      body: SafeArea(
        child: IndexedStack(
          index: _indice,
          children: [
            InicioTab(aoBuscar: _irParaBusca),
            ExplorarPage(pedidoDeBusca: _pedidoDeBusca),
            const ComunidadePage(),
            const ProgressoPage(),
            const PerfilPage(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        height: 68,
        backgroundColor: Colors.white,
        indicatorColor: Cores.verdeClaro,
        selectedIndex: _indice,
        onDestinationSelected: (i) => setState(() => _indice = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: Cores.verde),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.search),
            selectedIcon: Icon(Icons.search, color: Cores.verde),
            label: 'Explorar',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people, color: Cores.verde),
            label: 'Comunidade',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart, color: Cores.verde),
            label: 'Progresso',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Cores.verde),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

// =====================================================
// ABA INÍCIO
// =====================================================

class InicioTab extends StatefulWidget {
  final VoidCallback aoBuscar;

  const InicioTab({super.key, required this.aoBuscar});

  @override
  State<InicioTab> createState() => _InicioTabState();
}

class _InicioTabState extends State<InicioTab> {
  final ControleObjetivos _c = ControleObjetivos.instance;
  String? _tag;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ConfigService.instance,
      builder: (context, _) => _construir(context),
    );
  }

  Widget _construir(BuildContext context) {
    final nome = AuthService.instance.usuarioAtual?.primeiroNome ?? '';
    final tema = temaDoObjetivo(_c.objetivo?.id);
    final nivel = ConfigService.instance.nivelConteudo;
    final semFiltro = ArtigosRepositorio.feedDaSessao(
      _c.objetivo?.id,
      _c.categoriaIds,
    );
    final feed = ArtigosRepositorio.feedDaSessao(
      _c.objetivo?.id,
      _c.categoriaIds,
      nivel: nivel,
    );
    final tags = ArtigosRepositorio.tagsDe(feed);
    final tagAtiva = (_tag != null && tags.contains(_tag)) ? _tag : null;
    final visiveis =
        tagAtiva == null ? feed : ArtigosRepositorio.comTag(tagAtiva, feed);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _Cabecalho(nome: nome, tema: tema, objetivo: _c.objetivo?.titulo),
        const SizedBox(height: 20),
        _CampoBuscaFalso(aoTocar: widget.aoBuscar),
        const SizedBox(height: 20),
        const CartaoCheckIn(),
        const CartaoUsoSemanal(),
        _CartaoMeta(tema: tema),
        const SizedBox(height: 12),
        const _CartaoIkAi(),
        const SizedBox(height: 24),
        Row(
          children: [
            Icon(Icons.eco_outlined, size: 22, color: tema.principal),
            const SizedBox(width: 8),
            Text(
              'Seu feed de hoje',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: tema.escuro,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          feed.length == 1
              ? 'Um conteúdo escolhido para hoje.'
              : '${feed.length} conteúdos escolhidos para hoje.',
          style: const TextStyle(fontSize: 13, color: Cores.subtitulo),
        ),
        if (semFiltro.isNotEmpty) ...[
          const SizedBox(height: 12),
          const SeletorNivel(),
        ],
        if (tags.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: const Text('Todos'),
                    selected: tagAtiva == null,
                    onSelected: (_) => setState(() => _tag = null),
                  ),
                ),
                for (final t in tags)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(t),
                      selected: tagAtiva == t,
                      onSelected: (_) => setState(() => _tag = t),
                    ),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        if (feed.isEmpty && semFiltro.isNotEmpty)
          _SemNesteNivel(nivel: nivel)
        else if (feed.isEmpty)
          const _Aviso(
            'Ainda não há conteúdos nesta categoria. Eles chegam com o '
            'banco de dados.',
          )
        else
          ListaDeArtigos(artigos: List<Artigo>.of(visiveis)),
        if (feed.isNotEmpty) _FimDoFeed(tema: tema),
      ],
    );
  }
}

class _SemNesteNivel extends StatelessWidget {
  final int nivel;

  const _SemNesteNivel({required this.nivel});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Text(
            'Ainda não há conteúdo de nível ${Artigo.nomeDoNivel(nivel).toLowerCase()} '
            'nesta categoria.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Cores.subtitulo),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => ConfigService.instance.definirNivelConteudo(0),
            child: const Text('Ver todos os níveis'),
          ),
        ],
      ),
    );
  }
}

/// Faixa do topo: a paisagem do objetivo de hoje, com a saudação por cima.
class _Cabecalho extends StatelessWidget {
  final String nome;
  final TemaObjetivo tema;

  /// Título do objetivo escolhido hoje (null enquanto não há escolha).
  final String? objetivo;

  const _Cabecalho({required this.nome, required this.tema, this.objetivo});

  @override
  Widget build(BuildContext context) {
    final inicial = nome.isEmpty ? 'I' : String.fromCharCode(nome.runes.first).toUpperCase();
    return PaisagemView(
      paisagem: tema.paisagem,
      altura: 160,
      raio: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: tema.principal, width: 2),
                  ),
                  child: Text(
                    inicial,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: tema.escuro,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Que bom ver você',
                        style: TextStyle(fontSize: 13, color: tema.escuro),
                      ),
                      Text(
                        nome.isEmpty ? 'Olá' : 'Olá, $nome',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: tema.escuro,
                        ),
                      ),
                    ],
                  ),
                ),
                _BotaoQuadrado(
                  icone: Icons.collections_bookmark_outlined,
                  dica: 'Biblioteca',
                  fundo: Colors.white,
                  cor: tema.principal,
                  aoTocar: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BibliotecaPage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _BotaoQuadrado(
                  icone: Icons.notifications_none_rounded,
                  dica: 'Notificações',
                  fundo: Colors.white,
                  cor: Cores.titulo,
                  aoTocar: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificacaoPage(),
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            if (objetivo != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '$objetivo · ${tema.lugar}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: tema.escuro,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BotaoQuadrado extends StatelessWidget {
  final IconData icone;
  final String dica;
  final Color fundo;
  final Color cor;
  final VoidCallback aoTocar;

  const _BotaoQuadrado({
    required this.icone,
    required this.dica,
    required this.fundo,
    required this.cor,
    required this.aoTocar,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: dica,
      child: Material(
        color: fundo,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: aoTocar,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icone, color: cor, size: 26),
          ),
        ),
      ),
    );
  }
}

/// Parece um campo de busca, mas só leva para a aba Explorar (onde a busca
/// acontece de verdade, já com o teclado aberto).
class _CampoBuscaFalso extends StatelessWidget {
  final VoidCallback aoTocar;

  const _CampoBuscaFalso({required this.aoTocar});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(19),
      child: InkWell(
        borderRadius: BorderRadius.circular(19),
        onTap: aoTocar,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(19),
            border: Border.all(color: Cores.borda),
          ),
          child: const Row(
            children: [
              Icon(Icons.search, color: Cores.titulo),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Buscar no seu feed de hoje',
                  style: TextStyle(fontSize: 14, color: Cores.subtitulo),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Atalho para conversar com a Ik AI quando a pessoa quiser ideias do que
/// fazer longe da tela.
class _CartaoIkAi extends StatelessWidget {
  const _CartaoIkAi();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: abrirIkAi,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Cores.bordaQuente),
          ),
          child: const Row(
            children: [
              Icon(Icons.chat_bubble_outline, color: Cores.laranja),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Conversar com a Ik AI',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Cores.titulo,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Sem ideia do que fazer longe da tela? Conte o que '
                      'você tem vontade.',
                      style: TextStyle(fontSize: 12, color: Cores.subtitulo),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

/// O tempo de hoje: quanto falta da meta que a PESSOA escolheu, o que ela
/// está vendo, e as duas saídas: trocar as categorias ou encerrar o dia.
class _CartaoMeta extends StatelessWidget {
  final TemaObjetivo tema;

  const _CartaoMeta({required this.tema});

  Future<void> _encerrar(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Encerrar por hoje?'),
        content: const Text(
          'A Ik AI vai conversar com você sobre o que você aprendeu e '
          'depois o app descansa até amanhã.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Continuar aqui'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Encerrar'),
          ),
        ],
      ),
    );
    if (ok == true) TempoDiarioService.instance.abrirFimVoluntario();
  }

  void _trocarCategorias(BuildContext context) {
    ControleObjetivos.instance.reiniciarSessao();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const FluxoObjetivosPage()),
      (rota) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = TempoDiarioService.instance;
    final c = ControleObjetivos.instance;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tema.suave,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tema.claro, width: 2),
      ),
      child: Row(
        children: [
          ValueListenableBuilder<int>(
            valueListenable: t.usadoHoje,
            builder: (context, _, __) => SizedBox(
              width: 92,
              height: 92,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 92,
                    height: 92,
                    child: CircularProgressIndicator(
                      value: 1 - t.fracaoUsada.clamp(0.0, 1.0),
                      strokeWidth: 8,
                      color: tema.principal,
                      backgroundColor: tema.claro,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formatarHm(t.restanteSeg),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: tema.principal,
                        ),
                      ),
                      const Text(
                        'restam',
                        style:
                            TextStyle(fontSize: 10, color: Cores.subtitulo),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SEU TEMPO DE HOJE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: tema.principal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  c.titulosDasCategorias.isEmpty
                      ? 'Sem categoria'
                      : c.titulosDasCategorias,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Cores.titulo,
                  ),
                ),
                ValueListenableBuilder<int>(
                  valueListenable: t.usadoHoje,
                  builder: (context, _, __) => Text(
                    'Meta de ${formatarHm(t.limiteHojeSeg)} por dia',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Cores.subtitulo,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 14,
                  children: [
                    _LinkPequeno(
                      'Trocar categorias',
                      () => _trocarCategorias(context),
                      tema.principal,
                    ),
                    _LinkPequeno(
                      'Encerrar o dia',
                      () => _encerrar(context),
                      tema.principal,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkPequeno extends StatelessWidget {
  final String texto;
  final VoidCallback aoTocar;
  final Color cor;

  const _LinkPequeno(this.texto, this.aoTocar, this.cor);

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: aoTocar,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: cor,
      ),
      child: Text(
        texto,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ),
    );
  }
}

class _Aviso extends StatelessWidget {
  final String texto;

  const _Aviso(this.texto);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Text(
        texto,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Cores.subtitulo),
      ),
    );
  }
}

/// O feed acaba. Esse cartão existe para que a pessoa perceba isso.
class _FimDoFeed extends StatelessWidget {
  final TemaObjetivo tema;

  const _FimDoFeed({required this.tema});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tema.claro,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.eco_outlined, color: tema.principal, size: 32),
          const SizedBox(height: 8),
          Text(
            'Você chegou ao fim do feed',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: tema.escuro,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Não há mais nada para rolar. Faça uma pausa, ou volte a um '
            'artigo que você quer reler.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Cores.subtitulo),
          ),
        ],
      ),
    );
  }
}
