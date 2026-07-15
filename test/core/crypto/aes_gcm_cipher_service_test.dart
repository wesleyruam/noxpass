import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noxpass/core/crypto/aes_gcm_cipher_service.dart';
import 'package:noxpass/core/crypto/crypto_failure.dart';
import 'package:noxpass/core/crypto/encrypted_data.dart';

void main() {
  late AesGcmCipherService cipher;
  final key = SecretKey(List<int>.generate(32, (i) => i));
  final otherKey = SecretKey(List<int>.generate(32, (i) => 255 - i));

  setUp(() => cipher = AesGcmCipherService());

  Uint8List plaintext(String s) => Uint8List.fromList(utf8.encode(s));

  group('AesGcmCipherService', () {
    test('decrypt(encrypt(x)) devolve o texto original', () async {
      final input = plaintext('senha-super-secreta-🔐');
      final encrypted = await cipher.encrypt(plaintext: input, key: key);
      final decrypted = await cipher.decrypt(data: encrypted, key: key);

      expect(decrypted, input);
    });

    test('gera nonce novo a cada cifragem (sem reuso)', () async {
      final input = plaintext('mesmo texto');
      final a = await cipher.encrypt(plaintext: input, key: key);
      final b = await cipher.encrypt(plaintext: input, key: key);

      expect(a.nonce, isNot(equals(b.nonce)));
      expect(a.cipherText, isNot(equals(b.cipherText)));
    });

    test('chave errada falha a autenticação', () async {
      final encrypted = await cipher.encrypt(plaintext: plaintext('x'), key: key);
      expect(
        () => cipher.decrypt(data: encrypted, key: otherKey),
        throwsA(isA<AuthenticationFailure>()),
      );
    });

    test('ciphertext adulterado falha a autenticação', () async {
      final encrypted = await cipher.encrypt(plaintext: plaintext('integridade'), key: key);
      final tampered = EncryptedData(
        nonce: encrypted.nonce,
        mac: encrypted.mac,
        cipherText: Uint8List.fromList(encrypted.cipherText)..[0] ^= 0xFF,
      );
      expect(
        () => cipher.decrypt(data: tampered, key: key),
        throwsA(isA<AuthenticationFailure>()),
      );
    });
  });
}
