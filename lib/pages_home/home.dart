import 'package:flutter/material.dart';

import '../data/artigo.dart';
import '../pages_configurar/controle_objetivo.dart';
import '../pages_configurar/sessao_guard.dart';
import '../services/artigos_repositorio.dart';
import '../services/auth_service.dart';
import '../services/config_service.dart';
import '../widgets/artigo_card.dart';
import '../widgets/estilo.dart';
import '../widgets/seletor_nivel.dart';
import 'botoes_home/notificacao.dart';
import 'biblioteca.dart';
import 'comunidade.dart';
import 'explorar.dart';
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

  @override
  void dispose() {
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
    final nivel = ConfigService.instance.nivelConteudo;
    final semFiltro = ArtigosRepositorio.feedDaSessao(
      _c.objetivo?.id,
      _c.categoria?.id,
    );
    final feed = ArtigosRepositorio.feedDaSessao(
      _c.objetivo?.id,
      _c.categoria?.id,
      nivel: nivel,
    );
    final tags = ArtigosRepositorio.tagsDe(feed);
    final tagAtiva = (_tag != null && tags.contains(_tag)) ? _tag : null;
    final visiveis =
        tagAtiva == null ? feed : ArtigosRepositorio.comTag(tagAtiva, feed);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _Cabecalho(nome: nome),
        const SizedBox(height: 20),
        _CampoBuscaFalso(aoTocar: widget.aoBuscar),
        const SizedBox(height: 20),
        const _CartaoSessao(),
        const SizedBox(height: 24),
        const Text(
          'Seu feed de hoje',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Cores.titulo,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          feed.length == 1
              ? 'Um conteúdo escolhido para esta sessão.'
              : '${feed.length} conteúdos escolhidos para esta sessão.',
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
        if (feed.isNotEmpty) const _FimDoFeed(),
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

class _Cabecalho extends StatelessWidget {
  final String nome;

  const _Cabecalho({required this.nome});

  @override
  Widget build(BuildContext context) {
    final inicial = nome.isEmpty ? 'I' : String.fromCharCode(nome.runes.first).toUpperCase();
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Cores.bege,
            border: Border.all(color: Cores.bege, width: 3),
          ),
          child: Text(
            inicial,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Cores.tituloVerde,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Que bom ver você',
                style: TextStyle(fontSize: 13, color: Cores.subtitulo),
              ),
              Text(
                nome.isEmpty ? 'Olá' : 'Olá, $nome',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Cores.titulo,
                ),
              ),
            ],
          ),
        ),
        _BotaoQuadrado(
          icone: Icons.collections_bookmark_outlined,
          dica: 'Biblioteca',
          fundo: Cores.verdeClaro,
          cor: Cores.verde,
          aoTocar: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BibliotecaPage()),
          ),
        ),
        const SizedBox(width: 8),
        _BotaoQuadrado(
          icone: Icons.notifications_none_rounded,
          dica: 'Notificações',
          fundo: Colors.white,
          cor: Cores.titulo,
          borda: true,
          aoTocar: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NotificacaoPage()),
          ),
        ),
      ],
    );
  }
}

class _BotaoQuadrado extends StatelessWidget {
  final IconData icone;
  final String dica;
  final Color fundo;
  final Color cor;
  final bool borda;
  final VoidCallback aoTocar;

  const _BotaoQuadrado({
    required this.icone,
    required this.dica,
    required this.fundo,
    required this.cor,
    required this.aoTocar,
    this.borda = false,
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
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: borda ? Border.all(color: Cores.borda, width: 2) : null,
            ),
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
                  'Buscar nesta sessão',
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

class _CartaoSessao extends StatelessWidget {
  const _CartaoSessao();

  Future<void> _encerrar(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Encerrar a sessão agora?'),
        content: const Text(
          'Você verá as sugestões da Ik AI e, para voltar ao feed, precisará '
          'iniciar uma nova sessão.',
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
    if (ok == true) ControleObjetivos.instance.encerrarAgora();
  }

  @override
  Widget build(BuildContext context) {
    final c = ControleObjetivos.instance;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Cores.rosado,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          ValueListenableBuilder<Duration>(
            valueListenable: c.restante,
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
                      value: 1 - c.fracaoUsada.clamp(0.0, 1.0),
                      strokeWidth: 8,
                      color: Cores.laranja,
                      backgroundColor: Cores.bege,
                    ),
                  ),
                  const TempoRestante(
                    estilo: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Cores.laranja,
                    ),
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
                const Text(
                  'SESSÃO EM ANDAMENTO',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Cores.verde,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  c.categoria?.titulo ?? 'Sem categoria',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Cores.titulo,
                  ),
                ),
                Text(
                  'Limite de ${formatarDuracao(c.duracaoTotal.inSeconds)}',
                  style: const TextStyle(fontSize: 13, color: Cores.subtitulo),
                ),
                const SizedBox(height: 6),
                TextButton(
                  onPressed: () => _encerrar(context),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: Cores.laranja,
                  ),
                  child: const Text(
                    'Encerrar sessão',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
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
  const _FimDoFeed();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Cores.verdeClaro,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          Icon(Icons.check_circle_outline, color: Cores.verde, size: 32),
          SizedBox(height: 8),
          Text(
            'Você chegou ao fim do feed',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Cores.tituloVerde,
            ),
          ),
          SizedBox(height: 4),
          Text(
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
