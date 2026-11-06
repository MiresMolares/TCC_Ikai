import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';

import '../core/atividades.dart';
import '../services/chat_ik_ai.dart';
import 'estilo.dart';

/// Conversa com a Ik AI: balões, cartões de atividade, respostas rápidas e
/// campo de texto. Usada na tela de fim de tempo e na página "Ik AI".
///
/// Precisa de um Scaffold e de um Overlay acima (o campo de texto usa os
/// dois). O [ChatIkAi] pertence a quem criou a tela.
class IkAiChatView extends StatefulWidget {
  final ChatIkAi chat;

  const IkAiChatView({super.key, required this.chat});

  @override
  State<IkAiChatView> createState() => _IkAiChatViewState();
}

class _IkAiChatViewState extends State<IkAiChatView> {
  final TextEditingController _campo = TextEditingController();
  final ScrollController _rolagem = ScrollController();

  @override
  void initState() {
    super.initState();
    // Inicia antes de ouvir: setState não pode rodar dentro do initState.
    widget.chat.iniciar();
    widget.chat.addListener(_aoMudar);
  }

  @override
  void dispose() {
    widget.chat.removeListener(_aoMudar);
    _campo.dispose();
    _rolagem.dispose();
    super.dispose();
  }

  void _aoMudar() {
    if (!mounted) return;
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_rolagem.hasClients) return;
      _rolagem.animateTo(
        _rolagem.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _enviar() {
    final texto = _campo.text.trim();
    if (texto.isEmpty) return;
    _campo.clear();
    unawaited(widget.chat.enviar(texto));
  }

  @override
  Widget build(BuildContext context) {
    final chat = widget.chat;
    final msgs = chat.mensagens;
    var ultimaIa = -1;
    for (var i = 0; i < msgs.length; i++) {
      if (msgs[i].autor == Autor.ia) ultimaIa = i;
    }
    final podeInteragir = !chat.pensando && !chat.encerrada;

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _rolagem,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            itemCount: msgs.length + (chat.pensando ? 1 : 0),
            itemBuilder: (context, i) {
              if (i >= msgs.length) return const _Digitando();
              final m = msgs[i];
              if (m.autor == Autor.usuario) return _BalaoUsuario(m.texto);
              final ehUltima = i == ultimaIa;
              return _BalaoIa(
                mensagem: m,
                ativa: ehUltima && podeInteragir,
                aoEscolher: chat.escolher,
                aoResponder: (t) => unawaited(chat.enviar(t)),
              );
            },
          ),
        ),
        if (kDebugMode && chat.motivoLocal != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '[debug] resposta local: ${chat.motivoLocal}',
              style: const TextStyle(fontSize: 11, color: Cores.subtitulo),
            ),
          ),
        if (chat.geminiDisponivel && !chat.encerrada)
          SwitchListTile(
            dense: true,
            value: chat.usarGemini,
            onChanged: (v) => chat.usarGemini = v,
            activeTrackColor: Cores.verde,
            title: const Text(
              'Conversar também com o Gemini',
              style: TextStyle(fontSize: 13),
            ),
            subtitle: const Text(
              'Envia ao Google só o que você escrever aqui. Nunca seu nome '
              'nem seu e-mail.',
              style: TextStyle(fontSize: 11),
            ),
          ),
        if (!chat.encerrada)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Cores.bordaQuente)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _campo,
                        enabled: !chat.pensando,
                        maxLength: ChatIkAi.limiteTexto,
                        maxLines: 3,
                        minLines: 1,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _enviar(),
                        buildCounter: (
                          context, {
                          required currentLength,
                          required isFocused,
                          required maxLength,
                        }) =>
                            null,
                        decoration: const InputDecoration(
                          hintText: 'Conte o que você tem vontade de fazer...',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: chat.pensando ? null : _enviar,
                      icon: const Icon(Icons.send_rounded),
                      color: Cores.laranja,
                      tooltip: 'Enviar',
                    ),
                  ],
                ),
                const Text(
                  'A Ik AI é um assistente do app e não substitui ajuda de '
                  'um profissional.',
                  style: TextStyle(fontSize: 11, color: Cores.subtitulo),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _BalaoUsuario extends StatelessWidget {
  final String texto;

  const _BalaoUsuario(this.texto);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(top: 10, left: 48),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Cores.verdeClaro,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Cores.verde),
        ),
        child: Text(
          texto,
          style: const TextStyle(fontSize: 14, color: Cores.tituloVerde),
        ),
      ),
    );
  }
}

class _BalaoIa extends StatelessWidget {
  final Mensagem mensagem;

  /// Só a última mensagem da Ik AI aceita toques (cartões e respostas rápidas).
  final bool ativa;
  final void Function(Atividade) aoEscolher;
  final void Function(String) aoResponder;

  const _BalaoIa({
    required this.mensagem,
    required this.ativa,
    required this.aoEscolher,
    required this.aoResponder,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(top: 10, right: 24),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Cores.bordaQuente),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ik AI',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Cores.laranja,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              mensagem.texto,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
                color: Cores.tituloVerde,
              ),
            ),
            for (final a in mensagem.opcoes)
              _CartaoAtividade(
                atividade: a,
                ativo: ativa,
                aoEscolher: aoEscolher,
              ),
            if (ativa && mensagem.chips.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final c in mensagem.chips)
                    ActionChip(
                      label: Text(c, style: const TextStyle(fontSize: 12)),
                      onPressed: () => aoResponder(c),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CartaoAtividade extends StatelessWidget {
  final Atividade atividade;
  final bool ativo;
  final void Function(Atividade) aoEscolher;

  const _CartaoAtividade({
    required this.atividade,
    required this.ativo,
    required this.aoEscolher,
  });

  @override
  Widget build(BuildContext context) {
    final a = atividade;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Cores.fundoEtapas,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Cores.borda),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            a.titulo,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Cores.tituloVerde,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            a.passos,
            style: const TextStyle(
              fontSize: 13,
              height: 1.35,
              color: Cores.subtitulo,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _Meta('${a.minutos} min'),
              _Meta('energia ${a.rotuloEnergia}'),
              if (a.deIa) const _Meta('sugerida pelo Gemini'),
            ],
          ),
          if (ativo) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () => aoEscolher(a),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Cores.laranja,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Vou fazer isso'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  final String texto;

  const _Meta(this.texto);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Cores.verdeClaro,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        texto,
        style: const TextStyle(fontSize: 11, color: Cores.verde),
      ),
    );
  }
}

class _Digitando extends StatelessWidget {
  const _Digitando();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 14),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Cores.laranja,
            ),
          ),
          SizedBox(width: 10),
          Text(
            'A Ik AI está pensando...',
            style: TextStyle(fontSize: 13, color: Cores.subtitulo),
          ),
        ],
      ),
    );
  }
}
