import 'package:flutter_test/flutter_test.dart';
import 'package:noxpass/core/database/sqlcipher_key.dart';

void main() {
  group('formatRawKeyPragma', () {
    test('gera PRAGMA com chave raw em 64 hex (sem KDF do SQLCipher)', () {
      final key = List<int>.filled(32, 0)
        ..[0] = 0x0A
        ..[31] = 0xFF;
      final pragma = formatRawKeyPragma(key);

      expect(pragma, startsWith('PRAGMA key = "x\''));
      expect(pragma, endsWith('\'";'));
      // 32 bytes -> 64 caracteres hex.
      final hex = RegExp(r"x'([0-9a-f]+)'").firstMatch(pragma)!.group(1)!;
      expect(hex, hasLength(64));
      expect(hex, startsWith('0a'));
      expect(hex, endsWith('ff'));
    });

    test('rejeita chave que não tenha 32 bytes', () {
      expect(() => formatRawKeyPragma(List<int>.filled(16, 0)), throwsArgumentError);
      expect(() => formatRawKeyPragma(List<int>.filled(33, 0)), throwsArgumentError);
    });
  });
}
