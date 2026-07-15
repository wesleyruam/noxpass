import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:noxpass/core/crypto/crypto_failure.dart';
import 'package:noxpass/core/crypto/encrypted_data.dart';

void main() {
  EncryptedData sample() => EncryptedData(
        nonce: Uint8List.fromList(List<int>.generate(12, (i) => i)),
        mac: Uint8List.fromList(List<int>.generate(16, (i) => 100 + i)),
        cipherText: Uint8List.fromList(<int>[1, 2, 3, 4, 5]),
      );

  group('EncryptedData', () {
    test('toBytes/fromBytes é um roundtrip fiel', () {
      final original = sample();
      final restored = EncryptedData.fromBytes(original.toBytes());

      expect(restored.nonce, original.nonce);
      expect(restored.mac, original.mac);
      expect(restored.cipherText, original.cipherText);
    });

    test('toBase64/fromBase64 é um roundtrip fiel', () {
      final original = sample();
      final restored = EncryptedData.fromBase64(original.toBase64());

      expect(restored.toBytes(), original.toBytes());
    });

    test('blob tem tamanho nonce + mac + ciphertext', () {
      expect(sample().toBytes(), hasLength(12 + 16 + 5));
    });

    test('rejeita blob menor que o cabeçalho mínimo', () {
      final tooShort = Uint8List(EncryptedData.nonceLength + EncryptedData.macLength - 1);
      expect(
        () => EncryptedData.fromBytes(tooShort),
        throwsA(isA<MalformedCiphertextFailure>()),
      );
    });

    test('aceita ciphertext vazio (nonce + mac exatos)', () {
      final minimal = Uint8List(EncryptedData.nonceLength + EncryptedData.macLength);
      final data = EncryptedData.fromBytes(minimal);
      expect(data.cipherText, isEmpty);
    });
  });
}
