import 'package:flutter_test/flutter_test.dart';
import 'package:ikai/core/sem_emoji.dart';
import 'package:ikai/core/texto.dart';
import 'package:ikai/data/artigos_dados.dart';
import 'package:ikai/pages_configurar/controle_objetivo.dart';
import 'package:ikai/services/artigos_repositorio.dart';
import 'package:ikai/services/sugestoes_locais.dart';

void main() {
  group('Sugestões locais (plano B da Ik AI)', () {
    test('exemplo do projeto: leitura, treino e francês', () {
      final s = SugestoesLocais.gerar(
        texto: 'Estou lendo Capitães da Areia, treinando em casa e '
            'buscando me tornar fluente em francês',
        objetivoTitulo: 'Ler',
      );
      expect(s.length, equals(3));
      expect(s[0], contains('Capitães da Areia'));
      expect(s[0], contains('leia'));
      expect(s[1], contains('treino'));
      expect(s[2], contains('francês'));
      expect(s[2], contains('prática'));
    });

    test('sem texto, devolve 3 sugestões genéricas', () {
      final s = SugestoesLocais.gerar(texto: '', objetivoTitulo: 'Estudar');
      expect(s.length, equals(3));
      expect(s[0], contains('exercícios'));
    });

    test('com um só interesse, completa até 3', () {
      final s = SugestoesLocais.gerar(texto: 'academia');
      expect(s.length, equals(3));
      expect(s[0], contains('treino'));
    });

    test('mais de 3 interesses: usa só os 3 primeiros', () {
      final s = SugestoesLocais.gerar(
        texto: 'academia, inglês, escrever letras, estudar para a prova',
      );
      expect(s.length, equals(3));
    });

    test('nunca devolve emojis, nem quando o usuário escreve emojis', () {
      final s = SugestoesLocais.gerar(texto: 'treinando \u{1F4AA} e lendo');
      for (final item in s) {
        expect(temEmoji(item), isFalse);
      }
    });
  });

  group('Artigos', () {
    test('ids de artigo são únicos', () {
      final ids = artigosDados.map((a) => a.id).toList();
      expect(ids.toSet().length, equals(ids.length));
    });

    test('todo artigo aponta para objetivo e categoria que existem', () {
      for (final a in artigosDados) {
        final objetivo = buscarObjetivo(a.objetivoId);
        expect(objetivo, isNotNull, reason: 'objetivo de ${a.id}');
        expect(
          objetivo!.buscarCategoria(a.categoriaId),
          isNotNull,
          reason: 'categoria de ${a.id} (${a.categoriaId})',
        );
      }
    });

    test('toda categoria tem pelo menos um artigo (nenhum feed vazio)', () {
      for (final o in todosOsObjetivos) {
        for (final cat in o.categorias) {
          expect(
            ArtigosRepositorio.doModo(o.id, cat.id).isNotEmpty,
            isTrue,
            reason: 'sem artigos em ${cat.id}',
          );
        }
      }
    });

    test('campos obrigatórios preenchidos e sem emojis', () {
      for (final a in artigosDados) {
        expect(a.titulo.trim().isNotEmpty, isTrue, reason: a.id);
        expect(a.autor.trim().isNotEmpty, isTrue, reason: a.id);
        expect(a.resumo.trim().isNotEmpty, isTrue, reason: a.id);
        expect(a.tags.isNotEmpty, isTrue, reason: a.id);
        expect(a.paragrafos.isNotEmpty, isTrue, reason: a.id);
        final tudo = '${a.titulo} ${a.resumo} ${a.paragrafos.join(' ')}';
        expect(temEmoji(tudo), isFalse, reason: a.id);
        expect(a.minutosLeitura, greaterThanOrEqualTo(1));
      }
    });

    test('o feed só traz artigos do modo escolhido', () {
      final feed = ArtigosRepositorio.feedDaSessao('ler', 'ler_distopia');
      expect(feed.isNotEmpty, isTrue);
      for (final a in feed) {
        expect(a.objetivoId, equals('ler'));
        expect(a.categoriaId, equals('ler_distopia'));
      }
    });

    test('o feed é finito', () {
      for (final o in todosOsObjetivos) {
        for (final cat in o.categorias) {
          expect(
            ArtigosRepositorio.feedDaSessao(o.id, cat.id).length,
            lessThanOrEqualTo(conteudosPorSessao),
          );
        }
      }
    });

    test('sem modo definido, o feed é vazio', () {
      expect(ArtigosRepositorio.feedDaSessao(null, null), isEmpty);
      expect(ArtigosRepositorio.doModo('ler', null), isEmpty);
    });

    test('busca ignora acentos e maiúsculas, em título, autor e assunto', () {
      final base = artigosDados;
      expect(
        ArtigosRepositorio.buscar('sócrates', base).map((a) => a.id),
        contains('a025'),
      );
      expect(
        ArtigosRepositorio.buscar('SOCRATES', base).map((a) => a.id),
        contains('a025'),
      );
      expect(
        ArtigosRepositorio.buscar('machado', base).map((a) => a.id),
        contains('a007'),
      );
      expect(ArtigosRepositorio.buscar('xyzxyz', base), isEmpty);
      expect(ArtigosRepositorio.buscar('  ', base).length, equals(base.length));
    });

    test('a busca nunca sai da lista-base recebida (respeita o filtro)', () {
      final doModo = ArtigosRepositorio.doModo('estudar', 'estudar_historia');
      final r = ArtigosRepositorio.buscar('machado', doModo);
      expect(r, isEmpty); // artigo de Machado existe, mas em outro modo
    });

    test('tags e filtro por tag', () {
      final base = ArtigosRepositorio.doModo('ler', 'ler_distopia');
      final tags = ArtigosRepositorio.tagsDe(base);
      expect(tags, contains('distopia'));
      expect(ArtigosRepositorio.comTag('distopia', base).length, equals(1));
    });

    test('normalizarTexto', () {
      expect(normalizarTexto('Ação Rápida É Ótima'), equals('acao rapida e otima'));
    });
  });
}
