import 'dart:convert';
import 'dart:typed_data';

import 'encrypted_data.dart';
import 'kdf_params.dart';

/// Dados **não sensíveis** necessários para desbloquear o cofre.
///
/// Podem ser persistidos em claro (não revelam segredos): guardam o salt da
/// KDF, os parâmetros de custo e a DEK já cifrada (embrulhada) sob a Master
/// Key. Sem a senha mestra, a DEK aqui é indecifrável.
class VaultKeyMaterial {
  const VaultKeyMaterial({
    required this.kdfSalt,
    required this.kdfParams,
    required this.wrappedDek,
  });

  factory VaultKeyMaterial.fromJson(Map<String, dynamic> json) {
    return VaultKeyMaterial(
      kdfSalt: base64Decode(json['salt'] as String),
      kdfParams: KdfParams.fromJson(json['kdf'] as Map<String, dynamic>),
      wrappedDek: EncryptedData.fromBase64(json['dek'] as String),
    );
  }

  /// Salt aleatório do Argon2id (único por cofre).
  final Uint8List kdfSalt;

  /// Parâmetros de custo usados para derivar a Master Key.
  final KdfParams kdfParams;

  /// Data Encryption Key cifrada sob a Master Key (AES-256-GCM).
  final EncryptedData wrappedDek;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'salt': base64Encode(kdfSalt),
        'kdf': kdfParams.toJson(),
        'dek': wrappedDek.toBase64(),
      };
}
