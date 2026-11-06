import 'package:flutter_test/flutter_test.dart';
import 'package:ikai/core/sessao_salva.dart';
import 'package:ikai/pages_configurar/controle_objetivo.dart';
import 'package:ikai/pages_configurar/objetivo_leitura.dart';
import 'package:ikai/services/config_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late DateTime parede;
  late Duration mono;

  ControleObjetivos novo({int pausa = 10}) => ControleObjetivos.paraTeste(
        agora: () => parede,
        monotonico: () => mono,
        pausaMinutos: () => pausa,
      );

  void passar(Duration d) {
    parede = parede.add(d);
    mono += d;
  }

  Future<void> iniciar(ControleObjetivos c, {int segundos = 600}) async {
    c.selecionarObjetivo(objetivoLeitura);
    c.avancar();
    c.selecionarCategoria(objetivoLeitura.categorias.first);
    c.avancar();
    c.definirDuracaoTotal(segundos);
    c.avancar();
    expect(await c.confirmar(), isTrue);
  }

  Future<void> gravar() => Future<void>.delayed(Duration.zero);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    parede = DateTime(2026, 11, 6, 10);
    mono = Duration.zero;
  });

  group('Pausa obrigatória', () {
    test('ao acabar o tempo começa a pausa e a nova sessão fica barrada',
        () async {
      final c = novo();
      await iniciar(c);
      passar(const Duration(seconds: 601));
      c.verificar();
      expect(c.estado, EstadoSessao.expirada);
      expect(c.emPausa, isTrue);
      expect(c.pausaRestante.value.inMinutes >= 9 && c.pausaRestante.value.inMinutes <= 10, isTrue, reason: '${c.pausaRestante.value.inMinutes} min');

      expect(c.iniciarNovaSessao(), isFalse);
      expect(c.estado, EstadoSessao.expirada);
      c.reiniciarSessao();
    });

    test('passada a pausa, a nova sessão abre', () async {
      final c = novo();
      await iniciar(c);
      passar(const Duration(seconds: 601));
      c.verificar();
      passar(const Duration(minutes: 10));
      c.atualizarPausa();
      expect(c.emPausa, isFalse);
      expect(c.iniciarNovaSessao(), isTrue);
      expect(c.estado, EstadoSessao.naoIniciada);
      expect(c.pausaRestante.value, Duration.zero);
    });

    test('encerrar antes do tempo também gera pausa', () async {
      final c = novo(pausa: 5);
      await iniciar(c);
      passar(const Duration(minutes: 1));
      c.encerrarAgora();
      expect(c.emPausa, isTrue);
      expect(c.pausaRestante.value.inMinutes >= 4 && c.pausaRestante.value.inMinutes <= 5, isTrue, reason: '${c.pausaRestante.value.inMinutes} min');
      c.reiniciarSessao();
    });

    test('a duração da pausa vem da configuração', () async {
      final c = novo(pausa: 30);
      await iniciar(c);
      passar(const Duration(seconds: 601));
      c.verificar();
      expect(c.pausaRestante.value.inMinutes >= 29 && c.pausaRestante.value.inMinutes <= 30, isTrue, reason: '${c.pausaRestante.value.inMinutes} min');
      c.reiniciarSessao();
    });

    test('voltar a hora do celular não encurta a pausa', () async {
      final c = novo();
      await iniciar(c);
      passar(const Duration(seconds: 601));
      c.verificar();
      passar(const Duration(minutes: 2));
      c.atualizarPausa();
      final antes = c.pausaRestante.value;

      parede = parede.subtract(const Duration(hours: 5)); // adianta/atrasa
      c.atualizarPausa();
      expect(c.pausaRestante.value >= antes - const Duration(seconds: 1),
          isTrue);
      expect(c.iniciarNovaSessao(), isFalse);
      c.reiniciarSessao();
    });

    test('fechar e reabrir o app durante a pausa não zera a pausa', () async {
      final a = novo();
      await iniciar(a);
      passar(const Duration(seconds: 601));
      a.verificar();
      await gravar();
      a.descartarSessaoEmMemoria(); // app fechado

      passar(const Duration(minutes: 4));
      final b = novo();
      await b.restaurarSessao();
      expect(b.estado, EstadoSessao.expirada);
      expect(b.emPausa, isTrue);
      expect(b.pausaRestante.value.inMinutes >= 5 && b.pausaRestante.value.inMinutes <= 6, isTrue, reason: '${b.pausaRestante.value.inMinutes} min');
      expect(b.iniciarNovaSessao(), isFalse);

      passar(const Duration(minutes: 7));
      expect(b.iniciarNovaSessao(), isTrue);
    });

    test('sair da conta e entrar de novo mantém a pausa', () async {
      final a = novo();
      await iniciar(a);
      passar(const Duration(seconds: 601));
      a.verificar();
      await gravar();
      a.descartarSessaoEmMemoria(); // aoSair

      final b = novo();
      await b.restaurarSessao(); // aoEntrar, logo em seguida
      expect(b.emPausa, isTrue);
      expect(b.iniciarNovaSessao(), isFalse);
      b.reiniciarSessao();
    });

    test('app fechado durante a sessão: o tempo longe da tela conta como '
        'pausa', () async {
      final a = novo();
      await iniciar(a);
      await gravar();
      a.descartarSessaoEmMemoria();

      // A sessão acabou aos 10 min; o app só reabre aos 14 min.
      passar(const Duration(minutes: 14));
      final b = novo();
      await b.restaurarSessao();
      expect(b.estado, EstadoSessao.expirada);
      expect(b.pausaRestante.value.inMinutes >= 5 && b.pausaRestante.value.inMinutes <= 6, isTrue, reason: '${b.pausaRestante.value.inMinutes} min');
      b.reiniciarSessao();
    });

    test('app reaberto muito depois: sem pausa pendente', () async {
      final a = novo();
      await iniciar(a);
      await gravar();
      a.descartarSessaoEmMemoria();

      passar(const Duration(hours: 3));
      final b = novo();
      await b.restaurarSessao();
      expect(b.estado, EstadoSessao.expirada);
      expect(b.emPausa, isFalse);
      expect(b.iniciarNovaSessao(), isTrue);
    });

    test('reiniciar (excluir conta) apaga a pausa gravada', () async {
      final a = novo();
      await iniciar(a);
      passar(const Duration(seconds: 601));
      a.verificar();
      await gravar();
      a.reiniciarSessao();
      await gravar();

      final b = novo();
      await b.restaurarSessao();
      expect(b.estado, EstadoSessao.naoIniciada);
      expect(b.emPausa, isFalse);
    });
  });

  group('SessaoSalva e configuração da pausa', () {
    test('pausaAteMs faz ida e volta; dado antigo sem pausa vira 0', () {
      const base = SessaoSalva(
        objetivoId: 'ler',
        categoriaId: 'ler_romance',
        texto: '',
        permitirGemini: false,
        totalSegundos: 600,
        inicioMs: 1000,
        vistoMs: 1000,
      );
      final s = base.comoEncerrada(
        usadoSegundos: 600,
        peloUsuario: false,
        pausaAteMs: 5000,
      );
      expect(SessaoSalva.tentarLer(s.toJson())!.pausaAteMs, 5000);

      final antigo = s.toJson().replaceAll(',"pau":5000', '');
      expect(antigo.contains('pau'), isFalse);
      expect(SessaoSalva.tentarLer(antigo)!.pausaAteMs, 0);
    });

    test('pausaRestanteEm usa o maior entre agora e visto', () {
      const s = SessaoSalva(
        objetivoId: 'ler',
        categoriaId: 'ler_romance',
        texto: '',
        permitirGemini: false,
        totalSegundos: 600,
        inicioMs: 0,
        vistoMs: 4000,
        encerrada: true,
        pausaAteMs: 10000,
      );
      expect(s.pausaRestanteEm(1000), const Duration(milliseconds: 6000));
      expect(s.pausaRestanteEm(9000), const Duration(milliseconds: 1000));
      expect(s.pausaRestanteEm(20000), Duration.zero);
    });

    test('ConfigService: padrão 10, só aceita as opções, persiste', () async {
      SharedPreferences.setMockInitialValues({});
      final cfg = ConfigService.instance;
      await cfg.carregar();
      expect(cfg.pausaMinutos, 10);
      await cfg.definirPausaMinutos(0);
      await cfg.definirPausaMinutos(3);
      expect(cfg.pausaMinutos, 10);
      await cfg.definirPausaMinutos(15);
      expect(cfg.pausaMinutos, 15);
      await cfg.definirPausaMinutos(1); // volta ao ler do disco
      await cfg.carregar();
      expect(cfg.pausaMinutos, 15);
      expect(ConfigService.opcoesPausa.contains(0), isFalse);
      await cfg.definirPausaMinutos(10);
    });
  });
}
