import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ikai/core/sem_emoji.dart';

void main() {
  test('removerEmojis tira emojis e preserva acentos e pontuação', () {
    expect(removerEmojis('Olá \u{1F600} mundo!'), equals('Olá mundo!'));
    expect(removerEmojis('Treino \u{1F4AA}\u{FE0F}'), equals('Treino'));
    expect(removerEmojis('Ação, razão -> ok.'), equals('Ação, razão -> ok.'));
    expect(temEmoji('texto simples'), isFalse);
    expect(temEmoji('com \u{2705} marca'), isTrue);
  });

  // Garante que ninguém coloque emoji no código do app por engano.
  test('nenhum arquivo de lib/ contém emoji', () {
    final raiz = Directory('lib');
    expect(raiz.existsSync(), isTrue, reason: 'rode o teste na raiz do projeto');
    final achados = <String>[];
    for (final f in raiz.listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      final linhas = f.readAsLinesSync();
      for (var i = 0; i < linhas.length; i++) {
        if (temEmoji(linhas[i])) achados.add('${f.path}:${i + 1}');
      }
    }
    expect(achados, isEmpty, reason: 'emojis em: ${achados.join(', ')}');
  });
}
