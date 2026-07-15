import 'dart:convert';
import 'dart:typed_data';

/// Conteúdo **sensível** de um segredo: um mapa de campos nome→valor.
///
/// É o único dado que passa pelo envelope AES-256-GCM (via `fieldKey`). O
/// formato de mapa acomoda qualquer [SecretType] e os campos personalizados
/// sem alterar o schema — a granularidade por campo mora aqui dentro.
class SecretPayload {
  const SecretPayload(this.fields);

  factory SecretPayload.fromJson(Map<String, dynamic> json) {
    return SecretPayload(
      json.map((key, value) => MapEntry(key, value as String)),
    );
  }

  /// Desserializa a partir dos bytes UTF-8 do JSON decifrado.
  factory SecretPayload.fromBytes(List<int> bytes) {
    final decoded = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    return SecretPayload.fromJson(decoded);
  }

  final Map<String, String> fields;

  static const SecretPayload empty = SecretPayload(<String, String>{});

  // Nomes de campo convencionais (para tipos comuns).
  static const String username = 'username';
  static const String password = 'password';
  static const String url = 'url';
  static const String notes = 'notes';

  /// Segredo TOTP (Base32 ou URI `otpauth://`) para gerar códigos 2FA.
  static const String totp = 'totp';

  String? operator [](String key) => fields[key];

  Map<String, dynamic> toJson() => Map<String, dynamic>.from(fields);

  /// Serializa para os bytes que serão cifrados.
  Uint8List toBytes() => Uint8List.fromList(utf8.encode(jsonEncode(toJson())));
}
