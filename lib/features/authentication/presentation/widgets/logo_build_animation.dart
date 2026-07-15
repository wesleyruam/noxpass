import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Animação de construção ("build-up") da logo do NoxPass, feita 100% em
/// vetor com [CustomPainter] — leve, nítida e fiel à marca.
///
/// Sequência (≈4,2s): tela escura → partículas de luz roxas → o contorno do
/// cadeado se desenha → o traço diagonal ("N") entra → a fechadura surge com
/// um flare → pulso de brilho final → logo estática. Toque para pular.
class LogoBuildAnimation extends StatefulWidget {
  const LogoBuildAnimation({
    required this.onCompleted,
    this.size = 180,
    super.key,
  });

  final VoidCallback onCompleted;
  final double size;

  @override
  State<LogoBuildAnimation> createState() => _LogoBuildAnimationState();
}

class _LogoBuildAnimationState extends State<LogoBuildAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;
  bool _done = false;

  // Cores da marca (splash é sempre "cofre à noite", tema fixo escuro).
  static const Color _accent = Color(0xFF9B8CFF);
  static const Color _accentStrong = Color(0xFF6C5CE7);

  @override
  void initState() {
    super.initState();
    final rng = math.Random(7);
    _particles = List.generate(26, (_) {
      final angle = rng.nextDouble() * math.pi * 2;
      return _Particle(
        dir: Offset(math.cos(angle), math.sin(angle)),
        dist: 0.25 + rng.nextDouble() * 0.9,
        radius: 0.8 + rng.nextDouble() * 1.8,
        twinkle: rng.nextDouble(),
      );
    });
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) _finish();
      });
    _controller.forward();
  }

  void _finish() {
    if (_done) return;
    _done = true;
    widget.onCompleted();
  }

  void _skip() {
    if (_done) return;
    _controller.stop();
    _controller.value = 1;
    _finish();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _skip,
      child: SizedBox(
        width: widget.size,
        height: widget.size * 1.25,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            painter: _LogoPainter(
              t: _controller.value,
              particles: _particles,
              accent: _accent,
              accentStrong: _accentStrong,
            ),
          ),
        ),
      ),
    );
  }
}

class _Particle {
  const _Particle({
    required this.dir,
    required this.dist,
    required this.radius,
    required this.twinkle,
  });

  final Offset dir;
  final double dist;
  final double radius;
  final double twinkle;
}

/// Utilitário: normaliza [t] dentro do intervalo [a, b] em 0..1.
double _seg(double t, double a, double b) =>
    ((t - a) / (b - a)).clamp(0.0, 1.0);

class _LogoPainter extends CustomPainter {
  _LogoPainter({
    required this.t,
    required this.particles,
    required this.accent,
    required this.accentStrong,
  });

  final double t;
  final List<_Particle> particles;
  final Color accent;
  final Color accentStrong;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Caixa do cadeado (retrato), centralizada.
    final padW = size.width * 0.66;
    final padH = padW * 1.5;
    final rect = Rect.fromCenter(
      center: center,
      width: padW,
      height: padH,
    );

    _paintParticles(canvas, center, size);

    // Progresso das fases.
    final drawOutline = Curves.easeInOut.transform(_seg(t, 0.20, 0.62));
    final drawDiagonal = Curves.easeInOut.transform(_seg(t, 0.55, 0.72));
    final keyhole = Curves.easeOut.transform(_seg(t, 0.70, 0.84));
    final pulse = _seg(t, 0.82, 0.96);

    // Pulso final: leve escala com overshoot.
    final scale = 1 + 0.06 * math.sin(pulse * math.pi);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(scale);
    canvas.translate(-center.dx, -center.dy);

    final geo = _PadlockGeometry(rect);
    final stroke = padW * 0.085;

    // Brilho geral cresce ao longo do desenho e no pulso.
    final glowStrength =
        (0.3 + 0.7 * drawOutline) * (1 + 0.6 * math.sin(pulse * math.pi));

    // Gradiente da marca ao longo do cadeado.
    final shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFB0A5FF), Color(0xFF7C6CF6)],
    ).createShader(rect);

    // 1) Contorno (arco + corpo) desenhando-se.
    final outline = geo.outline();
    _drawGlowStroke(canvas, outline, drawOutline, stroke, shader, glowStrength);

    // 2) Traço diagonal "N".
    if (drawDiagonal > 0) {
      _drawGlowStroke(
          canvas, geo.diagonal(), drawDiagonal, stroke, shader, glowStrength);
    }

    // 3) Fechadura com fade + flare.
    if (keyhole > 0) {
      final c = geo.keyholeCenter();

      // Flare radial no centro da fechadura (por baixo).
      final flare = math.sin(keyhole * math.pi);
      if (flare > 0) {
        canvas.drawCircle(
          c,
          padW * 0.5 * flare,
          Paint()
            ..shader = RadialGradient(
              colors: [
                accent.withValues(alpha: 0.4 * flare),
                accent.withValues(alpha: 0),
              ],
            ).createShader(Rect.fromCircle(center: c, radius: padW * 0.5)),
        );
      }

      // Fechadura em si (cor sólida com fade-in).
      canvas.drawPath(
        geo.keyhole(),
        Paint()
          ..style = PaintingStyle.fill
          ..color = const Color(0xFFB0A5FF).withValues(alpha: keyhole),
      );
    }

    canvas.restore();
  }

  void _paintParticles(Canvas canvas, Offset center, Size size) {
    // Surgem (0.05–0.30), depois convergem/desaparecem conforme a logo forma.
    final appear = _seg(t, 0.05, 0.30);
    final fade = 1 - _seg(t, 0.35, 0.68);
    final baseAlpha = appear * fade;
    if (baseAlpha <= 0) return;

    final radius = size.width * 0.5;
    for (final p in particles) {
      // Convergem levemente para o centro enquanto somem.
      final converge = 1 - 0.4 * _seg(t, 0.30, 0.68);
      final pos = center + p.dir * (p.dist * radius * converge);
      final twinkle = 0.5 + 0.5 * math.sin((t * 8 + p.twinkle * 6) * math.pi);
      final alpha = (baseAlpha * twinkle).clamp(0.0, 1.0);
      canvas.drawCircle(
        pos,
        p.radius,
        Paint()
          ..color = accent.withValues(alpha: alpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
      );
    }
  }

  /// Desenha um traço até a fração [frac], com uma passada de glow por baixo.
  void _drawGlowStroke(
    Canvas canvas,
    Path path,
    double frac,
    double width,
    Shader shader,
    double glow,
  ) {
    if (frac <= 0) return;
    final partial = _extractUpTo(path, frac);

    // Glow (borrado, largo).
    canvas.drawPath(
      partial,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width * 1.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = accentStrong.withValues(alpha: (0.5 * glow).clamp(0.0, 0.9))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, width * 0.9),
    );
    // Traço nítido.
    canvas.drawPath(
      partial,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..shader = shader,
    );
  }

  /// Extrai a porção inicial de [path] correspondente à fração [frac] do
  /// comprimento total (percorrendo os contornos em ordem).
  Path _extractUpTo(Path path, double frac) {
    final metrics = path.computeMetrics().toList();
    final total = metrics.fold<double>(0, (s, m) => s + m.length);
    var remaining = total * frac;
    final out = Path();
    for (final m in metrics) {
      if (remaining <= 0) break;
      final len = math.min(remaining, m.length);
      out.addPath(m.extractPath(0, len), Offset.zero);
      remaining -= len;
    }
    return out;
  }

  @override
  bool shouldRepaint(_LogoPainter old) => old.t != t;
}

/// Geometria vetorial do cadeado do NoxPass, derivada de um retângulo.
class _PadlockGeometry {
  _PadlockGeometry(this.r)
      : cx = r.center.dx,
        w = r.width,
        h = r.height,
        bodyTop = r.top + r.height * 0.32;

  final Rect r;
  final double cx;
  final double w;
  final double h;
  final double bodyTop;

  double get _bodyH => r.bottom - bodyTop;

  /// Arco (shackle) + corpo hexagonal, em um único caminho (desenha nessa
  /// ordem: primeiro o arco, depois o corpo).
  Path outline() {
    final p = Path();
    // Shackle (∩) mais estreito que o corpo.
    final legTop = r.top + h * 0.13;
    final shHalf = w * 0.24;
    p
      ..moveTo(cx - shHalf, bodyTop)
      ..lineTo(cx - shHalf, legTop)
      ..arcToPoint(
        Offset(cx + shHalf, legTop),
        radius: Radius.circular(shHalf),
        clockwise: true,
      )
      ..lineTo(cx + shHalf, bodyTop);

    // Corpo: escudo hexagonal — laterais quase verticais, base em ponta curta.
    final midY = bodyTop + _bodyH * 0.55;
    p
      ..moveTo(cx - w * 0.38, bodyTop)
      ..lineTo(cx + w * 0.38, bodyTop)
      ..lineTo(cx + w * 0.44, midY)
      ..lineTo(cx, r.bottom)
      ..lineTo(cx - w * 0.44, midY)
      ..close();
    return p;
  }

  /// Traço diagonal ("N") atravessando o corpo (contido nas bordas).
  Path diagonal() {
    return Path()
      ..moveTo(cx - w * 0.20, bodyTop + _bodyH * 0.10)
      ..lineTo(cx + w * 0.20, r.bottom - _bodyH * 0.24);
  }

  Offset keyholeCenter() => Offset(cx, bodyTop + _bodyH * 0.46);

  /// Fechadura: círculo + haste trapezoidal.
  Path keyhole() {
    final c = keyholeCenter();
    final rr = w * 0.11;
    final p = Path()..addOval(Rect.fromCircle(center: c, radius: rr));
    final stemBottom = c.dy + _bodyH * 0.22;
    p
      ..moveTo(c.dx - rr * 0.55, c.dy + rr * 0.4)
      ..lineTo(c.dx + rr * 0.55, c.dy + rr * 0.4)
      ..lineTo(c.dx + rr * 0.28, stemBottom)
      ..lineTo(c.dx - rr * 0.28, stemBottom)
      ..close();
    return p;
  }
}
