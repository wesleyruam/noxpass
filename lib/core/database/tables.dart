import 'package:drift/drift.dart';

/// Categorias do cofre (nativas e personalizadas).
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 100)();

  /// Identificador do ícone (não é sensível).
  TextColumn get icon => text().nullable()();
  IntColumn get colorValue => integer().nullable()();
  BoolColumn get isBuiltIn => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Item do cofre (senha, cartão, Wi-Fi, chave SSH, nota segura, etc.).
///
/// As colunas aqui são **metadados** (protegidos em repouso pelo SQLCipher,
/// mas legíveis para listagem/busca). Todo o conteúdo **sensível** vive em
/// [encryptedPayload], cifrado individualmente com AES-256-GCM (envelope por
/// segredo) usando a `fieldKey` — defesa em profundidade sobre o SQLCipher.
@DataClassName('SecretRow')
class Secrets extends Table {
  TextColumn get id => text()();

  /// Nome do [SecretType] (enum serializado).
  TextColumn get type => text()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get categoryId =>
      text().nullable().references(Categories, #id)();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  TextColumn get iconRef => text().nullable()();

  /// `EncryptedData.toBytes()` do payload sensível (JSON cifrado).
  BlobColumn get encryptedPayload => blob()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  /// Marcação de lixeira (soft delete). Null = ativo. Preenchido = na lixeira.
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Etiquetas livres.
class Tags extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 60).unique()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Relação N:N entre segredos e etiquetas.
class SecretTags extends Table {
  TextColumn get secretId =>
      text().references(Secrets, #id, onDelete: KeyAction.cascade)();
  TextColumn get tagId =>
      text().references(Tags, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {secretId, tagId};
}

/// Histórico: cada alteração de um segredo gera um snapshot imutável.
///
/// Guarda o payload sensível já cifrado no momento da versão, permitindo
/// restauração futura sem jamais expor texto puro.
class SecretVersions extends Table {
  TextColumn get id => text()();
  TextColumn get secretId =>
      text().references(Secrets, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text()();
  BlobColumn get encryptedPayload => blob()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
