import 'package:flutter_test/flutter_test.dart';
import 'package:ikai/widgets/paisagens_dados.dart';

/// Confere que os desenhos das paisagens estão bem formados: cada traço é
/// uma sequência válida de operações, dentro da área de projeto (400 x 240).
void main() {
  final cenas = {
    'alvorecer': cenaAlvorecer,
    'floresta': cenaFloresta,
    'nascente': cenaNascente,
    'campo': cenaCampo,
    'entardecer': cenaEntardecer,
    'noite': cenaNoite,
  };

  // Quantidade de números que cada operação consome depois do código.
  const consumo = {0: 2, 1: 2, 2: 6, 3: 0};

  group('paisagens', () {
    cenas.forEach((nome, cena) {
      test('$nome: céu opaco e camadas suficientes', () {
        expect(cena.ceuTopo >> 24, 0xFF);
        expect(cena.ceuBase >> 24, 0xFF);
        expect(cena.camadas.length, greaterThanOrEqualTo(10));
      });

      test('$nome: traços bem formados e dentro da área', () {
        for (final camada in cena.camadas) {
          expect(camada.cor >> 24, greaterThan(0));
          final t = camada.traco;
          expect(t.isNotEmpty, isTrue);
          expect(t.first, 0.0, reason: 'todo traço começa com moveTo');
          var i = 0;
          while (i < t.length) {
            final op = t[i].toInt();
            expect(consumo.containsKey(op), isTrue, reason: 'operação $op');
            final n = consumo[op]!;
            expect(i + n, lessThan(t.length + 1), reason: 'traço cortado');
            for (var k = 0; k < n; k += 2) {
              final x = t[i + 1 + k];
              final y = t[i + 2 + k];
              expect(x >= -60 && x <= 460, isTrue, reason: '$nome x=$x');
              expect(y >= -30 && y <= 270, isTrue, reason: '$nome y=$y');
            }
            i += 1 + n;
          }
          expect(i, t.length);
        }
      });
    });
  });
}
