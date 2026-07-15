import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import 'kdf_params.dart';

/// Deriva chaves a partir da senha mestra do usuário.
///
/// A senha mestra **nunca** é usada diretamente como chave — ela sempre passa
/// por uma KDF memory-hard (Argon2id) para produzir a Master Key.
abstract interface class KeyDerivationService {
  /// Deriva uma chave a partir de [password] e [salt] com os custos [params].
  ///
  /// [password] é tratada em UTF-8. O [salt] deve ser aleatório e único por
  /// cofre. A chave resultante existe apenas em memória e deve ser destruída
  /// (`SecretKey.destroy()`) assim que não for mais necessária.
  Future<SecretKey> deriveKey({
    required String password,
    required Uint8List salt,
    required KdfParams params,
  });
}
