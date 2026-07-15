import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noxpass/core/crypto/aes_gcm_cipher_service.dart';
import 'package:noxpass/core/database/app_database.dart';
import 'package:noxpass/features/vault/data/secrets_repository_impl.dart';
import 'package:noxpass/features/vault/domain/entities/secret.dart';
import 'package:noxpass/features/vault/domain/entities/secret_payload.dart';
import 'package:noxpass/features/vault/domain/entities/secret_type.dart';

void main() {
  late AppDatabase db;
  late SecretsRepositoryImpl repo;
  final fieldKey = SecretKey(List<int>.generate(32, (i) => i * 3 % 256));

  SecretDraft draft({
    String title = 'GitHub',
    String password = 'hunter2-super-secreto',
    List<String> tags = const [],
    bool favorite = false,
  }) {
    return SecretDraft(
      type: SecretType.password,
      title: title,
      isFavorite: favorite,
      tags: tags,
      payload: SecretPayload({
        SecretPayload.username: 'wesley',
        SecretPayload.password: password,
        SecretPayload.url: 'https://github.com',
      }),
    );
  }

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = SecretsRepositoryImpl(
      database: db,
      cipher: AesGcmCipherService(),
      fieldKey: fieldKey,
    );
  });

  tearDown(() => db.close());

  group('create/getById', () {
    test('faz round-trip do payload decifrado', () async {
      final created = await repo.create(draft());
      final loaded = await repo.getById(created.id);

      expect(loaded, isNotNull);
      expect(loaded!.title, 'GitHub');
      expect(loaded.type, SecretType.password);
      expect(loaded.payload[SecretPayload.password], 'hunter2-super-secreto');
      expect(loaded.payload[SecretPayload.username], 'wesley');
    });

    test('o payload é gravado CIFRADO (blob opaco no banco)', () async {
      await repo.create(draft(password: 'SENHA-EM-TEXTO-PURO'));

      // Lê a linha crua, sem passar pela fronteira de decifragem.
      final row = await db.select(db.secrets).getSingle();
      final rawBlob = latin1.decode(row.encryptedPayload, allowInvalid: true);

      // A senha em claro NÃO pode aparecer nos bytes persistidos.
      expect(rawBlob.contains('SENHA-EM-TEXTO-PURO'), isFalse);
      expect(rawBlob.contains('wesley'), isFalse);
    });

    test('cada segredo tem nonce próprio (blobs diferentes p/ mesmo conteúdo)',
        () async {
      final a = await repo.create(draft());
      final b = await repo.create(draft());

      final rowA = await (db.select(db.secrets)..where((t) => t.id.equals(a.id)))
          .getSingle();
      final rowB = await (db.select(db.secrets)..where((t) => t.id.equals(b.id)))
          .getSingle();

      expect(rowA.encryptedPayload, isNot(equals(rowB.encryptedPayload)));
    });
  });

  group('getActive / busca', () {
    test('exclui itens na lixeira e ordena por atualização recente', () async {
      final s1 = await repo.create(draft(title: 'Alpha'));
      await Future<void>.delayed(const Duration(milliseconds: 5));
      final s2 = await repo.create(draft(title: 'Beta'));
      await repo.moveToTrash(s1.id);

      final active = await repo.getActive();
      expect(active.map((s) => s.id), [s2.id]);
    });

    test('filtra por título', () async {
      await repo.create(draft(title: 'Conta do Banco'));
      await repo.create(draft(title: 'E-mail pessoal'));

      final result = await repo.getActive(query: 'banco');
      expect(result, hasLength(1));
      expect(result.single.title, 'Conta do Banco');
    });
  });

  group('lixeira (soft delete + retenção)', () {
    test('move para a lixeira e restaura', () async {
      final s = await repo.create(draft());
      await repo.moveToTrash(s.id);

      expect(await repo.getActive(), isEmpty);
      expect((await repo.getTrash()).single.id, s.id);

      await repo.restore(s.id);
      expect((await repo.getActive()).single.id, s.id);
      expect(await repo.getTrash(), isEmpty);
    });

    test('purga apenas itens vencidos (>30 dias)', () async {
      // Repositório com relógio controlado no passado para "envelhecer" a lixeira.
      final old = DateTime(2020, 1, 1);
      final oldRepo = SecretsRepositoryImpl(
        database: db,
        cipher: AesGcmCipherService(),
        fieldKey: fieldKey,
        clock: () => old,
      );
      final s = await oldRepo.create(draft());
      await oldRepo.moveToTrash(s.id); // deletedAt = 2020

      final recent = await repo.create(draft(title: 'recente'));
      await repo.moveToTrash(recent.id); // deletedAt = agora

      final removed = await repo.purgeExpiredTrash();
      expect(removed, 1);
      expect((await repo.getTrash()).single.id, recent.id);
    });
  });

  group('histórico', () {
    test('update gera snapshot da versão anterior', () async {
      final s = await repo.create(draft(password: 'senha-v1'));
      await repo.update(
        s.id,
        draft(title: 'GitHub', password: 'senha-v2'),
      );

      final current = await repo.getById(s.id);
      expect(current!.payload[SecretPayload.password], 'senha-v2');

      final versions = await repo.getVersions(s.id);
      expect(versions, hasLength(1));
      expect(versions.single.payload[SecretPayload.password], 'senha-v1');
    });

    test('restoreVersion volta ao conteúdo antigo e preserva a versão atual',
        () async {
      final s = await repo.create(draft(password: 'senha-v1'));
      await repo.update(s.id, draft(password: 'senha-v2'));
      final v1 = (await repo.getVersions(s.id)).single; // snapshot de v1

      await repo.restoreVersion(s.id, v1.id);

      final current = await repo.getById(s.id);
      expect(current!.payload[SecretPayload.password], 'senha-v1');
      // Agora há 2 versões: a v1 original e o snapshot da v2 (antes de restaurar).
      final versions = await repo.getVersions(s.id);
      expect(versions, hasLength(2));
      expect(
        versions.map((v) => v.payload[SecretPayload.password]),
        containsAll(['senha-v1', 'senha-v2']),
      );
    });
  });

  group('tags e favoritos', () {
    test('persiste e recupera tags, reutilizando as existentes', () async {
      final a = await repo.create(draft(title: 'A', tags: ['trabalho', 'dev']));
      final b = await repo.create(draft(title: 'B', tags: ['dev']));

      expect((await repo.getById(a.id))!.tags, containsAll(['trabalho', 'dev']));
      expect((await repo.getById(b.id))!.tags, ['dev']);

      // 'dev' foi reaproveitada — só 2 tags distintas no total.
      final tagCount = await db.select(db.tags).get();
      expect(tagCount, hasLength(2));
    });

    test('setFavorite reflete em getFavorites', () async {
      final s = await repo.create(draft());
      expect(await repo.getFavorites(), isEmpty);

      await repo.setFavorite(s.id, value: true);
      expect((await repo.getFavorites()).single.id, s.id);
    });
  });

  group('categorias', () {
    test('cria e lista categorias', () async {
      final created = await repo.createCategory('Trabalho', icon: 'work');
      expect(created.name, 'Trabalho');
      expect(created.isBuiltIn, isFalse);

      final list = await repo.watchCategories().first;
      expect(list.map((c) => c.name), contains('Trabalho'));
    });

    test('renomeia categoria', () async {
      final c = await repo.createCategory('Antigo');
      await repo.renameCategory(c.id, 'Novo');
      final list = await repo.watchCategories().first;
      expect(list.single.name, 'Novo');
    });

    test('apagar categoria desvincula os segredos (categoryId vira null)',
        () async {
      final c = await repo.createCategory('Bancos');
      final s = await repo.create(
        SecretDraft(
          type: SecretType.password,
          title: 'Nubank',
          categoryId: c.id,
          payload: const SecretPayload({SecretPayload.password: 'senha-forte-123'}),
        ),
      );
      expect((await repo.getById(s.id))!.categoryId, c.id);

      await repo.deleteCategory(c.id);

      expect((await repo.getById(s.id))!.categoryId, isNull);
      expect(await repo.watchCategories().first, isEmpty);
    });
  });
}
