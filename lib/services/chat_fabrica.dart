import '../core/intencao.dart';
import '../core/motor_ik_ai.dart';
import '../pages_configurar/controle_objetivo.dart';
import 'auth_service.dart';
import 'chat_ik_ai.dart';
import 'compromisso_service.dart';
import 'ik_ai_service.dart';

/// Monta uma conversa com a Ik AI a partir do que o usuário DECLAROU:
/// o texto da etapa "Ik AI" e a memória guardada no perfil. O primeiro nome
/// fica só no aparelho (nunca vai para o Gemini).
///
/// [ocasiao]: 'fim' quando o tempo acabou, 'livre' quando a pessoa abre o chat.
ChatIkAi novoChatIkAi({
  required String ocasiao,
  ResumoSessao? resumo,
  int minutosUsados = 0,
}) {
  final c = ControleObjetivos.instance;
  final texto = (resumo?.textoIkAi ?? c.textoIkAi).trim();
  final memoria = IkAiService.memoria;
  final fontes = <String>[
    texto,
    ...memoria.vontades,
    memoria.detalhePrincipal ?? '',
  ];
  final permitiu = resumo?.permitiuEnvioGemini ?? c.permitirGemini;

  return ChatIkAi(
    estado: EstadoConversa(temas: temasDoTexto(fontes.join(' '))),
    nome: AuthService.instance.usuarioAtual?.primeiroNome,
    objetivoTitulo: resumo?.objetivoTitulo ?? c.objetivo?.titulo ?? '',
    textoDaSessao: texto,
    ocasiao: ocasiao,
    minutosUsados: minutosUsados,
    rotacao: CompromissoService.instance.todos.length,
    usarGemini: permitiu,
    aoCombinar: (atividade, quando) =>
        CompromissoService.instance.adicionar(atividade, quando),
  );
}
