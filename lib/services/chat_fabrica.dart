import '../core/intencao.dart';
import '../core/motor_ik_ai.dart';
import '../pages_configurar/controle_objetivo.dart';
import 'auth_service.dart';
import 'chat_ik_ai.dart';
import 'compromisso_service.dart';
import 'config_service.dart';
import 'ik_ai_service.dart';

/// Monta uma conversa com a Ik AI a partir do que o usuário DECLAROU:
/// o texto da etapa "Ik AI" e a memória guardada no perfil. O primeiro nome
/// fica só no aparelho (nunca vai para o Gemini).
///
/// [ocasiao]: 'fim' quando o tempo do dia acabou, 'livre' quando a pessoa
/// abre o chat pelo botão da Ik AI. [fimDoDia] liga a conversa de fim de
/// tempo (aprendizado, continuar com justificativa, ideias, encerrar).
ChatIkAi novoChatIkAi({
  required String ocasiao,
  int minutosUsados = 0,
  AcoesFimDoDia? fimDoDia,
}) {
  final c = ControleObjetivos.instance;
  final texto = c.textoIkAi.trim();
  final memoria = IkAiService.memoria;
  final fontes = <String>[
    texto,
    ...memoria.vontades,
    memoria.detalhePrincipal ?? '',
  ];
  // Autorização: a da etapa "Ik AI" (versão avançada) ou a que a pessoa deu
  // uma vez no chat / em Configurações. Sem nenhuma das duas, nada sai.
  final permitiu =
      c.permitirGemini || ConfigService.instance.geminiAutorizado == true;

  return ChatIkAi(
    estado: EstadoConversa(temas: temasDoTexto(fontes.join(' '))),
    nome: AuthService.instance.usuarioAtual?.primeiroNome,
    objetivoTitulo: c.objetivo?.titulo ?? '',
    textoDaSessao: texto,
    ocasiao: ocasiao,
    minutosUsados: minutosUsados,
    rotacao: CompromissoService.instance.todos.length,
    usarGemini: permitiu,
    aoCombinar: (atividade, quando) =>
        CompromissoService.instance.adicionar(atividade, quando),
    fimDoDia: fimDoDia,
  );
}
