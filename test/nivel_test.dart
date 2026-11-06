import 'package:flutter_test/flutter_test.dart';
import 'package:ikai/data/artigo.dart';
import 'package:ikai/data/artigos_dados.dart';
import 'package:ikai/services/artigos_repositorio.dart';
import 'package:ikai/services/config_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Nível de dificuldade dos artigos', () {
    test('todo artigo tem nível de 1 a 3', () {
      for (final a in artigosDados) {
        expect(
          a.nivel >= Artigo.nivelMinimo && a.nivel <= Artigo.nivelMaximo,
          isTrue,
          reason: a.id,
        );
      }
    });

    test('existem artigos nos três níveis', () {
      for (var n = 1; n <= 3; n++) {
        expect(artigosDados.where((a) => a.nivel == n), isNotEmpty,
            reason: 'nível $n');
      }
    });

    test('nomes dos níveis', () {
      expect(Artigo.nomeDoNivel(0), 'Todos');
      expect(Artigo.nomeDoNivel(1), 'Iniciante');
      expect(Artigo.nomeDoNivel(2), 'Intermediário');
      expect(Artigo.nomeDoNivel(3), 'Avançado');
    });

    test('nível 0 ou inválido devolve a lista inteira', () {
      final base = artigosDados.take(10).toList();
      expect(ArtigosRepositorio.doNivel(base, 0), base);
      expect(ArtigosRepositorio.doNivel(base, 9), base);
      expect(ArtigosRepositorio.doNivel(base, -1), base);
    });

    test('filtrar por nível só devolve aquele nível e nunca cria artigo', () {
      for (var n = 1; n <= 3; n++) {
        final r = ArtigosRepositorio.doNivel(artigosDados, n);
        expect(r.every((a) => a.nivel == n), isTrue);
        expect(r.every(artigosDados.contains), isTrue);
      }
    });

    test('o feed continua finito e respeita o nível', () {
      final base = ArtigosRepositorio.doModo('ler', 'ler_distopia');
      final alvo = base.first.nivel;
      final outro = alvo == 3 ? 1 : alvo + 1;
      expect(
        ArtigosRepositorio.feedDaSessao('ler', 'ler_distopia', nivel: alvo),
        isNotEmpty,
      );
      final feedOutro =
          ArtigosRepositorio.feedDaSessao('ler', 'ler_distopia', nivel: outro);
      expect(feedOutro.every((a) => a.nivel == outro), isTrue);
      expect(feedOutro.length, lessThanOrEqualTo(conteudosPorSessao));
    });
  });

  group('Preferência de nível', () {
    test('começa em "todos", o usuário escolhe e fica salvo', () async {
      final cfg = ConfigService.instance;
      await cfg.carregar();
      expect(cfg.nivelConteudo, 0);
      await cfg.definirNivelConteudo(2);
      expect(cfg.nivelConteudo, 2);

      // Simula reabrir o app: lê do armazenamento.
      await cfg.definirNivelConteudo(0);
      await cfg.definirNivelConteudo(3);
      await cfg.carregar();
      expect(cfg.nivelConteudo, 3);
      await cfg.definirNivelConteudo(0);
    });

    test('valores fora de 0 a 3 são ignorados', () async {
      final cfg = ConfigService.instance;
      await cfg.definirNivelConteudo(1);
      await cfg.definirNivelConteudo(7);
      await cfg.definirNivelConteudo(-2);
      expect(cfg.nivelConteudo, 1);
      await cfg.definirNivelConteudo(0);
    });

    test('valor corrompido no armazenamento volta para "todos"', () async {
      SharedPreferences.setMockInitialValues({'cfg_nivel_conteudo': 99});
      final cfg = ConfigService.instance;
      await cfg.carregar();
      expect(cfg.nivelConteudo, 0);
    });
  });
}
