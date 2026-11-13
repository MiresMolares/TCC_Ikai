import 'package:flutter_test/flutter_test.dart';
import 'package:ikai/core/sem_emoji.dart';
import 'package:ikai/core/uso_diario.dart';
import 'package:ikai/services/tempo_diario.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late DateTime agora;
  final s = TempoDiarioService.instance;

  Future<void> entrar({String email = 'a@x.com'}) async {
    await s.carregarPara(email);
    s.agora = () => agora;
  }

  Future<void> gravado() => Future<void>.delayed(Duration.zero);

  setUp(() async {
    // Deixa terminar as gravações pendentes do teste anterior.
    await Future<void>.delayed(const Duration(milliseconds: 10));
    SharedPreferences.setMockInitialValues({});
    agora = DateTime(2026, 11, 11, 9);
    s.agora = () => agora;
    await entrar();
  });

  group('Meta', () {
    test('sem meta: nada é contado e a fase é semMeta', () {
      expect(s.metaDefinida, isFalse);
      expect(s.fase, FaseDoDia.semMeta);
      s.tick(100);
      expect(s.usadoHojeSeg, 0);
    });

    test('valores fora de 10 a 240 min são recusados', () {
      expect(s.definirMeta(5), ResultadoMeta.invalida);
      expect(s.definirMeta(241), ResultadoMeta.invalida);
      expect(s.metaDefinida, isFalse);
      expect(s.definirMeta(45, avancado: true), ResultadoMeta.aplicadaAgora);
      expect(s.metaMin, 45);
      expect(s.avancado, isTrue);
      expect(s.fase, FaseDoDia.dentro);
    });

    test('diminuir vale na hora; aumentar só a partir de amanhã', () {
      s.definirMeta(60);
      expect(s.definirMeta(30), ResultadoMeta.aplicadaAgora);
      expect(s.metaMin, 30);
      expect(s.definirMeta(90), ResultadoMeta.aPartirDeAmanha);
      expect(s.metaMin, 30);
      expect(s.metaDeAmanhaMin, 90);

      agora = DateTime(2026, 11, 12, 8);
      s.tick(1); // virou o dia
      expect(s.metaMin, 90);
      expect(s.metaDeAmanhaMin, isNull);
    });
  });

  group('Metade, fim e prorrogação', () {
    setUp(() => s.definirMeta(20)); // 1200 s

    test('aviso na metade aparece uma vez só', () {
      s.tick(599);
      expect(s.aviso, isNull);
      s.tick(1);
      expect(s.aviso?.tipo, TipoAviso.metade);
      expect(s.aviso!.texto, contains('metade'));
      expect(s.aviso!.texto, contains('10 min de 20 min'));
      s.consumirAviso();
      expect(s.aviso, isNull);
      s.tick(100);
      expect(s.aviso, isNull);
    });

    test('ao acabar, a conversa de fim abre e a contagem para', () {
      s.tick(1199);
      expect(s.fase, FaseDoDia.dentro);
      s.tick(1);
      expect(s.fase, FaseDoDia.fimDeTempo);
      expect(s.fimVoluntario, isFalse);
      expect(s.aviso, isNull);
      s.tick(500);
      expect(s.usadoHojeSeg, 1200);
    });

    test('continuar exige motivo, tempo válido e tem limite de 2 por dia', () {
      s.tick(1200);
      expect(s.prorrogar(15, ''), isFalse);
      expect(s.prorrogar(15, 'ok'), isFalse); // curto demais
      expect(s.prorrogar(7, 'quero terminar o capítulo'), isFalse);
      expect(s.fase, FaseDoDia.fimDeTempo);

      expect(s.prorrogar(15, 'quero terminar o capítulo'), isTrue);
      expect(s.fase, FaseDoDia.dentro);
      expect(s.limiteHojeSeg, 1200 + 900);
      expect(s.prorrogacoesRestantes, 1);

      s.tick(900); // chega no novo limite
      expect(s.fase, FaseDoDia.fimDeTempo);
      expect(s.prorrogar(10, 'falta pouco para acabar'), isTrue);
      s.tick(600);
      expect(s.fase, FaseDoDia.fimDeTempo);
      expect(s.podeProrrogar, isFalse);
      expect(s.prorrogar(10, 'mais um pouquinho'), isFalse);
      expect(s.limiteHojeSeg, 1200 + 900 + 600);
    });

    test('o motivo e o aprendizado ficam registrados, sem emoji', () {
      s.tick(1200);
      expect(s.registrarAprendizado('   '), isFalse);
      expect(s.registrarAprendizado('aprendi sobre Roma \u{1F600}'), isTrue);
      expect(s.prorrogar(10, 'terminar o texto \u{1F600}'), isTrue);
      final r = s.reflexoes;
      expect(r.length, 2);
      expect(r[0].tipo, 'aprendi');
      expect(r[0].texto, 'aprendi sobre Roma');
      expect(r[1].tipo, 'continuar');
      expect(temEmoji(r[1].texto), isFalse);
      expect(r[1].dia, '2026-11-11');
    });

    test('texto muito longo é cortado', () {
      s.tick(1200);
      s.registrarAprendizado('a' * 1000);
      expect(s.reflexoes.last.texto.length, TempoDiarioService.limiteTexto);
    });

    test('encerrar por hoje trava até o dia seguinte', () {
      s.tick(1200);
      s.encerrarPorHoje();
      expect(s.fase, FaseDoDia.encerrado);
      s.tick(100);
      expect(s.usadoHojeSeg, 1200);
      expect(s.prorrogar(10, 'quero mais um pouco'), isFalse);

      agora = DateTime(2026, 11, 12, 7);
      s.tick(1);
      expect(s.fase, FaseDoDia.dentro);
      expect(s.usadoHojeSeg, 1);
      expect(s.prorrogacoesFeitas, 0);
      expect(s.extraHojeSeg, 0);
    });

    test('voltar a hora do celular não destrava o dia', () {
      s.tick(1200);
      s.encerrarPorHoje();
      agora = DateTime(2026, 11, 10, 9); // ontem
      s.tick(5);
      expect(s.fase, FaseDoDia.encerrado);
      expect(s.usadoHojeSeg, 1200);
    });

    test('fim voluntário: pode voltar ao app, mas não ganha tempo extra', () {
      s.tick(300);
      s.abrirFimVoluntario();
      expect(s.fase, FaseDoDia.fimDeTempo);
      expect(s.fimVoluntario, isTrue);
      expect(s.prorrogar(10, 'quero continuar'), isFalse);
      expect(s.voltarAoApp(), isTrue);
      expect(s.fase, FaseDoDia.dentro);
      expect(s.limiteHojeSeg, 1200);
      expect(s.voltarAoApp(), isFalse); // já voltou
    });

    test('voltarAoApp não serve quando o tempo acabou de verdade', () {
      s.tick(1200);
      expect(s.voltarAoApp(), isFalse);
      expect(s.fase, FaseDoDia.fimDeTempo);
    });
  });

  group('Foco da leitura (modo avançado)', () {
    test('avisa quando o tempo planejado passa, uma vez, sem travar', () {
      s.definirMeta(60);
      s.tick(120);
      s.definirFoco(5);
      s.tick(299);
      expect(s.aviso, isNull);
      s.tick(1);
      expect(s.aviso?.tipo, TipoAviso.foco);
      expect(s.aviso!.texto, contains('5 min'));
      s.consumirAviso();
      s.tick(60);
      expect(s.aviso, isNull);
      expect(s.fase, FaseDoDia.dentro);
    });

    test('foco 0 desliga', () {
      s.definirMeta(60);
      s.definirFoco(5);
      s.definirFoco(0);
      s.tick(600);
      expect(s.aviso, isNull);
    });
  });

  group('Balanço semanal', () {
    test('só aparece para uso recorrente e uma vez por semana', () {
      s.definirMeta(45);
      s.tick(600);
      expect(s.usoRecorrente, isFalse);
      expect(s.balancoPendente, isFalse);

      agora = DateTime(2026, 11, 12, 9); // quinta
      s.tick(600);
      expect(s.usoRecorrente, isTrue);
      expect(s.balancoPendente, isTrue);

      s.registrarBalanco(RespostaBalanco.ganhando, texto: 'gosto do feed');
      expect(s.balancoPendente, isFalse);
      expect(s.balancoDestaSemana?.resposta, RespostaBalanco.ganhando);
      expect(s.balancos.length, 1);

      // Responder de novo na mesma semana substitui, não duplica.
      s.registrarBalanco(RespostaBalanco.maisOuMenos);
      expect(s.balancos.length, 1);
      expect(s.balancoDestaSemana?.resposta, RespostaBalanco.maisOuMenos);

      agora = DateTime(2026, 11, 17, 9); // semana seguinte
      s.tick(600);
      expect(s.balancoPendente, isTrue);
    });

    test('nomes das respostas, sem emoji', () {
      for (final r in RespostaBalanco.values) {
        expect(temEmoji(nomeDoBalanco(r)), isFalse);
      }
    });

    test('resumo semanal usa a meta da pessoa', () {
      s.definirMeta(30);
      s.tick(40 * 60);
      final r = s.resumoSemanal;
      expect(r.totalSeg, 40 * 60);
      expect(r.metaSeg, 30 * 60);
      expect(r.texto, contains('Hoje você usou o Ikai por 40 min'));
    });
  });

  group('Persistência', () {
    test('meta, modo, uso e estado do dia voltam ao entrar de novo', () async {
      s.definirMeta(20, avancado: true);
      s.tick(1200); // dispara o fim e grava
      s.encerrarPorHoje();
      await gravado();

      s.limpar();
      expect(s.metaDefinida, isFalse);
      await entrar();
      expect(s.metaMin, 20);
      expect(s.avancado, isTrue);
      expect(s.usadoHojeSeg, 1200);
      expect(s.fase, FaseDoDia.encerrado);
    });

    test('o fim aberto continua aberto se o app for fechado', () async {
      s.definirMeta(20);
      s.tick(1200);
      await gravado();
      await entrar();
      expect(s.fase, FaseDoDia.fimDeTempo);
    });

    test('prorrogação e reflexões persistem', () async {
      s.definirMeta(20);
      s.tick(1200);
      s.registrarAprendizado('aprendi algo');
      s.prorrogar(15, 'preciso terminar');
      await gravado();
      await entrar();
      expect(s.limiteHojeSeg, 1200 + 900);
      expect(s.prorrogacoesFeitas, 1);
      expect(s.reflexoes.length, 2);
      expect(s.fase, FaseDoDia.dentro);
    });

    test('contas não se misturam', () async {
      s.definirMeta(20);
      s.tick(100);
      await gravado();
      await entrar(email: 'b@x.com');
      expect(s.metaDefinida, isFalse);
      expect(s.usadoHojeSeg, 0);
      await entrar(email: 'a@x.com');
      expect(s.metaMin, 20);
      expect(s.usadoHojeSeg, 100);
    });

    test('virou o dia com o app fechado: o dia novo começa limpo', () async {
      s.definirMeta(20);
      s.tick(1200);
      s.encerrarPorHoje();
      await gravado();
      agora = DateTime(2026, 11, 13, 10);
      await entrar();
      expect(s.fase, FaseDoDia.dentro);
      expect(s.usadoHojeSeg, 0);
      expect(s.resumoSemanal.totalSeg, 1200); // o histórico fica
    });

    test('dados corrompidos não quebram', () async {
      SharedPreferences.setMockInitialValues({'tempo_v1_a@x.com': '{lixo'});
      await entrar();
      expect(s.metaDefinida, isFalse);
      SharedPreferences.setMockInitialValues({
        'tempo_v1_a@x.com': '{"meta":9999,"uso":"x","dia":5,"refl":[1]}',
      });
      await entrar();
      expect(s.metaDefinida, isFalse);
      expect(s.reflexoes, isEmpty);
    });

    test('apagarDaConta remove tudo', () async {
      s.definirMeta(20);
      s.tick(100);
      await gravado();
      await s.apagarDaConta();
      await entrar();
      expect(s.metaDefinida, isFalse);
    });

    test('exportarJson traz o que a pessoa contou', () {
      s.definirMeta(20);
      s.tick(1200);
      s.registrarAprendizado('aprendi sobre Roma');
      expect(s.exportarJson(), contains('aprendi sobre Roma'));
    });
  });

  group('Textos', () {
    test('aviso de foco sem emoji', () {
      expect(temEmoji(TempoDiarioService.textoDoFoco(15)), isFalse);
    });

    test('restante e fração', () {
      s.definirMeta(20);
      s.tick(300);
      expect(s.restanteSeg, 900);
      expect((s.fracaoUsada - 0.25).abs() < 0.001, isTrue);
      s.tick(5000);
      expect(s.restanteSeg, 0);
      expect(s.fracaoUsada, 1.0);
    });

    test('chaves de dia usadas no registro', () {
      expect(chaveDoDia(agora), '2026-11-11');
    });
  });
}
