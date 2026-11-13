import 'package:flutter_test/flutter_test.dart';
import 'package:ikai/pages_configurar/controle_objetivo.dart';
import 'package:ikai/widgets/paisagem.dart';

void main() {
  group('identidade visual', () {
    test('todo objetivo tem o seu tema, com paisagem própria', () {
      final paisagens = <Paisagem>{};
      for (final o in todosOsObjetivos) {
        final tema = temaDoObjetivo(o.id);
        expect(tema.id, o.id, reason: 'sem tema para ${o.id}');
        paisagens.add(tema.paisagem);
      }
      expect(paisagens.length, todosOsObjetivos.length);
    });

    test('sem objetivo, vale o tema padrão', () {
      expect(identical(temaDoObjetivo(null), temaPadrao), isTrue);
      expect(identical(temaDoObjetivo('nao_existe'), temaPadrao), isTrue);
    });
  });
}
