import 'package:flutter_test/flutter_test.dart';
import 'package:ikai/core/duracao.dart';
import 'package:ikai/core/relogio_sessao.dart';

void main() {
  group('Duração', () {
    test('zero e negativo são inválidos', () {
      expect(duracaoValida(0), isFalse);
      expect(duracaoValida(-5), isFalse);
    });

    test('limite máximo de 3 horas é válido, 1 segundo a mais não', () {
      expect(duracaoValida(1), isTrue);
      expect(duracaoValida(duracaoMaximaSegundos), isTrue);
      expect(duracaoValida(duracaoMaximaSegundos + 1), isFalse);
    });

    test('formatarDuracao', () {
      expect(formatarDuracao(0), equals('0s'));
      expect(formatarDuracao(45), equals('45s'));
      expect(formatarDuracao(600), equals('10min'));
      expect(formatarDuracao(3725), equals('1h 2min 5s'));
    });

    test('formatarRelogio', () {
      expect(formatarRelogio(const Duration(seconds: 3)), equals('00:00:03'));
      expect(
        formatarRelogio(const Duration(hours: 1, minutes: 2, seconds: 5)),
        equals('01:02:05'),
      );
    });
  });

  group('RelogioSessao', () {
    late DateTime parede;
    late Duration mono;
    late RelogioSessao r;

    setUp(() {
      parede = DateTime(2026, 11, 4, 10);
      mono = Duration.zero;
      r = RelogioSessao(agora: () => parede, monotonico: () => mono);
    });

    void passar(Duration d) {
      parede = parede.add(d);
      mono += d;
    }

    test('antes de iniciar não há tempo decorrido nem expiração', () {
      expect(r.decorrido, equals(Duration.zero));
      expect(r.expirou, isFalse);
    });

    test('conta regressiva normal', () {
      r.iniciar(const Duration(minutes: 10));
      passar(const Duration(minutes: 3));
      expect(r.restante, equals(const Duration(minutes: 7)));
      expect(r.expirou, isFalse);
    });

    test('expira exatamente no fim e o restante nunca fica negativo', () {
      r.iniciar(const Duration(minutes: 10));
      passar(const Duration(minutes: 9, seconds: 59));
      expect(r.expirou, isFalse);
      passar(const Duration(seconds: 1));
      expect(r.expirou, isTrue);
      passar(const Duration(hours: 5));
      expect(r.restante, equals(Duration.zero));
    });

    test('voltar a hora do celular NÃO ganha tempo', () {
      r.iniciar(const Duration(minutes: 10));
      mono = const Duration(minutes: 4);
      parede = parede.subtract(const Duration(hours: 1)); // hora trocada
      expect(r.decorrido, equals(const Duration(minutes: 4)));
      expect(r.restante, equals(const Duration(minutes: 6)));
    });

    test('aparelho dormindo conta (relógio de parede avança, monotônico não)',
        () {
      r.iniciar(const Duration(minutes: 10));
      parede = parede.add(const Duration(minutes: 20));
      mono = const Duration(minutes: 1);
      expect(r.expirou, isTrue);
    });

    test('fração usada vai de 0 a 1', () {
      r.iniciar(const Duration(minutes: 10));
      expect(r.fracaoUsada, equals(0.0));
      passar(const Duration(minutes: 5));
      expect(r.fracaoUsada, equals(0.5));
      passar(const Duration(hours: 1));
      expect(r.fracaoUsada, equals(1.0));
    });

    test('zerar volta ao estado inicial', () {
      r.iniciar(const Duration(minutes: 10));
      passar(const Duration(minutes: 3));
      r.zerar();
      expect(r.iniciado, isFalse);
      expect(r.expirou, isFalse);
      expect(r.restante, equals(Duration.zero));
    });
  });
}
