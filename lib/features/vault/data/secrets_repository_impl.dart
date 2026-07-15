// Parâmetros nomeados não podem ser privados, então os campos privados são
// atribuídos manualmente (initializing formals não se aplicam a named args).
// ignore_for_file: prefer_initializing_formals

import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/crypto/cipher_service.dart';
import '../../../core/crypto/encrypted_data.dart';
import '../../../core/database/app_database.dart';
// Prefixo para não colidir com a data class gerada `Category` (linha da
// tabela) — assim conseguimos nomear ambas ao mapear.
import '../domain/entities/category.dart' as domain;
import '../domain/entities/secret.dart';
import '../domain/entities/secret_payload.dart';
import '../domain/entities/secret_type.dart';
import '../domain/repositories/secrets_repository.dart';

/// Implementação de [SecretsRepository] sobre Drift.
///
/// Esta classe é a **fronteira de cifragem**: recebe/entrega entidades com
/// payload em texto puro, mas só grava/lê blobs AES-256-GCM (via `fieldKey`).
/// Nada sensível cruza para o banco sem passar pelo envelope.
class SecretsRepositoryImpl implements SecretsRepository {
  SecretsRepositoryImpl({
    required AppDatabase database,
    required CipherService cipher,
    required SecretKey fieldKey,
    Uuid uuid = const Uuid(),
    DateTime Function() clock = DateTime.now,
  })  : _db = database,
        _cipher = cipher,
        _fieldKey = fieldKey,
        _uuid = uuid,
        _now = clock;

  final AppDatabase _db;
  final CipherService _cipher;
  final SecretKey _fieldKey;
  final Uuid _uuid;
  final DateTime Function() _now;

  static const Duration defaultTrashRetention = Duration(days: 30);

  // --- Escrita -------------------------------------------------------------

  @override
  Future<Secret> create(SecretDraft draft) async {
    final id = _uuid.v4();
    final now = _now();
    final blob = await _encrypt(draft.payload);

    await _db.transaction(() async {
      await _db.into(_db.secrets).insert(
            SecretsCompanion.insert(
              id: id,
              type: draft.type.name,
              title: draft.title,
              encryptedPayload: blob,
              createdAt: now,
              updatedAt: now,
              categoryId: Value(draft.categoryId),
              isFavorite: Value(draft.isFavorite),
              iconRef: Value(draft.iconRef),
            ),
          );
      await _attachTags(id, draft.tags);
    });

    return (await getById(id))!;
  }

  @override
  Future<Secret> update(String id, SecretDraft draft) async {
    final blob = await _encrypt(draft.payload);
    final now = _now();

    await _db.transaction(() async {
      final current = await (_db.select(_db.secrets)
            ..where((t) => t.id.equals(id)))
          .getSingleOrNull();
      if (current == null) {
        throw StateError('Segredo $id não existe.');
      }

      // Snapshot imutável da versão anterior (histórico).
      await _db.into(_db.secretVersions).insert(
            SecretVersionsCompanion.insert(
              id: _uuid.v4(),
              secretId: id,
              title: current.title,
              encryptedPayload: current.encryptedPayload,
              createdAt: now,
            ),
          );

      await (_db.update(_db.secrets)..where((t) => t.id.equals(id))).write(
        SecretsCompanion(
          type: Value(draft.type.name),
          title: Value(draft.title),
          categoryId: Value(draft.categoryId),
          isFavorite: Value(draft.isFavorite),
          iconRef: Value(draft.iconRef),
          encryptedPayload: Value(blob),
          updatedAt: Value(now),
        ),
      );

      await (_db.delete(_db.secretTags)..where((t) => t.secretId.equals(id)))
          .go();
      await _attachTags(id, draft.tags);
    });

    return (await getById(id))!;
  }

  @override
  Future<void> setFavorite(String id, {required bool value}) async {
    await (_db.update(_db.secrets)..where((t) => t.id.equals(id)))
        .write(SecretsCompanion(isFavorite: Value(value), updatedAt: Value(_now())));
  }

  @override
  Future<void> moveToTrash(String id) async {
    await (_db.update(_db.secrets)..where((t) => t.id.equals(id)))
        .write(SecretsCompanion(deletedAt: Value(_now())));
  }

  @override
  Future<void> restore(String id) async {
    await (_db.update(_db.secrets)..where((t) => t.id.equals(id)))
        .write(const SecretsCompanion(deletedAt: Value(null)));
  }

  @override
  Future<void> deletePermanently(String id) async {
    await (_db.delete(_db.secrets)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<int> purgeExpiredTrash({
    Duration retention = defaultTrashRetention,
  }) async {
    final cutoff = _now().subtract(retention);
    return (_db.delete(_db.secrets)
          ..where((t) =>
              t.deletedAt.isNotNull() & t.deletedAt.isSmallerThanValue(cutoff)))
        .go();
  }

  // --- Leitura -------------------------------------------------------------

  @override
  Future<Secret?> getById(String id) async {
    final row = await (_db.select(_db.secrets)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _toEntity(row);
  }

  @override
  Future<List<Secret>> getActive({String? query}) async {
    final select = _db.select(_db.secrets)
      ..where((t) => t.deletedAt.isNull());
    final trimmed = query?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      select.where((t) => t.title.like('%$trimmed%'));
    }
    select.orderBy([(t) => OrderingTerm.desc(t.updatedAt)]);
    return _mapRows(await select.get());
  }

  @override
  Stream<List<Secret>> watchActive() {
    final select = _db.select(_db.secrets)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]);
    return select.watch().asyncMap(_mapRows);
  }

  @override
  Future<List<Secret>> getFavorites() async {
    final select = _db.select(_db.secrets)
      ..where((t) => t.deletedAt.isNull() & t.isFavorite.equals(true))
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]);
    return _mapRows(await select.get());
  }

  @override
  Future<List<Secret>> getTrash() async {
    final select = _db.select(_db.secrets)
      ..where((t) => t.deletedAt.isNotNull())
      ..orderBy([(t) => OrderingTerm.desc(t.deletedAt)]);
    return _mapRows(await select.get());
  }

  @override
  Future<List<SecretVersionSnapshot>> getVersions(String secretId) async {
    final select = _db.select(_db.secretVersions)
      ..where((t) => t.secretId.equals(secretId))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    final rows = await select.get();
    return Future.wait(rows.map((row) async {
      return SecretVersionSnapshot(
        id: row.id,
        secretId: row.secretId,
        title: row.title,
        payload: await _decrypt(row.encryptedPayload),
        createdAt: row.createdAt,
      );
    }));
  }

  @override
  Future<void> restoreVersion(String secretId, String versionId) async {
    final now = _now();
    await _db.transaction(() async {
      final version = await (_db.select(_db.secretVersions)
            ..where((t) => t.id.equals(versionId) & t.secretId.equals(secretId)))
          .getSingleOrNull();
      if (version == null) {
        throw StateError('Versão $versionId não existe.');
      }
      final current = await (_db.select(_db.secrets)
            ..where((t) => t.id.equals(secretId)))
          .getSingleOrNull();
      if (current == null) {
        throw StateError('Segredo $secretId não existe.');
      }

      // Preserva a versão atual antes de sobrescrever.
      await _db.into(_db.secretVersions).insert(
            SecretVersionsCompanion.insert(
              id: _uuid.v4(),
              secretId: secretId,
              title: current.title,
              encryptedPayload: current.encryptedPayload,
              createdAt: now,
            ),
          );

      // Reaproveita o payload já cifrado da versão (mesma fieldKey).
      await (_db.update(_db.secrets)..where((t) => t.id.equals(secretId))).write(
        SecretsCompanion(
          title: Value(version.title),
          encryptedPayload: Value(version.encryptedPayload),
          updatedAt: Value(now),
        ),
      );
    });
  }

  // --- Categorias ----------------------------------------------------------

  @override
  Stream<List<domain.Category>> watchCategories() {
    final query = _db.select(_db.categories)
      ..orderBy([
        (t) => OrderingTerm(expression: t.sortOrder),
        (t) => OrderingTerm(expression: t.name),
      ]);
    return query.watch().map((rows) => rows.map(_toCategory).toList());
  }

  @override
  Future<domain.Category> createCategory(String name, {String? icon}) async {
    final now = _now();
    final id = _uuid.v4();
    await _db.into(_db.categories).insert(
          CategoriesCompanion.insert(
            id: id,
            name: name.trim(),
            icon: Value(icon),
            isBuiltIn: const Value(false),
            // Após as nativas (0..N); múltiplas custom desempatam pelo nome.
            sortOrder: const Value(1000),
            createdAt: now,
            updatedAt: now,
          ),
        );
    final row = await (_db.select(_db.categories)..where((t) => t.id.equals(id)))
        .getSingle();
    return _toCategory(row);
  }

  @override
  Future<void> renameCategory(String id, String name) async {
    await (_db.update(_db.categories)..where((t) => t.id.equals(id))).write(
      CategoriesCompanion(name: Value(name.trim()), updatedAt: Value(_now())),
    );
  }

  @override
  Future<void> deleteCategory(String id) async {
    await _db.transaction(() async {
      // Desvincula os segredos antes de remover (a FK é nullable).
      await (_db.update(_db.secrets)..where((t) => t.categoryId.equals(id)))
          .write(const SecretsCompanion(categoryId: Value(null)));
      await (_db.delete(_db.categories)..where((t) => t.id.equals(id))).go();
    });
  }

  domain.Category _toCategory(Category row) => domain.Category(
        id: row.id,
        name: row.name,
        icon: row.icon,
        colorValue: row.colorValue,
        isBuiltIn: row.isBuiltIn,
        sortOrder: row.sortOrder,
      );

  // --- Internos ------------------------------------------------------------

  Future<List<Secret>> _mapRows(List<SecretRow> rows) =>
      Future.wait(rows.map(_toEntity));

  Future<Secret> _toEntity(SecretRow row) async {
    return Secret(
      id: row.id,
      type: SecretType.fromName(row.type),
      title: row.title,
      payload: await _decrypt(row.encryptedPayload),
      categoryId: row.categoryId,
      isFavorite: row.isFavorite,
      iconRef: row.iconRef,
      tags: await _tagsFor(row.id),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      deletedAt: row.deletedAt,
    );
  }

  Future<Uint8List> _encrypt(SecretPayload payload) async {
    final encrypted = await _cipher.encrypt(
      plaintext: payload.toBytes(),
      key: _fieldKey,
    );
    return encrypted.toBytes();
  }

  Future<SecretPayload> _decrypt(Uint8List blob) async {
    final clear = await _cipher.decrypt(
      data: EncryptedData.fromBytes(blob),
      key: _fieldKey,
    );
    return SecretPayload.fromBytes(clear);
  }

  Future<void> _attachTags(String secretId, List<String> tagNames) async {
    for (final raw in tagNames) {
      final name = raw.trim();
      if (name.isEmpty) continue;
      final tagId = await _upsertTag(name);
      await _db.into(_db.secretTags).insert(
            SecretTagsCompanion.insert(secretId: secretId, tagId: tagId),
            mode: InsertMode.insertOrIgnore,
          );
    }
  }

  Future<String> _upsertTag(String name) async {
    final existing =
        await (_db.select(_db.tags)..where((t) => t.name.equals(name)))
            .getSingleOrNull();
    if (existing != null) return existing.id;
    final id = _uuid.v4();
    await _db.into(_db.tags).insert(TagsCompanion.insert(id: id, name: name));
    return id;
  }

  Future<List<String>> _tagsFor(String secretId) async {
    final query = _db.select(_db.tags).join([
      innerJoin(_db.secretTags, _db.secretTags.tagId.equalsExp(_db.tags.id)),
    ])
      ..where(_db.secretTags.secretId.equals(secretId))
      ..orderBy([OrderingTerm.asc(_db.tags.name)]);
    final rows = await query.get();
    return rows.map((r) => r.readTable(_db.tags).name).toList();
  }
}
