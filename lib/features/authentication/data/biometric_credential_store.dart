import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/crypto/vault_key_material.dart';

/// Credencial de desbloqueio por biometria.
///
/// Guarda um segredo aleatório de alta entropia e a DEK embrulhada sob ele.
/// A biometria é o "portão" (via local_auth); o segredo fica no armazenamento
/// seguro do SO. Conveniência — a senha mestra continua sendo a raiz forte.
class BiometricCredential {
  const BiometricCredential({required this.secret, required this.material});

  /// Segredo de alta entropia (base64) usado para derivar a chave que embrulha
  /// a DEK.
  final String secret;
  final VaultKeyMaterial material;

  Map<String, dynamic> toJson() =>
      {'secret': secret, 'material': material.toJson()};

  factory BiometricCredential.fromJson(Map<String, dynamic> json) =>
      BiometricCredential(
        secret: json['secret'] as String,
        material:
            VaultKeyMaterial.fromJson(json['material'] as Map<String, dynamic>),
      );
}

abstract interface class BiometricCredentialStore {
  Future<bool> exists();
  Future<BiometricCredential?> read();
  Future<void> write(BiometricCredential credential);
  Future<void> clear();
}

class SecureBiometricCredentialStore implements BiometricCredentialStore {
  const SecureBiometricCredentialStore(this._storage);

  final FlutterSecureStorage _storage;
  static const String _key = 'noxpass.biometric.credential.v1';

  @override
  Future<bool> exists() => _storage.containsKey(key: _key);

  @override
  Future<BiometricCredential?> read() async {
    final raw = await _storage.read(key: _key);
    if (raw == null) return null;
    return BiometricCredential.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }

  @override
  Future<void> write(BiometricCredential credential) =>
      _storage.write(key: _key, value: jsonEncode(credential.toJson()));

  @override
  Future<void> clear() => _storage.delete(key: _key);
}
