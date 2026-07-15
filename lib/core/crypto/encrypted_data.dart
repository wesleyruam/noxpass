import 'dart:convert';
import 'dart:typed_data';

import 'crypto_failure.dart';

/// Resultado de uma operação AES-256-GCM: ciphertext + nonce + tag (MAC).
///
/// Serializa para um único blob autocontido no formato:
///
/// ```
/// [ nonce (12 bytes) | mac (16 bytes) | ciphertext (n bytes) ]
/// ```
///
/// Esse blob é o que fica no banco (envelope por campo) e o que compõe
/// backups/compartilhamentos. É seguro persistir: sem a chave, é opaco.
class EncryptedData {
  const EncryptedData({
    required this.nonce,
    required this.mac,
    required this.cipherText,
  });

  /// Reconstrói a partir do blob serializado por [toBytes].
  factory EncryptedData.fromBytes(Uint8List bytes) {
    if (bytes.length < nonceLength + macLength) {
      throw const MalformedCiphertextFailure(
        'Blob menor que o cabeçalho mínimo (nonce + mac).',
      );
    }
    return EncryptedData(
      nonce: Uint8List.sublistView(bytes, 0, nonceLength),
      mac: Uint8List.sublistView(bytes, nonceLength, nonceLength + macLength),
      cipherText: Uint8List.sublistView(bytes, nonceLength + macLength),
    );
  }

  factory EncryptedData.fromBase64(String source) =>
      EncryptedData.fromBytes(base64Decode(source));

  /// Tamanho do nonce do AES-GCM (96 bits), conforme recomendação do NIST.
  static const int nonceLength = 12;

  /// Tamanho da tag de autenticação do GCM (128 bits).
  static const int macLength = 16;

  final Uint8List nonce;
  final Uint8List mac;
  final Uint8List cipherText;

  /// Concatena tudo em um único blob (ver formato na doc da classe).
  Uint8List toBytes() {
    final out = Uint8List(nonce.length + mac.length + cipherText.length);
    out
      ..setAll(0, nonce)
      ..setAll(nonce.length, mac)
      ..setAll(nonce.length + mac.length, cipherText);
    return out;
  }

  String toBase64() => base64Encode(toBytes());
}
