import 'package:flutter/material.dart';

import 'password_strength.dart';

/// Barra + rótulo que refletem a força de uma senha.
class PasswordStrengthMeter extends StatelessWidget {
  const PasswordStrengthMeter({required this.password, super.key});

  final String password;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final result = evaluatePasswordStrength(password);
    final color = _colorFor(result.strength, theme.colorScheme);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: password.isEmpty ? 0 : result.strength.fraction,
            minHeight: 6,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          password.isEmpty ? ' ' : 'Força: ${result.strength.label}',
          style: theme.textTheme.bodySmall?.copyWith(color: color),
        ),
      ],
    );
  }

  Color _colorFor(PasswordStrength strength, ColorScheme colors) {
    return switch (strength) {
      PasswordStrength.veryWeak => colors.error,
      PasswordStrength.weak => colors.error,
      PasswordStrength.medium => Colors.orange,
      PasswordStrength.strong => Colors.lightGreen,
      PasswordStrength.excellent => Colors.green,
    };
  }
}
