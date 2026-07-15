/// Tipos de segredo suportados pelo NoxPass (Secrets Manager).
///
/// O `name` de cada valor é o que se persiste na coluna `type`. Valores novos
/// podem ser adicionados ao fim sem migração de schema.
enum SecretType {
  password,
  appPassword,
  bankAccount,
  card,
  wifi,
  ssh,
  gpg,
  apiToken,
  license,
  certificate,
  recoveryCodes,
  privateKey,
  secureNote,
  identity,
  document,
  custom;

  /// Converte o nome persistido de volta ao enum, com fallback seguro para
  /// [SecretType.custom] (nunca lança em dado legado/desconhecido).
  static SecretType fromName(String name) {
    for (final type in values) {
      if (type.name == name) return type;
    }
    return SecretType.custom;
  }
}
