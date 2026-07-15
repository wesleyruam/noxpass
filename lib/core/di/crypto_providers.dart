import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../crypto/crypto.dart';

/// Injeção de dependência da camada de criptografia.
///
/// Providers manuais (sem code-gen) por serem serviços simples e sem estado.
/// Trocar uma implementação (ex.: KDF nativa) é sobrescrever um provider.

final secureRandomProvider = Provider<SecureRandom>(
  (ref) => const SecureRandom(),
);

final keyDerivationServiceProvider = Provider<KeyDerivationService>(
  (ref) => const Argon2KeyDerivationService(),
);

final cipherServiceProvider = Provider<CipherService>(
  (ref) => AesGcmCipherService(),
);

final vaultKeyServiceProvider = Provider<VaultKeyService>(
  (ref) => VaultKeyService(
    keyDerivation: ref.watch(keyDerivationServiceProvider),
    cipher: ref.watch(cipherServiceProvider),
    secureRandom: ref.watch(secureRandomProvider),
  ),
);
