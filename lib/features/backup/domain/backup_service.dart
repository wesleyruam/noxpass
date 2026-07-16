import 'dart:convert';
import 'dart:typed_data';

import '../../../core/crypto/aes_gcm_cipher_service.dart';
import '../../../core/crypto/argon2_key_derivation_service.dart';
import '../../../core/crypto/cipher_service.dart';
import '../../../core/crypto/encrypted_data.dart';
import '../../../core/crypto/kdf_params.dart';
import '../../../core/crypto/key_derivation_service.dart';
import '../../../core/crypto/secure_random.dart';
import '../../vault/domain/entities/secret.dart';
import '../../vault/domain/entities/secret_payload.dart';
import '../../vault/domain/entities/secret_type.dart';

/// Erro de formato/estrutura de um arquivo de backup.
class BackupFormatException implements Exception {
  const BackupFormatException(this.message);
  final String message;
  @override
  String toString() => 'BackupFormatException: $message';
}

/// Exporta/importa o cofre como um arquivo `.backup` criptografado.
///
/// Zero-Knowledge por design: os segredos são cifrados com AES-256-GCM sob uma
/// chave derivada por Argon2id de uma **senha de backup própria** — nunca a
/// senha mestra. Salt e parâmetros da KDF ficam em claro (não são sensíveis);
/// o conteúdo (`data`) é opaco sem a senha.
class BackupService {
  BackupService({
    KeyDerivationService? keyDerivation,
    CipherService? cipher,
    SecureRandom? secureRandom,
  }) : _kdf = keyDerivation ?? const Argon2KeyDerivationService(),
       _cipher = cipher ?? AesGcmCipherService(),
       _random = secureRandom ?? const SecureRandom();

  final KeyDerivationService _kdf;
  final CipherService _cipher;
  final SecureRandom _random;

  static const String _magic = 'noxpass.backup';
  static const int _formatVersion = 1;
  static const int _saltLength = 16;

  /// Gera os bytes de um arquivo de backup criptografado.
  Future<Uint8List> export(
    List<Secret> secrets,
    String backupPassword, {
    KdfParams params = KdfParams.owaspDefault,
  }) async {
    final salt = _random.nextBytes(_saltLength);
    final key = await _kdf.deriveKey(
      password: backupPassword,
      salt: salt,
      params: params,
    );
    try {
      final payload = jsonEncode({
        'exportedAt': DateTime.now().toUtc().toIso8601String(),
        'secrets': secrets.map(_secretToJson).toList(),
      });
      final encrypted = await _cipher.encrypt(
        plaintext: Uint8List.fromList(utf8.encode(payload)),
        key: key,
      );
      final envelope = jsonEncode({
        'format': _magic,
        'version': _formatVersion,
        'kdf': params.toJson(),
        'salt': base64Encode(salt),
        'data': encrypted.toBase64(),
      });
      return Uint8List.fromList(utf8.encode(envelope));
    } finally {
      key.destroy();
    }
  }

  /// Lê um backup e devolve rascunhos prontos para recriação no cofre.
  ///
  /// Lança [BackupFormatException] se o arquivo for inválido e
  /// [AuthenticationFailure] (via cipher) se a senha estiver incorreta.
  Future<List<SecretDraft>> import(
    Uint8List backupBytes,
    String backupPassword,
  ) async {
    final Map<String, dynamic> envelope;
    try {
      envelope = jsonDecode(utf8.decode(backupBytes)) as Map<String, dynamic>;
    } catch (_) {
      throw const BackupFormatException('Arquivo não é um backup válido.');
    }
    if (envelope['format'] != _magic) {
      throw const BackupFormatException('Formato de backup desconhecido.');
    }

    final params = KdfParams.fromJson(envelope['kdf'] as Map<String, dynamic>);
    final salt = base64Decode(envelope['salt'] as String);
    final data = EncryptedData.fromBase64(envelope['data'] as String);

    final key = await _kdf.deriveKey(
      password: backupPassword,
      salt: salt,
      params: params,
    );
    try {
      final clear = await _cipher.decrypt(data: data, key: key);
      final payload = jsonDecode(utf8.decode(clear)) as Map<String, dynamic>;
      final list = (payload['secrets'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      return list.map(_secretFromJson).toList();
    } finally {
      key.destroy();
    }
  }

  Map<String, dynamic> _secretToJson(Secret secret) => {
    'type': secret.type.name,
    'title': secret.title,
    'categoryId': secret.categoryId,
    'isFavorite': secret.isFavorite,
    'iconRef': secret.iconRef,
    'tags': secret.tags,
    'payload': secret.payload.toJson(),
  };

  SecretDraft _secretFromJson(Map<String, dynamic> json) => SecretDraft(
    type: SecretType.fromName(json['type'] as String),
    title: json['title'] as String,
    categoryId: json['categoryId'] as String?,
    isFavorite: (json['isFavorite'] as bool?) ?? false,
    iconRef: json['iconRef'] as String?,
    tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? const [],
    payload: SecretPayload.fromJson((json['payload'] as Map<String, dynamic>)),
  );
}
