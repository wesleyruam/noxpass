import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import 'cipher_service.dart';
import 'crypto_failure.dart';
import 'encrypted_data.dart';

/// Implementação de [CipherService] com AES-256-GCM.
///
/// O nonce de 96 bits é gerado por [AesGcm.newNonce] (CSPRNG) a cada
/// operação de cifragem, garantindo unicidade e impossibilitando reuso.
class AesGcmCipherService implements CipherService {
  AesGcmCipherService() : _algorithm = AesGcm.with256bits();

  final AesGcm _algorithm;

  @override
  Future<EncryptedData> encrypt({
    required Uint8List plaintext,
    required SecretKey key,
  }) async {
    final secretBox = await _algorithm.encrypt(
      plaintext,
      secretKey: key,
      nonce: _algorithm.newNonce(),
    );
    return EncryptedData(
      nonce: Uint8List.fromList(secretBox.nonce),
      mac: Uint8List.fromList(secretBox.mac.bytes),
      cipherText: Uint8List.fromList(secretBox.cipherText),
    );
  }

  @override
  Future<Uint8List> decrypt({
    required EncryptedData data,
    required SecretKey key,
  }) async {
    final secretBox = SecretBox(
      data.cipherText,
      nonce: data.nonce,
      mac: Mac(data.mac),
    );
    try {
      final clear = await _algorithm.decrypt(secretBox, secretKey: key);
      return Uint8List.fromList(clear);
    } on SecretBoxAuthenticationError {
      // Nunca vaza qual foi a causa concreta (senha vs. corrupção).
      throw const AuthenticationFailure();
    }
  }
}
