import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/crypto/vault_key_material.dart';

/// Guarda o material de credencial do PIN (a DEK embrulhada sob a chave do PIN).
///
/// É opaco sem o PIN; ainda assim fica no armazenamento seguro do SO.
abstract interface class PinCredentialStore {
  Future<bool> exists();
  Future<VaultKeyMaterial?> read();
  Future<void> write(VaultKeyMaterial material);
  Future<void> clear();
}

class SecurePinCredentialStore implements PinCredentialStore {
  const SecurePinCredentialStore(this._storage);

  final FlutterSecureStorage _storage;
  static const String _key = 'noxpass.pin.material.v1';

  @override
  Future<bool> exists() => _storage.containsKey(key: _key);

  @override
  Future<VaultKeyMaterial?> read() async {
    final raw = await _storage.read(key: _key);
    if (raw == null) return null;
    return VaultKeyMaterial.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> write(VaultKeyMaterial material) =>
      _storage.write(key: _key, value: jsonEncode(material.toJson()));

  @override
  Future<void> clear() => _storage.delete(key: _key);
}
