/// Ferramentas para manter o app livre de emojis. Dart puro.
///
/// Cobre os blocos Unicode de emojis e pictogramas. Não remove setas,
/// pontuação nem acentos.
final RegExp _padraoEmoji = RegExp(
  '[\u{1F000}-\u{1FAFF}'
  '\u{2600}-\u{27BF}'
  '\u{2B00}-\u{2BFF}'
  '\u{2300}-\u{23FF}'
  '\u{FE0F}\u{200D}\u{20E3}'
  '\u{E0020}-\u{E007F}]',
  unicode: true,
);

bool temEmoji(String texto) => _padraoEmoji.hasMatch(texto);

/// Remove emojis e arruma os espaços que sobrarem.
String removerEmojis(String texto) {
  if (!temEmoji(texto)) return texto;
  return texto
      .replaceAll(_padraoEmoji, '')
      .replaceAll(RegExp(r'[ \t]{2,}'), ' ')
      .trim();
}
