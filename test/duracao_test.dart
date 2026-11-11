import 'package:flutter_test/flutter_test.dart';
import 'package:ikai/core/duracao.dart';

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
}
