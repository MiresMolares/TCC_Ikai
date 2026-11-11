import 'package:flutter_test/flutter_test.dart';
import 'package:ikai/core/sem_emoji.dart';
import 'package:ikai/core/uso_diario.dart';

void main() {
  final hoje = DateTime(2026, 11, 11, 9, 30); // quarta-feira

  group('Datas', () {
    test('chaveDoDia e diaDeChave', () {
      expect(chaveDoDia(DateTime(2026, 3, 5)), '2026-03-05');
      expect(diaDeChave('2026-03-05'), DateTime(2026, 3, 5));
      expect(diaDeChave('2026-13-05'), isNull);
      expect(diaDeChave('lixo'), isNull);
    });

    test('diasAntes atravessa mês e ano', () {
      expect(chaveDoDia(diasAntes(DateTime(2026, 1, 2), 3)), '2025-12-30');
      expect(chaveDoDia(diasAntes(DateTime(2026, 3, 1), 1)), '2026-02-28');
    });

    test('chaveDaSemana é a segunda-feira da semana', () {
      expect(chaveDaSemana(DateTime(2026, 11, 11)), '2026-11-09'); // quarta
      expect(chaveDaSemana(DateTime(2026, 11, 9)), '2026-11-09'); // segunda
      expect(chaveDaSemana(DateTime(2026, 11, 15)), '2026-11-09'); // domingo
      expect(chaveDaSemana(DateTime(2026, 11, 16)), '2026-11-16');
    });
  });

  group('formatarHm', () {
    test('formatos', () {
      expect(formatarHm(0), '0 min');
      expect(formatarHm(10), 'menos de 1 min');
      expect(formatarHm(45 * 60), '45 min');
      expect(formatarHm(5 * 3600 + 38 * 60), '5h38');
      expect(formatarHm(2 * 3600), '2h00');
      expect(formatarHm(59 * 60 + 40), '1h00'); // arredonda para 60 min
    });
  });

  group('UsoDiario', () {
    test('soma por dia e ignora valores inválidos', () {
      final u = UsoDiario();
      u.somar(hoje, 60);
      u.somar(hoje, 30);
      u.somar(hoje, -5);
      u.somar(hoje, 0);
      expect(u.doDia(hoje), 90);
      expect(u.doDia(diasAntes(hoje, 1)), 0);
    });

    test('ultimosDias vai do mais antigo até hoje', () {
      final u = UsoDiario();
      u.somar(hoje, 10);
      u.somar(diasAntes(hoje, 2), 20);
      expect(u.ultimosDias(hoje, 4), [0, 20, 0, 10]);
    });

    test('recorrente exige 2 dias de uso e algum na última semana', () {
      final u = UsoDiario();
      expect(u.recorrente(hoje), isFalse);
      u.somar(hoje, 100);
      expect(u.recorrente(hoje), isFalse);
      u.somar(diasAntes(hoje, 1), 100);
      expect(u.recorrente(hoje), isTrue);

      final antigo = UsoDiario()
        ..somar(diasAntes(hoje, 30), 100)
        ..somar(diasAntes(hoje, 31), 100);
      expect(antigo.recorrente(hoje), isFalse);
    });

    test('resumo: soma, média pelos dias desde o primeiro uso e meta', () {
      final u = UsoDiario()
        ..somar(diasAntes(hoje, 3), 60 * 60) // 1h, 3 dias atrás
        ..somar(diasAntes(hoje, 1), 30 * 60)
        ..somar(hoje, 30 * 60);
      final r = u.resumo(hoje, 45 * 60);
      expect(r.totalSeg, 2 * 3600);
      expect(r.dias, 4); // do primeiro uso até hoje, contando o dia vazio
      expect(r.mediaSeg, 30 * 60);
      expect(r.diasComUso, 3);
      expect(r.diasDentroDaMeta, 2); // 30 e 30 min; 1h passou da meta
      expect(r.mediaDentroDaMeta, isTrue);
      expect(r.maiorDiaSeg, 3600);
      expect(r.porDia.length, 7);
    });

    test('resumo limita a janela em 7 dias', () {
      final u = UsoDiario()
        ..somar(diasAntes(hoje, 20), 3600) // fora da janela
        ..somar(diasAntes(hoje, 6), 600)
        ..somar(hoje, 600);
      final r = u.resumo(hoje, 1800);
      expect(r.dias, 7);
      expect(r.totalSeg, 1200);
    });

    test('resumo sem uso não divide por zero', () {
      final r = UsoDiario().resumo(hoje, 1800);
      expect(r.totalSeg, 0);
      expect(r.dias, 1);
      expect(r.mediaSeg, 0);
      expect(r.mediaDentroDaMeta, isTrue);
    });

    test('texto do resumo: dentro e acima da meta, sem emoji', () {
      final dentro = UsoDiario()
        ..somar(diasAntes(hoje, 1), 40 * 60)
        ..somar(hoje, 40 * 60);
      final t1 = dentro.resumo(hoje, 45 * 60).texto;
      expect(t1, contains('Nos últimos 2 dias'));
      expect(t1, contains('1h20'));
      expect(t1, contains('média de 40 min por dia'));
      expect(t1, contains('dentro da meta de 45 min'));

      final fora = UsoDiario()
        ..somar(diasAntes(hoje, 1), 60 * 60)
        ..somar(hoje, 60 * 60);
      final t2 = fora.resumo(hoje, 45 * 60).texto;
      expect(t2, contains('15 min acima da meta de 45 min'));

      final um = UsoDiario()..somar(hoje, 12 * 60);
      final t3 = um.resumo(hoje, 45 * 60).texto;
      expect(t3, startsWith('Hoje você usou o Ikai por 12 min'));
      for (final t in [t1, t2, t3]) {
        expect(temEmoji(t), isFalse);
      }
    });

    test('diasDentroDaMeta no histórico todo', () {
      final u = UsoDiario()
        ..somar(diasAntes(hoje, 40), 10 * 60)
        ..somar(diasAntes(hoje, 2), 90 * 60)
        ..somar(hoje, 20 * 60);
      expect(u.diasDentroDaMeta(30 * 60), 2);
    });

    test('podar descarta o que é antigo', () {
      final u = UsoDiario()
        ..somar(diasAntes(hoje, 200), 100)
        ..somar(diasAntes(hoje, 5), 100);
      u.podar(hoje);
      expect(u.diasComUsoNoTotal, 1);
    });

    test('toMap e fromMap; dado corrompido vira vazio', () {
      final u = UsoDiario()
        ..somar(hoje, 77)
        ..somar(diasAntes(hoje, 1), 5);
      final volta = UsoDiario.fromMap(u.toMap());
      expect(volta.doDia(hoje), 77);
      expect(UsoDiario.fromMap('lixo').vazio, isTrue);
      expect(
        UsoDiario.fromMap({'x': 1, '2026-01-01': 'a', '2026-01-02': -3}).vazio,
        isTrue,
      );
    });
  });
}
