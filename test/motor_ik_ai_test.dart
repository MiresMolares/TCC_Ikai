import 'package:flutter_test/flutter_test.dart';
import 'package:ikai/core/atividades.dart';
import 'package:ikai/core/intencao.dart';
import 'package:ikai/core/motor_ik_ai.dart';
import 'package:ikai/core/sem_emoji.dart';

void main() {
  group('Catálogo de atividades', () {
    test('ids únicos e campos válidos', () {
      final ids = <String>{};
      for (final a in catalogoDeAtividades) {
        expect(ids.add(a.id), isTrue, reason: 'id repetido ${a.id}');
        expect(a.titulo.trim(), isNotEmpty);
        expect(a.passos.trim(), isNotEmpty);
        expect(a.minutos >= 1 && a.minutos <= 120, isTrue, reason: a.id);
        expect(a.energia >= 1 && a.energia <= 3, isTrue, reason: a.id);
        expect(temEmoji('${a.titulo} ${a.passos}'), isFalse, reason: a.id);
      }
    });

    test('há opções sem material, de pouca energia e em cada tema', () {
      expect(
        catalogoDeAtividades.where((a) => a.precisa.isEmpty).length,
        greaterThanOrEqualTo(15),
      );
      expect(
        catalogoDeAtividades.where((a) => a.energia == 1).length,
        greaterThanOrEqualTo(15),
      );
      for (final t in Tema.values) {
        expect(catalogoDeAtividades.where((a) => a.tema == t), isNotEmpty,
            reason: '$t');
      }
    });

    test('quem não tem o livro ainda tem opções de leitura sem livro', () {
      final sem = catalogoDeAtividades.where((a) =>
          a.tema == Tema.leitura && !a.precisa.contains(Material.livro));
      expect(sem.length, greaterThanOrEqualTo(4));
    });

    test('atividadePorId', () {
      expect(atividadePorId('lei_livro')?.tema, Tema.leitura);
      expect(atividadePorId('nao_existe'), isNull);
    });
  });

  group('Leitura do que o usuário disse', () {
    test('sem o livro', () {
      for (final f in [
        'Não tenho meu livro',
        'nao estou com o livro agora',
        'esqueci o livro em casa',
        'sem livro aqui',
      ]) {
        expect(interpretar(f).semMaterial, contains(Material.livro), reason: f);
      }
    });

    test('sem papel e caneta, sem instrumento', () {
      expect(interpretar('não tenho caneta').semMaterial,
          contains(Material.caderno));
      expect(interpretar('estou sem violão').semMaterial,
          contains(Material.instrumento));
    });

    test('tempo disponível', () {
      expect(interpretar('tenho 10 minutos').minutos, 10);
      expect(interpretar('só 5 min').minutos, 5);
      expect(interpretar('tenho meia hora').minutos, 30);
      expect(interpretar('tenho 2 horas').minutos, 120);
      expect(interpretar('tenho pouco tempo').minutos, 10);
      expect(interpretar('tenho 9999 minutos').minutos, isNull);
    });

    test('energia e lugar', () {
      expect(interpretar('estou muito cansado').energiaMaxima, 1);
      expect(interpretar('estou sem energia').energiaMaxima, 1);
      expect(interpretar('tô na rua').local, Local.fora);
      expect(interpretar('estou na rua').local, Local.fora);
      expect(interpretar('estou em casa').local, Local.casa);
    });

    test('temas pelas palavras escritas', () {
      final t = temasDoTexto('lendo Capitães da Areia, treinando em casa e '
          'aprendendo francês');
      expect(t.length, 3);
      expect(t.containsAll({Tema.leitura, Tema.treino, Tema.idioma}), isTrue);
    });

    test('não confunde palavras parecidas', () {
      expect(temasDoTexto('isso está correto'), isEmpty);
      expect(temasDoTexto('violência urbana'), isEmpty);
    });

    test('outra ideia, aceite e sem ideia', () {
      expect(interpretar('quero outra ideia').querOutras, isTrue);
      expect(interpretar('não quero isso').querOutras, isTrue);
      expect(interpretar('bora').aceitou, isTrue);
      expect(interpretar('não sei').semIdeia, isTrue);
    });

    test('texto vazio ou sem significado não marca nada', () {
      expect(interpretar('').vazia, isTrue);
      expect(interpretar('hmm').vazia, isTrue);
    });
  });

  group('Motor da Ik AI', () {
    EstadoConversa estado({Set<Tema>? temas}) =>
        EstadoConversa(temas: temas ?? {Tema.leitura});

    test('sempre devolve várias opções, não uma só', () {
      for (final temas in <Set<Tema>>[
        {},
        {Tema.leitura},
        {Tema.treino, Tema.idioma},
        {Tema.escrita},
      ]) {
        final r = MotorIkAi.selecionar(estado(temas: temas));
        expect(r.length, 3, reason: '$temas');
        expect(r.map((a) => a.id).toSet().length, 3);
      }
    });

    test('prioriza o que o usuário declarou, com variedade de tema', () {
      final r = MotorIkAi.selecionar(
          estado(temas: {Tema.treino, Tema.idioma, Tema.leitura}));
      final temas = r.map((a) => a.tema).toSet();
      expect(temas.length, 3);
      expect(temas.containsAll({Tema.treino, Tema.idioma, Tema.leitura}),
          isTrue);
    });

    test('sem o livro: nenhuma opção exige livro e ainda há leitura', () {
      final e = estado();
      final r = MotorIkAi.responder(e, 'Não tenho meu livro');
      expect(r.opcoes, isNotEmpty);
      expect(r.opcoes.any((a) => a.precisa.contains(Material.livro)), isFalse);
      expect(r.opcoes.any((a) => a.tema == Tema.leitura), isTrue);
      expect(r.texto, contains('sem o livro'));
      expect(r.chips, isNot(contains(MotorIkAi.chipSemLivro)));
    });

    test('pouco tempo respeita o limite', () {
      final r = MotorIkAi.responder(estado(), 'tenho 5 minutos');
      expect(r.opcoes, isNotEmpty);
      expect(r.opcoes.every((a) => a.minutos <= 5), isTrue);
      expect(r.texto, contains('5 minutos'));
    });

    test('cansado: só atividades de pouca energia', () {
      final r = MotorIkAi.responder(estado(temas: {Tema.treino}), 'estou cansado');
      expect(r.opcoes, isNotEmpty);
      expect(r.opcoes.every((a) => a.energia == 1), isTrue);
    });

    test('fora de casa: nada que exija estar em casa', () {
      final r = MotorIkAi.responder(estado(temas: {Tema.treino}), 'estou na rua');
      expect(r.opcoes.every((a) => a.local != Local.casa), isTrue);
    });

    test('"outra ideia" nunca repete o que já foi mostrado', () {
      final e = estado(temas: {Tema.leitura, Tema.treino});
      var r = MotorIkAi.abertura(e);
      final vistas = <String>{...r.opcoes.map((a) => a.id)};
      for (var k = 0; k < 6; k++) {
        r = MotorIkAi.responder(e, 'quero outra ideia', mostradas: r.opcoes);
        if (r.opcoes.isEmpty) break;
        for (final a in r.opcoes) {
          expect(vistas.add(a.id), isTrue, reason: 'repetiu ${a.id}');
        }
      }
      expect(vistas.length, greaterThan(6));
    });

    test('quando as ideias acabam, não inventa e oferece descanso', () {
      final e = estado();
      var r = MotorIkAi.abertura(e);
      var guarda = 0;
      while (r.opcoes.isNotEmpty && guarda++ < 100) {
        r = MotorIkAi.responder(e, 'outra coisa', mostradas: r.opcoes);
      }
      expect(r.opcoes, isEmpty);
      expect(r.texto, contains('Passamos por todas'));
      expect(r.chips, contains('Vou descansar um pouco'));
    });

    test('abertura sem nada declarado é honesta e não cita temas', () {
      final r = MotorIkAi.abertura(EstadoConversa(), minutosUsados: 15);
      expect(r.texto, contains('Você não me contou'));
      expect(r.texto.contains('Você me falou'), isFalse);
      expect(r.texto, contains('15 minutos'));
      expect(r.opcoes.length, 3);
    });

    test('abertura reflete só o que foi declarado, e usa o nome', () {
      final r = MotorIkAi.abertura(
        estado(temas: {Tema.leitura, Tema.idioma}),
        nome: 'Ana',
      );
      expect(r.texto, startsWith('Ana, seu tempo no Ikai acabou'));
      expect(r.texto, contains('leitura'));
      expect(r.texto, contains('idiomas'));
      expect(r.texto.contains('treino'), isFalse);
    });

    test('abertura livre não fala em "tempo acabou"', () {
      final r = MotorIkAi.abertura(EstadoConversa(), ocasiao: 'livre');
      expect(r.texto.contains('acabou'), isFalse);
      expect(r.texto, startsWith('Oi!'));
    });

    test('rotação muda a primeira opção entre sessões', () {
      final a = MotorIkAi.selecionar(EstadoConversa(), rotacao: 0);
      final b = MotorIkAi.selecionar(EstadoConversa(), rotacao: 1);
      expect(a.first.id == b.first.id, isFalse);
      final primeiras = <String>{
        for (var r = 0; r < 8; r++)
          MotorIkAi.selecionar(EstadoConversa(), rotacao: r).first.id,
      };
      expect(primeiras.length, greaterThan(3));
    });

    test('texto sem sentido gera pergunta, sem presumir nada', () {
      final r = MotorIkAi.responder(EstadoConversa(), 'hmm');
      expect(r.texto, contains('O que você tem vontade'));
      expect(r.opcoes, isNotEmpty);
    });

    test('só "ok": pede para escolher uma opção', () {
      final mostradas = MotorIkAi.selecionar(EstadoConversa());
      final r = MotorIkAi.responder(EstadoConversa(), 'ok', mostradas: mostradas);
      expect(r.texto, contains('Vou fazer isso'));
    });

    test('tema novo dito no chat é anotado e passa a valer', () {
      final e = EstadoConversa();
      final r = MotorIkAi.responder(e, 'quero treinar um pouco');
      expect(e.temas, contains(Tema.treino));
      expect(r.texto, contains('Anotei: treino'));
      expect(r.opcoes.any((a) => a.tema == Tema.treino), isTrue);
    });

    test('plano "quando X, então Y"', () {
      final a = atividadePorId('tre_alongar')!;
      final q = MotorIkAi.perguntarQuando(a);
      expect(q.texto, contains('Quando você começa'));
      expect(q.chips, contains('Antes de dormir'));
      final c = MotorIkAi.confirmarCombinado(a, 'depois do jantar');
      expect(c.texto, contains('depois do jantar'));
      expect(c.texto, contains(a.titulo));
    });

    test('nenhum texto do motor tem emoji', () {
      final e = estado(temas: {Tema.leitura, Tema.treino});
      final todos = <String>[
        MotorIkAi.abertura(e, nome: 'Ana', minutosUsados: 3).texto,
        MotorIkAi.responder(e, 'estou cansado e sem o livro').texto,
        MotorIkAi.responder(e, 'outra ideia').texto,
        MotorIkAi.perguntarQuando(catalogoDeAtividades.first).texto,
      ];
      for (final t in todos) {
        expect(temEmoji(t), isFalse, reason: t);
      }
    });
  });
}
