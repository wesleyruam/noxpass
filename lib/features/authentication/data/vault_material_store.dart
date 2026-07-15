import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/crypto/vault_key_material.dart';

/// Persiste o [VaultKeyMaterial] (salt, params e DEK embrulhada).
///
/// O conteúdo é opaco sem a senha mestra, mas é guardado no armazenamento
/// seguro do SO (Keystore/Keychain) por precaução — defesa em profundidade.
abstract interface class VaultMaterialStore {
  Future<bool> exists();
  Future<VaultKeyMaterial?> read();
  Future<void> write(VaultKeyMaterial material);

  /// Remove o material (usado ao "esquecer"/reinicializar o cofre).
  Future<void> clear();
}

/// Implementação sobre [FlutterSecureStorage].
class SecureVaultMaterialStore implements VaultMaterialStore {
  SecureVaultMaterialStore(this._storage);

  final FlutterSecureStorage _storage;

  static const String _key = 'noxpass.vault.material.v1';

  @override
  Future<bool> exists() async => _storage.containsKey(key: _key);

  @override
  Future<VaultKeyMaterial?> read() async {
    final raw = await _storage.read(key: _key);
    if (raw == null) return null;
    return VaultKeyMaterial.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> write(VaultKeyMaterial material) async {
    await _storage.write(key: _key, value: jsonEncode(material.toJson()));
  }

  @override
  Future<void> clear() async => _storage.delete(key: _key);
}
