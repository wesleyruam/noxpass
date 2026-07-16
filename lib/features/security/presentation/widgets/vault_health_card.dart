import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/theme/nox_colors.dart';
import '../security_providers.dart';

/// Cartão "Saúde do cofre": anel de pontuação + chips de diagnóstico.
///
/// Peça-assinatura da home. Acionável quando há problemas (leva ao relatório).
class VaultHealthCard extends ConsumerWidget {
  const VaultHealthCard({this.onTap, super.key});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(securityReportProvider);
    final theme = Theme.of(context);
    final nox = context.nox;

    final total = report.total;
    final weak = report.weakCount;
    final reused = report.reusedCount;
    final strong = (total - weak).clamp(0, total);

    // Pontuação: penaliza fracas cheio e reutilizadas pela metade.
    final penalty = math.min(total.toDouble(), weak + reused * 0.5);
    final score = total == 0 ? 100 : (100 * (total - penalty) / total).round();

    final Color ringColor;
    if (total == 0 || score >= 80) {
      ringColor = nox.ok;
    } else if (score >= 50) {
      ringColor = nox.warn;
    } else {
      ringColor = theme.colorScheme.error;
    }

    final subtitle = total == 0
        ? 'Adicione senhas para começar'
        : '$total ${total == 1 ? 'item protegido' : 'itens protegidos'}';

    final card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: nox.border),
      ),
      child: Row(
        children: [
          _ScoreRing(
            value: total == 0 ? 1 : score / 100,
            score: score,
            hasScore: total != 0,
            color: ringColor,
            trackColor: nox.surface3,
            textColor: theme.colorScheme.onSurface,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Saúde do cofre',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(color: nox.textDim),
                ),
                if (total > 0) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (weak > 0)
                        _HealthChip(
                          color: theme.colorScheme.error,
                          label: '$weak ${weak == 1 ? 'fraca' : 'fracas'}',
                        ),
                      if (reused > 0)
                        _HealthChip(
                          color: nox.warn,
                          label: '$reused reutilizada${reused == 1 ? '' : 's'}',
                        ),
                      _HealthChip(
                        color: nox.ok,
                        label: '$strong forte${strong == 1 ? '' : 's'}',
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (onTap != null && report.hasIssues)
            Icon(Icons.chevron_right, color: nox.textFaint),
        ],
      ),
    );

    if (onTap == null || !report.hasIssues) return card;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: card,
    );
  }
}

/// Anel de pontuação com traço arredondado e trilha ao fundo. Preenche e
/// conta de 0 até o valor ao aparecer (respeita "reduzir movimento").
class _ScoreRing extends StatelessWidget {
  const _ScoreRing({
    required this.value,
    required this.score,
    required this.hasScore,
    required this.color,
    required this.trackColor,
    required this.textColor,
  });

  final double value;
  final int score;
  final bool hasScore;
  final Color color;
  final Color trackColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return SizedBox(
      width: 64,
      height: 64,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration:
            reduceMotion ? Duration.zero : const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, t, _) {
          return CustomPaint(
            painter: _RingPainter(
              value: (value * t).clamp(0, 1),
              color: color,
              trackColor: trackColor,
            ),
            child: Center(
              child: Text(
                hasScore ? '${(score * t).round()}' : '—',
                style: context.mono(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.value,
    required this.color,
    required this.trackColor,
  });

  final double value;
  final Color color;
  final Color trackColor;

  static const double _stroke = 6.5;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - _stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..color = trackColor;
    canvas.drawCircle(center, radius, track);

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * value, false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.color != color || old.trackColor != trackColor;
}

/// Chip com ponto colorido: "1 fraca", "18 fortes".
class _HealthChip extends StatelessWidget {
  const _HealthChip({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
