import 'package:flutter_test/flutter_test.dart';
import 'package:noxpass/shared/security/password_strength.dart';

void main() {
  PasswordStrength strengthOf(String p) =>
      evaluatePasswordStrength(p).strength;

  group('evaluatePasswordStrength', () {
    test('vazia é muito fraca', () {
      expect(strengthOf(''), PasswordStrength.veryWeak);
    });

    test('curta é no máximo fraca mesmo com variedade', () {
      expect(strengthOf('A1@b'), isIn([
        PasswordStrength.veryWeak,
        PasswordStrength.weak,
      ]));
    });

    test('média para razoável', () {
      expect(strengthOf('Password1'), PasswordStrength.medium);
    });

    test('forte para longa e variada', () {
      expect(strengthOf(r'P@ssw0rd12345'), PasswordStrength.strong);
    });

    test('excelente para 16+ com todas as classes', () {
      expect(strengthOf(r'P@ssw0rd1234567!'), PasswordStrength.excellent);
    });

    test('sugere melhorias para senhas fracas', () {
      final result = evaluatePasswordStrength('abcdefg');
      expect(result.suggestions, isNotEmpty);
    });

    test('fração cresce com o nível', () {
      expect(PasswordStrength.veryWeak.fraction,
          lessThan(PasswordStrength.excellent.fraction));
    });
  });
}
