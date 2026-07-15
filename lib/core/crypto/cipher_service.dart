import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import 'encrypted_data.dart';

/// Cifra/decifra dados simétricos autenticados (AEAD).
///
/// Contrato: cada [encrypt] gera um nonce novo e aleatório internamente —
/// o chamador nunca fornece nonce, o que torna a reutilização impossível por
/// construção. A integridade é sempre verificada em [decrypt].
abstract interface class CipherService {
  /// Cifra [plaintext] com [key], retornando nonce + tag + ciphertext.
  Future<EncryptedData> encrypt({
    required Uint8List plaintext,
    required SecretKey key,
  });

  /// Decifra e autentica [data] com [key].
  ///
  /// Lança [AuthenticationFailure] se a tag não conferir (chave errada ou
  /// dado adulterado/corrompido).
  Future<Uint8List> decrypt({
    required EncryptedData data,
    required SecretKey key,
  });
}
