import 'package:flutter_test/flutter_test.dart';
import 'package:noxpass/core/crypto/secure_random.dart';

void main() {
  const random = SecureRandom();

  group('SecureRandom', () {
    test('retorna a quantidade de bytes pedida', () {
      expect(random.nextBytes(16), hasLength(16));
      expect(random.nextBytes(32), hasLength(32));
    });

    test('gera valores diferentes a cada chamada (não determinístico)', () {
      final a = random.nextBytes(32);
      final b = random.nextBytes(32);
      expect(a, isNot(equals(b)));
    });

    test('rejeita tamanho não positivo', () {
      expect(() => random.nextBytes(0), throwsArgumentError);
      expect(() => random.nextBytes(-1), throwsArgumentError);
    });
  });
}
