import 'package:flutter_test/flutter_test.dart';
import 'package:ikai/pages_configurar/controle_objetivo.dart';
import 'package:ikai/pages_configurar/objetivo_estudo.dart';
import 'package:ikai/pages_configurar/objetivo_leitura.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late DateTime parede;
  late Duration mono;
  late ControleObjetivos c;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    parede = DateTime(2026, 11, 4, 10);
    mono = Duration.zero;
    c = ControleObjetivos.paraTeste(
      agora: () => parede,
      monotonico: () => mono,
    );
  });

  // Cancela o timer da sessão ao fim de cada teste.
  tearDown(() => c.reiniciarSessao());

  void passar(Duration d) {
    parede = parede.add(d);
    mono += d;
  }

  /// Percorre as 4 etapas escolhendo Ler > primeira categoria.
  void escolherAteUltimaEtapa({int segundos = 600}) {
    c.selecionarObjetivo(objetivoLeitura);
    c.avancar();
    c.selecionarCategoria(objetivoLeitura.categorias.first);
    c.avancar();
    c.definirDuracaoTotal(segundos);
    c.avancar();
  }

  group('Escolhas', () {
    test('não avança sem escolher o objetivo', () {
      expect(c.podeAvancar, isFalse);
      c.avancar();
      expect(c.etapa, equals(0));
    });

    test('não avança da categoria sem escolher categoria', () {
      c.selecionarObjetivo(objetivoLeitura);
      c.avancar();
      expect(c.etapa, equals(1));
      expect(c.podeAvancar, isFalse);
    });

    test('categoria de outro objetivo é ignorada', () {
      c.selecionarObjetivo(objetivoLeitura);
      c.selecionarCategoria(objetivoEstudo.categorias.first);
      expect(c.categoria, isNull);
    });

    test('trocar de objetivo invalida a categoria escolhida', () {
      c.selecionarObjetivo(objetivoLeitura);
      c.selecionarCategoria(objetivoLeitura.categorias.first);
      c.selecionarObjetivo(objetivoEstudo);
      expect(c.categoria, isNull);
    });

    test('duração zero ou acima de 3 horas bloqueia', () {
      c.selecionarObjetivo(objetivoLeitura);
      c.avancar();
      c.selecionarCategoria(objetivoLeitura.categorias.first);
      c.avancar();
      expect(c.etapa, equals(2));
      expect(c.podeAvancar, isFalse); // 0s
      c.definirDuracao(3, 0, 1);
      expect(c.podeAvancar, isFalse); // 3h e 1s
      c.definirDuracao(3, 0, 0);
      expect(c.podeAvancar, isTrue); // 3h exatas
    });

    test('opções rápidas preenchem horas, minutos e segundos', () {
      c.definirDuracaoTotal(3725);
      expect(c.horas, equals(1));
      expect(c.minutos, equals(2));
      expect(c.segundos, equals(5));
      expect(c.duracaoSegundos, equals(3725));
    });

    test('a etapa da Ik AI é opcional', () {
      escolherAteUltimaEtapa();
      expect(c.etapa, equals(ControleObjetivos.ultimaEtapa));
      expect(c.textoIkAi, equals(''));
      expect(c.podeAvancar, isTrue);
    });

    test('permissão do Gemini exige texto e some se o texto for apagado', () {
      c.definirPermissaoGemini(true);
      expect(c.permitirGemini, isFalse); // sem texto
      c.definirTextoIkAi('estou lendo um livro');
      c.definirPermissaoGemini(true);
      expect(c.permitirGemini, isTrue);
      c.definirTextoIkAi('   ');
      expect(c.permitirGemini, isFalse);
    });

    test('texto da Ik AI respeita o limite de caracteres', () {
      c.definirTextoIkAi('a' * 500);
      expect(c.textoIkAi.length, equals(ControleObjetivos.limiteTextoIkAi));
    });
  });

  group('Sessão e tempo', () {
    test('só confirma na última etapa', () async {
      c.selecionarObjetivo(objetivoLeitura);
      c.avancar();
      c.selecionarCategoria(objetivoLeitura.categorias.first);
      c.avancar();
      c.definirDuracaoTotal(600);
      expect(await c.confirmar(), isFalse); // ainda na etapa 2
      expect(c.estado, equals(EstadoSessao.naoIniciada));
    });

    test('confirmar inicia a sessão com o restante igual à duração', () async {
      escolherAteUltimaEtapa(segundos: 600);
      expect(await c.confirmar(), isTrue);
      expect(c.estado, equals(EstadoSessao.ativa));
      expect(c.restante.value, equals(const Duration(minutes: 10)));
    });

    test('o tempo corre e a sessão expira exatamente no limite', () async {
      escolherAteUltimaEtapa(segundos: 600);
      await c.confirmar();

      passar(const Duration(minutes: 9, seconds: 59));
      c.verificar();
      expect(c.estado, equals(EstadoSessao.ativa));
      expect(c.restante.value, equals(const Duration(seconds: 1)));

      passar(const Duration(seconds: 1));
      c.verificar();
      expect(c.estado, equals(EstadoSessao.expirada));
      expect(c.restante.value, equals(Duration.zero));
    });

    test('depois de expirar não há como continuar nem iniciar outra', () async {
      escolherAteUltimaEtapa(segundos: 60);
      await c.confirmar();
      passar(const Duration(minutes: 2));
      c.verificar();
      expect(c.estado, equals(EstadoSessao.expirada));

      expect(await c.confirmar(), isFalse);
      c.selecionarObjetivo(objetivoEstudo);
      expect(c.objetivo?.id, equals(objetivoLeitura.id)); // escolha ignorada
      c.verificar();
      expect(c.estado, equals(EstadoSessao.expirada));
    });

    test('voltar a hora do celular não prolonga a sessão', () async {
      escolherAteUltimaEtapa(segundos: 600);
      await c.confirmar();
      mono = const Duration(minutes: 10);
      parede = parede.subtract(const Duration(hours: 2));
      c.verificar();
      expect(c.estado, equals(EstadoSessao.expirada));
    });

    test('aparelho dormindo também consome o tempo', () async {
      escolherAteUltimaEtapa(segundos: 600);
      await c.confirmar();
      parede = parede.add(const Duration(minutes: 30));
      c.verificar(); // equivale a voltar do segundo plano
      expect(c.estado, equals(EstadoSessao.expirada));
    });

    test('não inicia uma segunda sessão enquanto há uma ativa', () async {
      escolherAteUltimaEtapa();
      expect(await c.confirmar(), isTrue);
      expect(await c.confirmar(), isFalse);
    });

    test('escolhas ficam travadas durante a sessão', () async {
      escolherAteUltimaEtapa(segundos: 600);
      await c.confirmar();
      c.definirDuracaoTotal(5);
      expect(c.duracaoSegundos, equals(600));
    });

    test('encerrar antes da hora guarda o resumo', () async {
      escolherAteUltimaEtapa(segundos: 600);
      c.definirTextoIkAi('treinando em casa');
      c.definirPermissaoGemini(true);
      await c.confirmar();
      passar(const Duration(minutes: 2));
      c.encerrarAgora();

      expect(c.estado, equals(EstadoSessao.expirada));
      final r = c.ultimoResumo!;
      expect(r.encerradaPeloUsuario, isTrue);
      expect(r.usadoSegundos, equals(120));
      expect(r.duracaoPlanejadaSegundos, equals(600));
      expect(r.objetivoTitulo, equals('Ler'));
      expect(r.textoIkAi, equals('treinando em casa'));
      expect(r.permitiuEnvioGemini, isTrue);
    });

    test('expiração natural marca que não foi o usuário', () async {
      escolherAteUltimaEtapa(segundos: 30);
      await c.confirmar();
      passar(const Duration(seconds: 31));
      c.verificar();
      final r = c.ultimoResumo!;
      expect(r.encerradaPeloUsuario, isFalse);
      expect(r.usadoSegundos, equals(30)); // nunca passa do planejado
    });

    test('reiniciar libera uma nova sessão e zera tudo', () async {
      escolherAteUltimaEtapa();
      c.definirTextoIkAi('algo');
      await c.confirmar();
      c.encerrarAgora();
      c.reiniciarSessao();

      expect(c.estado, equals(EstadoSessao.naoIniciada));
      expect(c.etapa, equals(0));
      expect(c.objetivo, isNull);
      expect(c.categoria, isNull);
      expect(c.duracaoSegundos, equals(0));
      expect(c.textoIkAi, equals(''));
      expect(c.permitirGemini, isFalse);
      expect(c.ultimoResumo, isNull);

      escolherAteUltimaEtapa(segundos: 120);
      expect(await c.confirmar(), isTrue);
      expect(c.restante.value, equals(const Duration(minutes: 2)));
    });
  });

  group('Histórico (só sugestão, nunca aplicado sozinho)', () {
    test('última escolha vira sugestão, mas as escolhas começam vazias',
        () async {
      escolherAteUltimaEtapa(segundos: 900);
      c.definirTextoIkAi('lendo Capitães da Areia');
      await c.confirmar();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      c.reiniciarSessao();

      c.descartarHistoricoEmMemoria();
      await c.carregarHistorico();

      expect(c.sugestaoObjetivoId, equals('ler'));
      expect(c.sugestaoDuracao, equals(900));
      expect(c.sugestaoTexto, equals('lendo Capitães da Areia'));
      // Nada foi aplicado:
      expect(c.objetivo, isNull);
      expect(c.duracaoSegundos, equals(0));
      expect(c.textoIkAi, equals(''));

      // Só vira escolha quando o usuário toca.
      c.aplicarSugestaoDuracao();
      expect(c.duracaoSegundos, equals(900));
      c.aplicarSugestaoTexto();
      expect(c.textoIkAi, equals('lendo Capitães da Areia'));
    });

    test('sugestão de categoria só vale para o objetivo escolhido', () async {
      escolherAteUltimaEtapa();
      await c.confirmar();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      c.reiniciarSessao();
      c.descartarHistoricoEmMemoria();
      await c.carregarHistorico();

      c.selecionarObjetivo(objetivoEstudo);
      expect(c.sugestaoCategoriaId, isNull); // a categoria salva era de "Ler"
      c.selecionarObjetivo(objetivoLeitura);
      expect(c.sugestaoCategoriaId, equals(objetivoLeitura.categorias.first.id));
    });
  });

  group('Catálogo', () {
    test('ids de categoria são únicos em todo o app', () {
      final ids = <String>[];
      for (final o in todosOsObjetivos) {
        ids.addAll(o.categorias.map((cat) => cat.id));
      }
      expect(ids.toSet().length, equals(ids.length));
    });

    test('títulos de categoria não têm erros de digitação conhecidos', () {
      final titulos = [
        for (final o in todosOsObjetivos) ...o.categorias.map((e) => e.titulo),
      ];
      expect(titulos.contains('Horro'), isFalse);
      expect(titulos.contains('Terro'), isFalse);
      expect(titulos.contains('Horror'), isTrue);
      expect(titulos.contains('Terror'), isTrue);
    });
  });
}
