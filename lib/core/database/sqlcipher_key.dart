/// Formata a chave do banco (32 bytes) no PRAGMA de **chave raw** do SQLCipher.
///
/// O formato `x'<64 hex>'` faz o SQLCipher usar os bytes diretamente como
/// chave de 256 bits, **pulando a KDF interna (PBKDF2)** — o que é correto
/// aqui, pois a chave já vem endurecida via Argon2id + HKDF (a `databaseKey`).
///
/// Dart puro (sem dependências de plataforma) para ser testável no host.
String formatRawKeyPragma(List<int> databaseKey) {
  if (databaseKey.length != 32) {
    throw ArgumentError.value(
      databaseKey.length,
      'databaseKey.length',
      'A databaseKey deve ter exatamente 32 bytes (256 bits).',
    );
  }
  final hex = StringBuffer();
  for (final byte in databaseKey) {
    hex.write((byte & 0xFF).toRadixString(16).padLeft(2, '0'));
  }
  return "PRAGMA key = \"x'$hex'\";";
}
