import 'package:flutter/material.dart';

import '../services/biblioteca_service.dart';
import '../services/progresso_service.dart';
import '../widgets/estilo.dart';

/// Progresso individual (Pilar 4): você só se compara com o seu próprio
/// histórico. Não existe ranking.
class ProgressoPage extends StatelessWidget {
  const ProgressoPage({super.key});

  static const Map<String, String> _nomesObjetivos = {
    'ver_conteudo': 'Ver conteúdo',
    'ler': 'Ler',
    'estudar': 'Estudar',
  };

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        ProgressoService.instance,
        BibliotecaService.instance,
      ]),
      builder: (context, _) {
        final p = ProgressoService.instance;
        final conquistas = p.conquistas(
          totalSalvos: BibliotecaService.instance.todosOsIds.length,
        );
        final porObjetivo = p.lidosPorObjetivo();
        final maior = porObjetivo.values.fold<int>(1, (a, b) => b > a ? b : a);

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            const Text(
              'Seu progresso',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Cores.titulo,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _Numero(
                    valor: '${p.totalLidos}',
                    rotulo: 'artigos lidos',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Numero(
                    valor: '${p.sessoesConcluidas}',
                    rotulo: 'sessões',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _Numero(
                    valor: formatarMinutos(p.segundosEmSessao),
                    rotulo: 'em sessão',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Numero(
                    valor: p.ofensiva == 1 ? '1 dia' : '${p.ofensiva} dias',
                    rotulo: 'seguidos',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Leituras por modo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Cores.titulo,
              ),
            ),
            const SizedBox(height: 10),
            for (final e in _nomesObjetivos.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 96,
                      child: Text(
                        e.value,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Cores.titulo,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: (porObjetivo[e.key] ?? 0) / maior,
                          minHeight: 8,
                          color: Cores.verde,
                          backgroundColor: Cores.borda,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 30,
                      child: Text(
                        '${porObjetivo[e.key] ?? 0}',
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Cores.titulo,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 14),
            const Text(
              'Conquistas',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Cores.titulo,
              ),
            ),
            const SizedBox(height: 10),
            for (final c in conquistas)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: c.desbloqueada ? Cores.verdeClaro : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: c.desbloqueada ? Cores.verde : Cores.borda,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      c.desbloqueada
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: c.desbloqueada ? Cores.verde : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.titulo,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Cores.titulo,
                            ),
                          ),
                          Text(
                            c.descricao,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Cores.subtitulo,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 6),
            const Text(
              'Sem ranking: aqui você só se compara com você mesmo.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Cores.subtitulo),
            ),
          ],
        );
      },
    );
  }
}

/// 0 -> "0 min"; 90 s -> "2 min"; 3 600 s -> "1 h".
String formatarMinutos(int segundos) {
  if (segundos <= 0) return '0 min';
  final min = (segundos / 60).round();
  if (min < 60) return '${min < 1 ? 1 : min} min';
  final h = min ~/ 60;
  final r = min % 60;
  return r == 0 ? '$h h' : '$h h $r min';
}

class _Numero extends StatelessWidget {
  final String valor;
  final String rotulo;

  const _Numero({required this.valor, required this.rotulo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Cores.borda),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            valor,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Cores.laranja,
            ),
          ),
          Text(
            rotulo,
            style: const TextStyle(fontSize: 12, color: Cores.subtitulo),
          ),
        ],
      ),
    );
  }
}
