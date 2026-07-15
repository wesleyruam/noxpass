/// Camada de criptografia do NoxPass.
///
/// Ponto único de importação para o subsistema criptográfico. Regras de ouro:
///  - a senha mestra nunca é usada como chave (sempre via Argon2id);
///  - todo dado sensível é cifrado com AES-256-GCM (nonce aleatório único);
///  - chaves vivem em memória pelo menor tempo possível (chame `dispose`).
library;

export 'aes_gcm_cipher_service.dart';
export 'argon2_key_derivation_service.dart';
export 'cipher_service.dart';
export 'crypto_failure.dart';
export 'encrypted_data.dart';
export 'kdf_params.dart';
export 'key_derivation_service.dart';
export 'secure_random.dart';
export 'unlocked_vault_keys.dart';
export 'vault_key_material.dart';
export 'vault_key_service.dart';
