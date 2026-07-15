/// Níveis de força de senha (conforme o indicador de segurança do NoxPass).
enum PasswordStrength {
  veryWeak,
  weak,
  medium,
  strong,
  excellent;

  String get label => switch (this) {
        PasswordStrength.veryWeak => 'Muito fraca',
        PasswordStrength.weak => 'Fraca',
        PasswordStrength.medium => 'Média',
        PasswordStrength.strong => 'Forte',
        PasswordStrength.excellent => 'Excelente',
      };

  /// Fração de 0..1 para barras de progresso.
  double get fraction => (index + 1) / PasswordStrength.values.length;
}

/// Resultado da avaliação: o nível + sugestões de melhoria.
class PasswordStrengthResult {
  const PasswordStrengthResult(this.strength, this.suggestions);

  final PasswordStrength strength;
  final List<String> suggestions;
}

/// Avalia a força de uma senha de forma determinística (heurística leve,
/// sem dependências). Não é um estimador de entropia completo — é um guia de
/// UX que premia comprimento e variedade de caracteres.
PasswordStrengthResult evaluatePasswordStrength(String password) {
  if (password.isEmpty) {
    return const PasswordStrengthResult(
      PasswordStrength.veryWeak,
      ['Digite uma senha.'],
    );
  }

  final hasLower = password.contains(RegExp('[a-z]'));
  final hasUpper = password.contains(RegExp('[A-Z]'));
  final hasDigit = password.contains(RegExp('[0-9]'));
  final hasSymbol = password.contains(RegExp('[^A-Za-z0-9]'));
  final length = password.length;

  var score = 0;
  if (length >= 8) score++;
  if (length >= 12) score++;
  if (length >= 16) score++;
  if (hasLower) score++;
  if (hasUpper) score++;
  if (hasDigit) score++;
  if (hasSymbol) score++;

  // Senhas curtas nunca passam de "Fraca", por mais variadas que sejam.
  final strength = switch (length < 8 ? (score >= 2 ? 1 : 0) : score) {
    <= 2 => PasswordStrength.veryWeak,
    3 => PasswordStrength.weak,
    4 => PasswordStrength.medium,
    5 || 6 => PasswordStrength.strong,
    _ => PasswordStrength.excellent,
  };

  final suggestions = <String>[
    if (length < 12) 'Use pelo menos 12 caracteres.',
    if (!hasUpper) 'Adicione letras maiúsculas.',
    if (!hasLower) 'Adicione letras minúsculas.',
    if (!hasDigit) 'Adicione números.',
    if (!hasSymbol) 'Adicione símbolos (!, @, #, …).',
  ];

  return PasswordStrengthResult(strength, suggestions);
}
