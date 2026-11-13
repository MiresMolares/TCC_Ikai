"""Gera as paisagens do Ikai.

Uso (na raiz do projeto):  python3 tools/gerar_paisagens.py

Escreve lib/widgets/paisagens_dados.dart (os desenhos usados pelo app) e
tools/paisagens_previa.html (abra no navegador para ver as seis cenas).
Para mudar uma cena, edite as funções cena_*() abaixo e rode de novo.
"""
import math, random

W, H = 400.0, 240.0
K = 0.5523

class P:
    """Caminho em coordenadas de projeto (400x240): lista de operações."""
    def __init__(self): self.o = []
    def M(self, x, y): self.o += [(0, x, y)]; return self
    def L(self, x, y): self.o += [(1, x, y)]; return self
    def C(self, a, b, c, d, e, f): self.o += [(2, a, b, c, d, e, f)]; return self
    def Z(self): self.o += [(3,)]; return self
    def extend(self, other): self.o += other.o; return self
    def svg(self):
        s = []
        for op in self.o:
            if op[0] == 0: s.append("M%.1f %.1f" % op[1:])
            elif op[0] == 1: s.append("L%.1f %.1f" % op[1:])
            elif op[0] == 2: s.append("C%.1f %.1f %.1f %.1f %.1f %.1f" % op[1:])
            else: s.append("Z")
        return " ".join(s)
    def flat(self):
        out = []
        for op in self.o:
            out.append(float(op[0]))
            out += [round(v, 1) for v in op[1:]]
        return out

def circle(cx, cy, r):
    p = P().M(cx + r, cy)
    p.C(cx + r, cy + K*r, cx + K*r, cy + r, cx, cy + r)
    p.C(cx - K*r, cy + r, cx - r, cy + K*r, cx - r, cy)
    p.C(cx - r, cy - K*r, cx - K*r, cy - r, cx, cy - r)
    p.C(cx + K*r, cy - r, cx + r, cy - K*r, cx + r, cy)
    return p.Z()

def ellipse(cx, cy, rx, ry):
    p = P().M(cx + rx, cy)
    p.C(cx + rx, cy + K*ry, cx + K*rx, cy + ry, cx, cy + ry)
    p.C(cx - K*rx, cy + ry, cx - rx, cy + K*ry, cx - rx, cy)
    p.C(cx - rx, cy - K*ry, cx - K*rx, cy - ry, cx, cy - ry)
    p.C(cx + K*rx, cy - ry, cx + rx, cy - K*ry, cx + rx, cy)
    return p.Z()

def smooth(points, close_to=None):
    """Catmull-Rom -> cubicas. Se close_to=(y) fecha por baixo até y."""
    p = P().M(*points[0])
    n = len(points)
    for i in range(n - 1):
        p0 = points[max(i - 1, 0)]; p1 = points[i]; p2 = points[i + 1]; p3 = points[min(i + 2, n - 1)]
        c1 = (p1[0] + (p2[0] - p0[0]) / 6, p1[1] + (p2[1] - p0[1]) / 6)
        c2 = (p2[0] - (p3[0] - p1[0]) / 6, p2[1] - (p3[1] - p1[1]) / 6)
        p.C(c1[0], c1[1], c2[0], c2[1], p2[0], p2[1])
    if close_to is not None:
        p.L(points[-1][0], close_to).L(points[0][0], close_to).Z()
    return p

def hill(base, amp, seed, step=50, x0=-20, x1=470, bottom=H + 4):
    rnd = random.Random(seed)
    xs = [x0 + i * step for i in range(int((x1 - x0) / step) + 1)]
    ph = rnd.uniform(0, 6.28)
    pts = [(x, base + amp * math.sin(x / 60.0 + ph) + rnd.uniform(-amp * .35, amp * .35)) for x in xs]
    return smooth(pts, close_to=bottom), pts

def hill_y(pts, x):
    for i in range(len(pts) - 1):
        if pts[i][0] <= x <= pts[i + 1][0]:
            t = (x - pts[i][0]) / (pts[i + 1][0] - pts[i][0])
            return pts[i][1] + (pts[i + 1][1] - pts[i][1]) * t
    return pts[-1][1]

def rpoly(pts, r=0.18):
    """Polígono fechado com cantos suavizados (r = fração da aresta)."""
    n = len(pts)
    def lerp(a, b, t): return (a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t)
    p = P()
    for i in range(n):
        a, b, c = pts[i - 1], pts[i], pts[(i + 1) % n]
        s = lerp(b, a, r); e = lerp(b, c, r)
        if i == 0: p.M(*s)
        else: p.L(*s)
        p.C(*lerp(s, b, .55), *lerp(e, b, .55), *e)
    return p.Z()

def rot(pt, ang, ox, oy):
    c, s = math.cos(ang), math.sin(ang)
    x, y = pt
    return (ox + x * c - y * s, oy + x * s + y * c)

def leaf(x, y, length, width, ang):
    """Folha como a da logo: base em (x,y), ponta a 'length', ang em graus (0 = para cima)."""
    a = math.radians(ang - 90)
    def t(px, py): return rot((px, py), a, x, y)
    p = P().M(*t(0, 0))
    p.C(*t(length * .25, -width), *t(length * .75, -width * .9), *t(length, 0))
    p.C(*t(length * .75, width * .9), *t(length * .25, width), *t(0, 0))
    return p.Z()

def pine(x, base, h, w, tiers=3):
    p = P()
    top = base - h
    th = h * .22
    p.extend(rpoly([(x - w * .07, base), (x + w * .07, base), (x + w * .07, base - th), (x - w * .07, base - th)], .1))
    seg = (h - th) / tiers
    for i in range(tiers):
        yb = base - th - seg * i * .78
        yt = yb - seg * 1.25
        ww = w * (1 - i * .22) * .5
        p.extend(rpoly([(x - ww, yb), (x + ww, yb), (x, yt)], .14))
    return p

def roundtree(x, base, r):
    p = P().extend(rpoly([(x - r * .09, base), (x + r * .09, base), (x + r * .09, base - r * 1.1), (x - r * .09, base - r * 1.1)], .1))
    p.extend(circle(x, base - r * 1.5, r))
    p.extend(circle(x - r * .6, base - r * 1.15, r * .7))
    p.extend(circle(x + r * .6, base - r * 1.15, r * .7))
    return p

def cloud(x, y, s=1.0):
    p = P()
    for dx, dy, r in [(0, 0, 11), (14, -6, 14), (30, 0, 11), (15, 3, 11)]:
        p.extend(ellipse(x + dx * s, y + dy * s, r * s * 1.2, r * s * .8))
    return p

def bird(x, y, s=1.0):
    p = P().M(x, y)
    p.C(x + 4*s, y - 5*s, x + 8*s, y - 5*s, x + 10*s, y - 1*s)
    p.C(x + 12*s, y - 5*s, x + 16*s, y - 5*s, x + 20*s, y)
    p.C(x + 16*s, y - 3*s, x + 12*s, y - 3*s, x + 10*s, y + 1.5*s)
    p.C(x + 8*s, y - 3*s, x + 4*s, y - 3*s, x, y)
    return p.Z()

def sprout(x, base, h, ang=0):
    p = P()
    tip = (x + math.sin(math.radians(ang)) * h * .4, base - h)
    p.M(x - 1.6, base).C(x - 1.6, base - h * .5, tip[0] - 1.2, base - h * .6, tip[0] - .8, tip[1])
    p.L(tip[0] + .8, tip[1]).C(tip[0] + 1.2, base - h * .6, x + 1.6, base - h * .5, x + 1.6, base).Z()
    p.extend(leaf(tip[0], tip[1] + h * .12, h * .62, h * .2, ang - 42))
    p.extend(leaf(tip[0], tip[1] + h * .12, h * .62, h * .2, ang + 42))
    return p

def wheat(x, base, h, lean=0):
    p = P()
    tx = x + lean
    p.M(x - .9, base).C(x - .9, base - h * .5, tx - .6, base - h * .6, tx - .6, base - h)
    p.L(tx + .6, base - h).C(tx + .6, base - h * .6, x + .9, base - h * .5, x + .9, base).Z()
    for i in range(5):
        gy = base - h + i * h * .07
        for side in (-1, 1):
            p.extend(leaf(tx, gy + h * .06, h * .17, h * .042, side * 32))
    p.extend(leaf(tx, base - h - h * .01, h * .17, h * .042, 0))
    return p

def mountains(peaks, base=H + 4, soft=.12):
    pts = [(-30, base)] + peaks + [(430, base)]
    return rpoly(pts, soft)

def snowcap(peak, left, right, depth=.26):
    """Neve: do pico até 'depth' das arestas, com borda irregular."""
    lx = peak[0] + (left[0] - peak[0]) * depth; ly = peak[1] + (left[1] - peak[1]) * depth
    rx = peak[0] + (right[0] - peak[0]) * depth; ry = peak[1] + (right[1] - peak[1]) * depth
    mx, my = (lx + rx) / 2, max(ly, ry) + 4
    return rpoly([peak, (rx, ry), (rx - (rx - mx) * .35, ry + 3), (mx, my + 2), (lx + (mx - lx) * .35, ly + 3), (lx, ly)], .12)

def stripe(pts, thick):
    """Faixa fina que acompanha uma curva (sulcos do campo)."""
    top = pts
    bot = [(x, y + thick) for x, y in reversed(pts)]
    p = smooth(top)
    n = len(bot)
    p.L(*bot[0])
    for i in range(n - 1):
        p0 = bot[max(i - 1, 0)]; p1 = bot[i]; p2 = bot[i + 1]; p3 = bot[min(i + 2, n - 1)]
        p.C(p1[0] + (p2[0] - p0[0]) / 6, p1[1] + (p2[1] - p0[1]) / 6, p2[0] - (p3[0] - p1[0]) / 6, p2[1] - (p3[1] - p1[1]) / 6, p2[0], p2[1])
    return p.Z()

def argb(hexrgb, a=1.0):
    return (int(round(a * 255)) << 24) | int(hexrgb.lstrip('#'), 16)

# ----------------------------------------------------------------- cenas
def cena_alvorecer():
    L = []
    L.append((argb('#F9E4C8', .55), circle(305, 150, 62)))      # halo
    L.append((argb('#F4C39A', .6), circle(305, 150, 44)))
    L.append((argb('#E07A45'), circle(305, 150, 28)))            # sol
    L.append((argb('#FFFFFF', .55), cloud(60, 95, 1.1)))
    L.append((argb('#FFFFFF', .45), cloud(335, 74, .8)))
    L.append((argb('#B9563A', .75), bird(110, 70, 1)))
    L.append((argb('#B9563A', .75), bird(135, 60, .8)))
    far, fp = hill(168, 8, 11)
    L.append((argb('#E7B58F'), far))
    mid, mp = hill(188, 9, 12)
    L.append((argb('#9DB97C'), mid))
    for x in (70, 118, 330):
        L.append((argb('#6E9A63'), roundtree(x, hill_y(mp, x) + 3, 8)))
    near, np_ = hill(212, 8, 13)
    L.append((argb('#5E8F5B'), near))
    for x, h in ((60, 22), (150, 16), (290, 24), (350, 17)):
        L.append((argb('#355E3B'), sprout(x, hill_y(np_, x) + 6, h, ((x * 7) % 21) - 10)))
    return (argb('#FBE9D3'), argb('#F6CFA6')), L

def cena_floresta():
    L = []
    L.append((argb('#FFFFFF', .35), circle(300, 120, 50)))
    L.append((argb('#F7F3E3'), circle(300, 120, 30)))
    L.append((argb('#FFFFFF', .5), cloud(70, 92, 1.0)))
    far, fp = hill(170, 6, 21)
    L.append((argb('#B5D3BA'), far))
    for x in range(10, 400, 26):
        L.append((argb('#A2C8AA'), pine(x, hill_y(fp, x) + 8, 40 + (x * 13) % 14, 20)))
    mid, mp = hill(192, 7, 22)
    L.append((argb('#78A985'), mid))
    for x in range(0, 410, 34):
        L.append((argb('#5F9570'), pine(x + 6, hill_y(mp, x + 6) + 8, 58 + (x * 7) % 18, 28)))
    near, np_ = hill(220, 6, 23)
    L.append((argb('#3F7550'), near))
    for x in (30, 120, 250, 360):
        L.append((argb('#2F5E40'), pine(x, hill_y(np_, x) + 10, 88 + (x % 17), 40, 4)))
    for x, h in ((70, 15), (190, 12), (310, 16)):
        L.append((argb('#9FD0A0'), sprout(x, hill_y(np_, x) + 8, h, 8)))
    return (argb('#E6F1E5'), argb('#CFE4D1')), L

def cena_nascente():
    L = []
    L.append((argb('#FFFFFF', .4), circle(105, 112, 46)))
    L.append((argb('#F6EBD0'), circle(105, 112, 26)))
    L.append((argb('#FFFFFF', .55), cloud(250, 80, 1.0)))
    L.append((argb('#FFFFFF', .4), cloud(335, 105, .7)))
    pk1 = [(40, 168), (120, 112), (175, 150), (245, 90), (320, 148), (370, 124)]
    L.append((argb('#9CC3C4'), mountains(pk1)))
    L.append((argb('#F3F8F6', .95), snowcap((245, 90), (175, 150), (320, 148))))
    L.append((argb('#F3F8F6', .9), snowcap((120, 112), (40, 168), (175, 150), .3)))
    pk2 = [(-10, 190), (70, 150), (140, 186), (215, 138), (300, 190), (390, 160)]
    L.append((argb('#689DA0'), mountains(pk2)))
    L.append((argb('#F3F8F6', .95), snowcap((215, 138), (140, 186), (300, 190), .22)))
    lago = smooth([(-10, 196), (100, 193), (200, 197), (300, 193), (410, 196)], close_to=H + 4)
    L.append((argb('#3E7C80'), lago))
    for (x, y, w, a) in ((60, 208, 70, .5), (200, 214, 90, .4), (310, 205, 60, .45), (140, 226, 80, .35), (290, 230, 70, .3)):
        L.append((argb('#9CCFCB', a), stripe([(x - w / 2, y), (x, y - 1.2), (x + w / 2, y)], 2.6)))
    marg, mgp = hill(232, 4, 33)
    L.append((argb('#2F6366'), marg))
    for x, h in ((24, 20), (360, 22), (380, 16)):
        L.append((argb('#1F4A4D'), sprout(x, hill_y(mgp, x) + 6, h, -8)))
    return (argb('#DDEFEF'), argb('#BCDFDC')), L

def cena_campo():
    L = []
    L.append((argb('#FBEBC1', .55), circle(310, 122, 56)))
    L.append((argb('#F3C56A', .8), circle(310, 122, 38)))
    L.append((argb('#E39B3A'), circle(310, 122, 24)))
    L.append((argb('#FFFFFF', .5), cloud(70, 90, 1.0)))
    L.append((argb('#B5701E', .7), bird(160, 72, .9)))
    far, fp = hill(166, 7, 41)
    L.append((argb('#E3C77F'), far))
    mid, mp = hill(188, 9, 42)
    L.append((argb('#CFA24B'), mid))
    for k in range(4):
        pts = [(x, hill_y(mp, x) + 9 + k * 7) for x in range(-20, 470, 50)]
        L.append((argb('#B58A33', .7), stripe(pts, 2.2)))
    L.append((argb('#7C6A2C'), roundtree(92, hill_y(mp, 92) + 4, 9)))
    near, np_ = hill(214, 7, 43)
    L.append((argb('#A29A3F'), near))
    for k in range(3):
        pts = [(x, hill_y(np_, x) + 9 + k * 8) for x in range(-20, 470, 50)]
        L.append((argb('#857E2F', .75), stripe(pts, 2.4)))
    for x in range(14, 400, 38):
        L.append((argb('#7A5D1C'), wheat(x, hill_y(np_, x) + 22, 46 + (x * 3) % 12, ((x * 5) % 9) - 4)))
    L.append((argb('#4F7A38'), sprout(188, hill_y(np_, 188) + 14, 34, 4)))
    return (argb('#F8EBC8'), argb('#F1DCA4')), L

def cena_entardecer():
    L = []
    L.append((argb('#FFE3B0', .5), circle(200, 168, 78)))
    L.append((argb('#F7B26A', .7), circle(200, 168, 50)))
    L.append((argb('#E0723E'), circle(200, 168, 30)))
    L.append((argb('#FFFFFF', .35), cloud(60, 100, 1.1)))
    L.append((argb('#FFFFFF', .3), cloud(310, 84, 1.0)))
    L.append((argb('#8E4B3D', .7), bird(280, 120, .9)))
    far, fp = hill(180, 6, 51)
    L.append((argb('#C9889A'), far))
    mid, mp = hill(198, 7, 52)
    L.append((argb('#9A6F8F'), mid))
    for x in (60, 330):
        L.append((argb('#6F4F72'), roundtree(x, hill_y(mp, x) + 4, 9)))
    near, np_ = hill(220, 6, 53)
    L.append((argb('#5E4B73'), near))
    for x, h in ((40, 20), (150, 14), (270, 18), (360, 22)):
        L.append((argb('#3E3355'), sprout(x, hill_y(np_, x) + 6, h, ((x * 7) % 17) - 8)))
    return (argb('#F8D9C0'), argb('#F2B58C')), L

def cena_noite():
    L = []
    rnd = random.Random(7)
    for _ in range(46):
        x, y = rnd.uniform(6, 394), rnd.uniform(6, 150)
        L.append((argb('#F4EFD6', rnd.uniform(.35, .9)), circle(x, y, rnd.uniform(.7, 1.7))))
    L.append((argb('#F4EFD6', .16), circle(290, 78, 46)))
    L.append((argb('#F4EFD6', .25), circle(290, 78, 33)))
    L.append((argb('#F4EFD6'), circle(290, 78, 22)))
    L.append((argb('#E3DDBE'), circle(283, 72, 4)))
    L.append((argb('#E3DDBE'), circle(297, 84, 3)))
    far, fp = hill(176, 7, 61)
    L.append((argb('#2D4A5C'), far))
    mid, mp = hill(196, 8, 62)
    L.append((argb('#244053'), mid))
    for x in range(14, 400, 44):
        L.append((argb('#1D3546'), pine(x, hill_y(mp, x) + 6, 38 + (x * 5) % 14, 20)))
    near, np_ = hill(220, 6, 63)
    L.append((argb('#162B3A'), near))
    for x, h in ((50, 20), (170, 14), (330, 22)):
        L.append((argb('#2F6B58'), sprout(x, hill_y(np_, x) + 6, h, ((x * 7) % 17) - 8)))
    return (argb('#1A3446'), argb('#34586B')), L

CENAS = {
    'alvorecer': cena_alvorecer(), 'floresta': cena_floresta(), 'nascente': cena_nascente(),
    'campo': cena_campo(), 'entardecer': cena_entardecer(), 'noite': cena_noite(),
}

def hexa(c): return '#%06X' % (c & 0xFFFFFF), ((c >> 24) & 255) / 255

def svg_cena(nome, w=400, h=240):
    (t, b), layers = CENAS[nome]
    th, _ = hexa(t); bh, _ = hexa(b)
    out = ['<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 240" width="%d" height="%d">' % (w, h),
           '<defs><linearGradient id="c%s" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="%s"/><stop offset="1" stop-color="%s"/></linearGradient></defs>' % (nome, th, bh),
           '<rect width="400" height="240" fill="url(#c%s)"/>' % nome]
    for cor, path in layers:
        hx, a = hexa(cor)
        out.append('<path d="%s" fill="%s" fill-opacity="%.2f"/>' % (path.svg(), hx, a))
    out.append('</svg>')
    return "\n".join(out)

def dart_data():
    s = ["// GERADO: ilustrações de paisagem do Ikai em coordenadas de projeto 400 x 240.",
         "// Cada traço é uma lista de operações: 0 = moveTo(x,y), 1 = lineTo(x,y),",
         "// 2 = cubicTo(x1,y1,x2,y2,x,y), 3 = close. Veja paisagem.dart.",
         "// Para mudar uma cena, edite a lista de camadas (cor 0xAARRGGBB e traço).",
         "", "class CamadaPaisagem {", "  final int cor;", "  final List<double> traco;", "  const CamadaPaisagem(this.cor, this.traco);", "}", "",
         "class CenaPaisagem {", "  final int ceuTopo;", "  final int ceuBase;", "  final List<CamadaPaisagem> camadas;", "  const CenaPaisagem(this.ceuTopo, this.ceuBase, this.camadas);", "}", ""]
    for nome, ((t, b), layers) in CENAS.items():
        s.append("const CenaPaisagem cena%s = CenaPaisagem(" % (nome.capitalize()))
        s.append("  0x%08X," % t); s.append("  0x%08X," % b); s.append("  [")
        for cor, path in layers:
            nums = ", ".join(("%g" % v) for v in path.flat())
            # quebra em linhas de ~76 colunas
            import textwrap
            linhas = textwrap.wrap(nums, 66)
            s.append("    CamadaPaisagem(0x%08X, [" % cor)
            for l in linhas: s.append("      " + l)
            s.append("    ]),")
        s.append("  ],"); s.append(");"); s.append("")
    return "\n".join(s)

if __name__ == '__main__':
    import pathlib
    raiz = pathlib.Path(__file__).resolve().parent.parent
    (raiz / 'lib' / 'widgets' / 'paisagens_dados.dart').write_text(dart_data())
    html = ['<html><body style="margin:0;font:14px sans-serif"><div style="display:grid;grid-template-columns:repeat(3,400px);gap:10px;padding:10px">']
    for n in CENAS:
        html.append('<div><b>%s</b><br>%s</div>' % (n, svg_cena(n)))
    html.append('</div></body></html>')
    (raiz / 'tools' / 'paisagens_previa.html').write_text("\n".join(html))
    print('ok:', ', '.join(CENAS))
