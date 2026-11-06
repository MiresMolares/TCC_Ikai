import 'package:flutter_test/flutter_test.dart';
import 'package:ikai/core/sessao_salva.dart';
import 'package:ikai/pages_configurar/controle_objetivo.dart';
import 'package:ikai/pages_configurar/objetivo_leitura.dart';
import 'package:shared_preferences/shared_preferences.dart';

SessaoSalva _salva({int total = 600, int ini = 1000, int vis = 1000}) =>
    SessaoSalva(
      objetivoId: 'ler',
      categoriaId: 'ler_romance',
      texto: 'lendo um livro',
      permitirGemini: false,
      totalSegundos: total,
      inicioMs: ini,
      vistoMs: vis,
    );

void main() {
  group('SessaoSalva (modelo)', () {
    test('ida e volta em JSON preserva tudo', () {
      final s = _salva().comoEncerrada(usadoSegundos: 42, peloUsuario: true);
      final l = SessaoSalva.tentarLer(s.toJson())!;
      expect(l.objetivoId, 'ler');
      expect(l.categoriaId, 'ler_romance');
      expect(l.texto, 'lendo um livro');
      expect(l.totalSegundos, 600);
      expect(l.encerrada, isTrue);
      expect(l.usadoSegundos, 42);
      expect(l.peloUsuario, isTrue);
    });

    test('texto lixo, vazio ou com tipos errados vira null', () {
      expect(SessaoSalva.tentarLer(null), isNull);
      expect(SessaoSalva.tentarLer(''), isNull);
      expect(SessaoSalva.tentarLer('nao e json'), isNull);
      expect(SessaoSalva.tentarLer('[1,2]'), isNull);
      expect(SessaoSalva.tentarLer('{"o":1}'), isNull);
    });

    test('duração fora do limite é rejeitada', () {
      final ruim = _salva(total: 99999).toJson();
      expect(SessaoSalva.tentarLer(ruim), isNull);
    });

    test('voltar a hora não devolve tempo', () {
      final s = _salva(ini: 0, vis: 300000); // visto aos 5 min
      // "agora" voltou para o minuto 1: continua contando 5 min
      expect(s.decorridoEm(60000), const Duration(minutes: 5));
      expect(s.decorridoEm(400000), const Duration(milliseconds: 400000));
    });

    test('decorrido nunca é negativo', () {
      final s = _salva(ini: 5000, vis: 5000);
      expect(s.decorridoEm(0), Duration.zero);
    });
  });

  group('Sessão sobrevive ao fechar o app', () {
    late DateTime parede;
    late Duration mono;

    ControleObjetivos novo() => ControleObjetivos.paraTeste(
          agora: () => parede,
          monotonico: () => mono,
        );

    void iniciar(ControleObjetivos c, {int segundos = 600}) {
      c.selecionarObjetivo(objetivoLeitura);
      c.avancar();
      c.selecionarCategoria(objetivoLeitura.categorias.first);
      c.avancar();
      c.definirDuracaoTotal(segundos);
      c.avancar();
      c.definirTextoIkAi('lendo um livro');
    }

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      parede = DateTime(2026, 11, 6, 10);
      mono = Duration.zero;
    });

    test('reabrir no meio continua do mesmo ponto', () async {
      final a = novo();
      iniciar(a);
      expect(await a.confirmar(), isTrue);
      parede = parede.add(const Duration(minutes: 4));
      mono += const Duration(minutes: 4);
      a.verificar();
      await Future<void>.delayed(Duration.zero);
      a.descartarSessaoEmMemoria(); // app fechado

      parede = parede.add(const Duration(minutes: 3)); // ficou fechado 3 min
      final b = novo();
      await b.restaurarSessao();
      expect(b.estado, EstadoSessao.ativa);
      expect(b.restante.value, const Duration(minutes: 3));
      expect(b.categoria?.id, objetivoLeitura.categorias.first.id);
      expect(b.textoIkAi, 'lendo um livro');
      b.reiniciarSessao();
    });

    test('reabrir depois do fim mostra sessão expirada, sem tempo novo',
        () async {
      final a = novo();
      iniciar(a);
      await a.confirmar();
      await Future<void>.delayed(Duration.zero);
      a.descartarSessaoEmMemoria();

      parede = parede.add(const Duration(hours: 2)); // muito depois do fim
      final b = novo();
      await b.restaurarSessao();
      expect(b.estado, EstadoSessao.expirada);
      expect(b.ultimoResumo, isNotNull);
      expect(b.ultimoResumo!.usadoSegundos, 600);
      b.reiniciarSessao();
    });

    test('sessão encerrada fica encerrada ao reabrir', () async {
      final a = novo();
      iniciar(a);
      await a.confirmar();
      parede = parede.add(const Duration(minutes: 1));
      mono += const Duration(minutes: 1);
      a.encerrarAgora();
      await Future<void>.delayed(Duration.zero);
      a.descartarSessaoEmMemoria();

      final b = novo();
      await b.restaurarSessao();
      expect(b.estado, EstadoSessao.expirada);
      expect(b.ultimoResumo!.encerradaPeloUsuario, isTrue);
      expect(b.ultimoResumo!.usadoSegundos, 60);
      b.reiniciarSessao();
    });

    test('voltar a hora do celular depois de fechar não ganha tempo',
        () async {
      final a = novo();
      iniciar(a);
      await a.confirmar();
      parede = parede.add(const Duration(minutes: 5));
      mono += const Duration(minutes: 5);
      a.verificar(); // grava "visto" aos 5 min
      await Future<void>.delayed(Duration.zero);
      a.descartarSessaoEmMemoria();

      parede = parede.subtract(const Duration(minutes: 8)); // hora voltada
      final b = novo();
      await b.restaurarSessao();
      expect(b.estado, EstadoSessao.ativa);
      expect(b.restante.value, const Duration(minutes: 5));
      b.reiniciarSessao();
    });

    test('"Iniciar nova sessão" apaga a gravada', () async {
      final a = novo();
      iniciar(a);
      await a.confirmar();
      await Future<void>.delayed(Duration.zero);
      a.reiniciarSessao();
      await Future<void>.delayed(Duration.zero);

      final b = novo();
      await b.restaurarSessao();
      expect(b.estado, EstadoSessao.naoIniciada);
    });

    test('sem nada gravado, nada acontece', () async {
      final b = novo();
      await b.restaurarSessao();
      expect(b.estado, EstadoSessao.naoIniciada);
    });
  });
}
