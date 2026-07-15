import 'package:flutter/material.dart';

import '../theme/nox_colors.dart';
import 'password_strength.dart';

/// Barras segmentadas + rótulo que refletem a força de uma senha.
class PasswordStrengthMeter extends StatelessWidget {
  const PasswordStrengthMeter({required this.password, super.key});

  final String password;

  /// Quantidade de segmentos preenchidos por nível (de 5).
  static const _segments = 5;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nox = context.nox;
    final result = evaluatePasswordStrength(password);
    final color = _colorFor(result.strength, theme.colorScheme, nox);
    final filled = password.isEmpty ? 0 : (result.strength.index + 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 0; i < _segments; i++) ...[
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  height: 5,
                  decoration: BoxDecoration(
                    color: i < filled ? color : nox.surface3,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              if (i < _segments - 1) const SizedBox(width: 5),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Text(
          password.isEmpty ? ' ' : 'Força: ${result.strength.label}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: password.isEmpty ? null : color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Color _colorFor(PasswordStrength strength, ColorScheme colors, NoxColors nox) {
    return switch (strength) {
      PasswordStrength.veryWeak => colors.error,
      PasswordStrength.weak => colors.error,
      PasswordStrength.medium => nox.warn,
      PasswordStrength.strong => nox.ok,
      PasswordStrength.excellent => nox.ok,
    };
  }
}
