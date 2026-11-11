import 'chat_ik_ai.dart';
import '../core/uso_diario.dart';
import 'tempo_diario.dart';

/// Liga a conversa de fim do dia ao [TempoDiarioService].
class AcoesFimDoDiaReais implements AcoesFimDoDia {
  final TempoDiarioService _t;

  AcoesFimDoDiaReais([TempoDiarioService? servico])
    : _t = servico ?? TempoDiarioService.instance;

  @override
  bool get voluntario => _t.fimVoluntario;

  @override
  bool get podeProrrogar => _t.podeProrrogar;

  @override
  int get prorrogacoesRestantes => _t.prorrogacoesRestantes;

  @override
  int get maxProrrogacoes => TempoDiarioService.maxProrrogacoes;

  @override
  List<int> get opcoesProrrogacao => TempoDiarioService.opcoesProrrogacao;

  @override
  String get resumoDeUso =>
      '${formatarHm(_t.usadoHojeSeg)} de ${formatarHm(_t.limiteHojeSeg)}';

  @override
  bool registrarAprendizado(String texto) => _t.registrarAprendizado(texto);

  @override
  bool prorrogar(int minutos, String motivo) => _t.prorrogar(minutos, motivo);

  @override
  bool voltarAoApp() => _t.voltarAoApp();

  @override
  void encerrarPorHoje() => _t.encerrarPorHoje();
}
