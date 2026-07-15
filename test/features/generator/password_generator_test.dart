import 'package:flutter_test/flutter_test.dart';
import 'package:noxpass/features/generator/domain/password_generator.dart';

void main() {
  const generator = PasswordGenerator();

  group('PasswordGenerator', () {
    test('respeita o comprimento pedido', () {
      final pass = generator.generate(const PasswordGeneratorOptions(length: 24));
      expect(pass, hasLength(24));
    });

    test('usa apenas as classes selecionadas', () {
      final pass = generator.generate(
        const PasswordGeneratorOptions(
          length: 200,
          useLower: false,
          useUpper: false,
          useSymbols: false,
        ),
      );
      expect(RegExp(r'^[0-9]+$').hasMatch(pass), isTrue);
    });

    test('duas gerações diferem (aleatoriedade)', () {
      final a = generator.generate(const PasswordGeneratorOptions());
      final b = generator.generate(const PasswordGeneratorOptions());
      expect(a, isNot(equals(b)));
    });

    test('exige ao menos uma classe de caracteres', () {
      expect(
        () => generator.generate(
          const PasswordGeneratorOptions(
            useLower: false,
            useUpper: false,
            useDigits: false,
            useSymbols: false,
          ),
        ),
        throwsArgumentError,
      );
    });
  });
}
