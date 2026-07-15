import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import 'kdf_params.dart';
import 'key_derivation_service.dart';

/// Implementação de [KeyDerivationService] baseada em Argon2id (RFC 9106).
///
/// Usa a implementação do pacote `cryptography`. Em runtime móvel/desktop,
/// `cryptography_flutter` pode substituir por implementações nativas quando
/// disponíveis; em testes (Dart VM) roda a implementação pura em Dart.
class Argon2KeyDerivationService implements KeyDerivationService {
  const Argon2KeyDerivationService();

  @override
  Future<SecretKey> deriveKey({
    required String password,
    required Uint8List salt,
    required KdfParams params,
  }) async {
    final algorithm = Argon2id(
      parallelism: params.parallelism,
      memory: params.memoryBlocks,
      iterations: params.iterations,
      hashLength: params.hashLength,
    );

    // A senha vira bytes UTF-8 apenas pelo tempo da derivação.
    final passwordBytes = utf8.encode(password);
    final secret = SecretKey(passwordBytes);
    try {
      return await algorithm.deriveKey(secretKey: secret, nonce: salt);
    } finally {
      secret.destroy();
    }
  }
}
