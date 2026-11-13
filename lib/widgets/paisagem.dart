import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'estilo.dart';
import 'paisagens_dados.dart';

/// As paisagens do Ikai: ilustrações de natureza e crescimento que dão
/// identidade ao app. Cada objetivo tem a sua, e o dia ganha uma por hora
/// (alvorecer na entrada, entardecer no fim do tempo, noite no descanso).
///
/// Os desenhos ficam em paisagens_dados.dart (gerados a partir de formas
/// simples: colinas, árvores, montanhas, brotos). Aqui só está o que os
/// desenha na tela.
enum Paisagem { alvorecer, floresta, nascente, campo, entardecer, noite }

CenaPaisagem _cenaDe(Paisagem p) {
  switch (p) {
    case Paisagem.alvorecer:
      return cenaAlvorecer;
    case Paisagem.floresta:
      return cenaFloresta;
    case Paisagem.nascente:
      return cenaNascente;
    case Paisagem.campo:
      return cenaCampo;
    case Paisagem.entardecer:
      return cenaEntardecer;
    case Paisagem.noite:
      return cenaNoite;
  }
}

/// Como a cena se ajusta ao espaço.
///  - [cobrir]: preenche tudo, cortando as bordas (bom para faixas e cartões).
///  - [largura]: usa a largura toda e fica no pé da tela; o céu continua
///    para cima (bom para telas inteiras).
enum AjustePaisagem { cobrir, largura }

/// Os traços convertidos em [Path], feitos uma vez só.
final Map<Paisagem, List<Path>> _caminhos = <Paisagem, List<Path>>{};

List<Path> _caminhosDe(Paisagem p) {
  return _caminhos.putIfAbsent(p, () {
    final cena = _cenaDe(p);
    return [for (final c in cena.camadas) _montar(c.traco)];
  });
}

/// Operações: 0 moveTo, 1 lineTo, 2 cubicTo, 3 close (veja paisagens_dados).
Path _montar(List<double> t) {
  final path = Path();
  var i = 0;
  while (i < t.length) {
    final op = t[i].toInt();
    i++;
    switch (op) {
      case 0:
        path.moveTo(t[i], t[i + 1]);
        i += 2;
        break;
      case 1:
        path.lineTo(t[i], t[i + 1]);
        i += 2;
        break;
      case 2:
        path.cubicTo(t[i], t[i + 1], t[i + 2], t[i + 3], t[i + 4], t[i + 5]);
        i += 6;
        break;
      default:
        path.close();
        break;
    }
  }
  return path;
}

class PaisagemPainter extends CustomPainter {
  final Paisagem paisagem;
  final AjustePaisagem ajuste;

  const PaisagemPainter(this.paisagem, {this.ajuste = AjustePaisagem.cobrir});

  static const double _largura = 400;
  static const double _altura = 240;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final cena = _cenaDe(paisagem);
    final tudo = Offset.zero & size;

    final escala = ajuste == AjustePaisagem.largura
        ? size.width / _largura
        : math.max(size.width / _largura, size.height / _altura);
    final alturaCena = _altura * escala;
    final topoCena = size.height - alturaCena;

    // Céu: degradê só na faixa da cena; acima dela, a cor do topo.
    final faixa = Rect.fromLTWH(0, topoCena, size.width, alturaCena);
    final ceu = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(cena.ceuTopo), Color(cena.ceuBase)],
      ).createShader(faixa);

    canvas.save();
    canvas.clipRect(tudo);
    canvas.drawRect(tudo, ceu);
    canvas.translate((size.width - _largura * escala) / 2, topoCena);
    canvas.scale(escala, escala);
    final caminhos = _caminhosDe(paisagem);
    for (var i = 0; i < caminhos.length; i++) {
      canvas.drawPath(
        caminhos[i],
        Paint()..color = Color(cena.camadas[i].cor),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(PaisagemPainter antigo) =>
      antigo.paisagem != paisagem || antigo.ajuste != ajuste;
}

/// Mostra uma paisagem, com um [child] opcional por cima (textos, logo).
/// Sem [altura], ocupa a altura que o pai oferecer.
class PaisagemView extends StatelessWidget {
  final Paisagem paisagem;
  final AjustePaisagem ajuste;
  final double? altura;
  final BorderRadius? raio;
  final Widget? child;

  const PaisagemView({
    super.key,
    required this.paisagem,
    this.ajuste = AjustePaisagem.cobrir,
    this.altura,
    this.raio,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final conteudo = Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: CustomPaint(painter: PaisagemPainter(paisagem, ajuste: ajuste)),
        ),
        if (child != null) child!,
      ],
    );
    final recortado = raio == null
        ? conteudo
        : ClipRRect(borderRadius: raio!, child: conteudo);
    if (altura == null) return recortado;
    return SizedBox(height: altura, width: double.infinity, child: recortado);
  }
}

// =====================================================
// PALETA POR OBJETIVO
// =====================================================

/// Cada objetivo é um lugar: um mundo com a sua paisagem e a sua cor.
/// As cores vêm das mesmas folhas e da mesma terra da logo.
class TemaObjetivo {
  final String id;

  /// Nome do lugar ("Floresta"), usado como rótulo.
  final String lugar;
  final Paisagem paisagem;

  /// Cor de destaque: ícones, bordas, botões.
  final Color principal;

  /// Para títulos sobre fundo claro.
  final Color escuro;

  /// Fundo suave de seleção e etiquetas.
  final Color claro;

  /// Fundo ainda mais suave, para cartões.
  final Color suave;

  const TemaObjetivo({
    required this.id,
    required this.lugar,
    required this.paisagem,
    required this.principal,
    required this.escuro,
    required this.claro,
    required this.suave,
  });
}

const TemaObjetivo temaPadrao = TemaObjetivo(
  id: '',
  lugar: 'Alvorecer',
  paisagem: Paisagem.alvorecer,
  principal: Cores.laranja,
  escuro: Color(0xFF7A3418),
  claro: Color(0xFFFBE9D3),
  suave: Color(0xFFFFF4E8),
);

const List<TemaObjetivo> _temas = [
  TemaObjetivo(
    id: 'ver_conteudo',
    lugar: 'Alvorecer',
    paisagem: Paisagem.alvorecer,
    principal: Cores.laranja,
    escuro: Color(0xFF7A3418),
    claro: Color(0xFFFBE9D3),
    suave: Color(0xFFFFF4E8),
  ),
  TemaObjetivo(
    id: 'ler',
    lugar: 'Floresta',
    paisagem: Paisagem.floresta,
    principal: Color(0xFF3F7550),
    escuro: Color(0xFF1F4A31),
    claro: Color(0xFFE2EFE3),
    suave: Color(0xFFF1F7F0),
  ),
  TemaObjetivo(
    id: 'estudar',
    lugar: 'Nascente',
    paisagem: Paisagem.nascente,
    principal: Color(0xFF3E7C80),
    escuro: Color(0xFF1F4A4D),
    claro: Color(0xFFDDEFEF),
    suave: Color(0xFFEFF8F7),
  ),
  TemaObjetivo(
    id: 'oficio',
    lugar: 'Campo',
    paisagem: Paisagem.campo,
    principal: Color(0xFFA9731F),
    escuro: Color(0xFF5E3F0E),
    claro: Color(0xFFF8EBC8),
    suave: Color(0xFFFCF5E2),
  ),
];

/// O tema de um objetivo pelo id; sem id (ou id desconhecido), o padrão.
TemaObjetivo temaDoObjetivo(String? objetivoId) {
  for (final t in _temas) {
    if (t.id == objetivoId) return t;
  }
  return temaPadrao;
}
