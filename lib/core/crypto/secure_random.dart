import 'dart:math';
import 'dart:typed_data';

/// Fonte central de aleatoriedade criptograficamente segura do NoxPass.
///
/// Todo salt e nonce do aplicativo deve ser gerado por aqui — nunca por
/// [Random] comum. Usa [Random.secure], que delega para a CSPRNG do sistema
/// operacional (getrandom/BCryptGenRandom/SecRandomCopyBytes).
class SecureRandom {
  const SecureRandom();

  /// Retorna [length] bytes aleatórios seguros.
  Uint8List nextBytes(int length) {
    if (length <= 0) {
      throw ArgumentError.value(length, 'length', 'deve ser positivo');
    }
    final random = Random.secure();
    final bytes = Uint8List(length);
    for (var i = 0; i < length; i++) {
      bytes[i] = random.nextInt(256);
    }
    return bytes;
  }
}
