import 'dart:convert';
import 'dart:typed_data';

// Oculta o SecureRandom do pacote cryptography para não colidir com o nosso.
import 'package:cryptography/cryptography.dart' hide SecureRandom;

import 'aes_gcm_cipher_service.dart';
import 'argon2_key_derivation_service.dart';
import 'cipher_service.dart';
import 'crypto_failure.dart';
import 'kdf_params.dart';
import 'key_derivation_service.dart';
import 'secure_random.dart';
import 'unlocked_vault_keys.dart';
import 'vault_key_material.dart';

/// Resultado da criação de um cofre: o material persistível + as chaves vivas.
class VaultCreation {
  const VaultCreation({required this.material, required this.keys});

  /// Persistir (não sensível).
  final VaultKeyMaterial material;

  /// Manter só em memória; chamar `keys.dispose()` no lock.
  final UnlockedVaultKeys keys;
}

/// Orquestra toda a hierarquia de chaves do NoxPass.
///
/// ```
/// Senha Mestra --Argon2id--> Master Key (KEK, nunca persistida)
///                                 │ AES-256-GCM
///                                 ▼
///                          [ DEK embrulhada ]  (persistida em claro, opaca)
///                                 │ (desembrulhada só em memória)
///                                 ▼
///                                DEK  --HKDF--> databaseKey (SQLCipher)
///                                        └----> fieldKey   (envelope por campo)
/// ```
///
/// Trocar a senha mestra re-embrulha apenas a DEK (32 bytes) — o cofre inteiro
/// não precisa ser recifrado.
class VaultKeyService {
  VaultKeyService({
    KeyDerivationService? keyDerivation,
    CipherService? cipher,
    SecureRandom? secureRandom,
  })  : _kdf = keyDerivation ?? const Argon2KeyDerivationService(),
        _cipher = cipher ?? AesGcmCipherService(),
        _random = secureRandom ?? const SecureRandom();

  final KeyDerivationService _kdf;
  final CipherService _cipher;
  final SecureRandom _random;

  static const int _saltLength = 16;
  static const int _dekLength = 32;

  // Rótulos de separação de domínio para o HKDF (versionados).
  static const String _dbInfo = 'noxpass:sqlcipher-db:v1';
  static const String _fieldInfo = 'noxpass:field-encryption:v1';
  static final List<int> _hkdfSalt = utf8.encode('noxpass:hkdf-salt:v1');

  /// Cria um cofre novo a partir da [masterPassword].
  Future<VaultCreation> createVault(
    String masterPassword, {
    KdfParams params = KdfParams.owaspDefault,
  }) async {
    final salt = _random.nextBytes(_saltLength);
    final masterKey = await _kdf.deriveKey(
      password: masterPassword,
      salt: salt,
      params: params,
    );
    try {
      final dekBytes = _random.nextBytes(_dekLength);
      final wrappedDek = await _cipher.encrypt(plaintext: dekBytes, key: masterKey);
      final material = VaultKeyMaterial(
        kdfSalt: salt,
        kdfParams: params,
        wrappedDek: wrappedDek,
      );
      final keys = await _expandDek(dekBytes);
      return VaultCreation(material: material, keys: keys);
    } finally {
      masterKey.destroy();
    }
  }

  /// Destrava um cofre existente. Lança [AuthenticationFailure] se a senha
  /// estiver incorreta (a tag do AES-GCM da DEK não confere).
  Future<UnlockedVaultKeys> unlock(
    String masterPassword,
    VaultKeyMaterial material,
  ) async {
    final masterKey = await _kdf.deriveKey(
      password: masterPassword,
      salt: material.kdfSalt,
      params: material.kdfParams,
    );
    try {
      final dekBytes = await _cipher.decrypt(
        data: material.wrappedDek,
        key: masterKey,
      );
      return _expandDek(dekBytes);
    } finally {
      masterKey.destroy();
    }
  }

  /// Re-embrulha a DEK sob uma nova senha mestra, sem tocar nos dados do cofre.
  ///
  /// Gera novo salt (e pode adotar novos [newParams]). Valida a senha atual
  /// antes de trocar.
  Future<VaultKeyMaterial> changeMasterPassword({
    required String currentPassword,
    required String newPassword,
    required VaultKeyMaterial material,
    KdfParams? newParams,
  }) async {
    final currentMasterKey = await _kdf.deriveKey(
      password: currentPassword,
      salt: material.kdfSalt,
      params: material.kdfParams,
    );
    late final Uint8List dekBytes;
    try {
      dekBytes = await _cipher.decrypt(
        data: material.wrappedDek,
        key: currentMasterKey,
      );
    } finally {
      currentMasterKey.destroy();
    }

    final params = newParams ?? material.kdfParams;
    final newSalt = _random.nextBytes(_saltLength);
    final newMasterKey = await _kdf.deriveKey(
      password: newPassword,
      salt: newSalt,
      params: params,
    );
    try {
      final rewrapped = await _cipher.encrypt(plaintext: dekBytes, key: newMasterKey);
      return VaultKeyMaterial(
        kdfSalt: newSalt,
        kdfParams: params,
        wrappedDek: rewrapped,
      );
    } finally {
      newMasterKey.destroy();
    }
  }

  /// Embrulha uma DEK **existente** sob um novo segredo (ex.: PIN/biometria),
  /// produzindo um material que [unlock] consegue abrir. Reaproveita a mesma
  /// DEK do cofre — as chaves resultantes são idênticas às do desbloqueio
  /// pela senha mestra.
  Future<VaultKeyMaterial> wrapDek(
    Uint8List dekBytes,
    String secret, {
    KdfParams params = KdfParams.owaspDefault,
  }) async {
    if (dekBytes.length != _dekLength) {
      throw const InvalidCryptoInputFailure('DEK com tamanho inesperado.');
    }
    final salt = _random.nextBytes(_saltLength);
    final key = await _kdf.deriveKey(
      password: secret,
      salt: salt,
      params: params,
    );
    try {
      final wrapped = await _cipher.encrypt(plaintext: dekBytes, key: key);
      return VaultKeyMaterial(
        kdfSalt: salt,
        kdfParams: params,
        wrappedDek: wrapped,
      );
    } finally {
      key.destroy();
    }
  }

  /// Deriva as subchaves de propósito específico a partir da DEK via HKDF.
  Future<UnlockedVaultKeys> _expandDek(Uint8List dekBytes) async {
    if (dekBytes.length != _dekLength) {
      throw const InvalidCryptoInputFailure('DEK com tamanho inesperado.');
    }
    final databaseKey = await _deriveSubkey(dekBytes, _dbInfo);
    final fieldKey = await _deriveSubkey(dekBytes, _fieldInfo);
    return UnlockedVaultKeys(
      dataKey: SecretKey(dekBytes),
      databaseKey: databaseKey,
      fieldKey: fieldKey,
    );
  }

  Future<SecretKey> _deriveSubkey(Uint8List dekBytes, String info) {
    final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
    return hkdf.deriveKey(
      secretKey: SecretKey(dekBytes),
      nonce: _hkdfSalt,
      info: utf8.encode(info),
    );
  }
}
