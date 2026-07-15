import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:noxpass/core/crypto/crypto_failure.dart';
import 'package:noxpass/core/crypto/kdf_params.dart';
import 'package:noxpass/core/crypto/vault_key_material.dart';
import 'package:noxpass/core/crypto/vault_key_service.dart';

void main() {
  final service = VaultKeyService();
  // Parâmetros baratos para manter a suíte rápida — jamais usar em produção.
  const params = KdfParams.insecureTestOnly;

  group('VaultKeyService.createVault', () {
    test('gera material persistível coerente', () async {
      final created = await service.createVault('senha-mestra', params: params);

      expect(created.material.kdfSalt, hasLength(16));
      expect(created.material.kdfParams, params);
      expect(created.keys.isDisposed, isFalse);
      addTearDown(created.keys.dispose);
    });

    test('databaseKey e fieldKey são distintas entre si e da DEK', () async {
      final created = await service.createVault('senha-mestra', params: params);
      addTearDown(created.keys.dispose);

      final dek = await created.keys.dataKey.extractBytes();
      final dbKey = await created.keys.databaseKey.extractBytes();
      final fieldKey = await created.keys.fieldKey.extractBytes();

      expect(dbKey, isNot(equals(fieldKey)));
      expect(dbKey, isNot(equals(dek)));
      expect(fieldKey, isNot(equals(dek)));
      expect(dbKey, hasLength(32));
      expect(fieldKey, hasLength(32));
    });
  });

  group('VaultKeyService.unlock', () {
    test('senha correta reconstrói exatamente as mesmas chaves', () async {
      final created = await service.createVault('correta', params: params);
      addTearDown(created.keys.dispose);

      final unlocked = await service.unlock('correta', created.material);
      addTearDown(unlocked.dispose);

      expect(
        await unlocked.databaseKey.extractBytes(),
        await created.keys.databaseKey.extractBytes(),
      );
      expect(
        await unlocked.fieldKey.extractBytes(),
        await created.keys.fieldKey.extractBytes(),
      );
    });

    test('senha incorreta lança AuthenticationFailure', () async {
      final created = await service.createVault('correta', params: params);
      addTearDown(created.keys.dispose);

      expect(
        () => service.unlock('errada', created.material),
        throwsA(isA<AuthenticationFailure>()),
      );
    });
  });

  group('VaultKeyService.changeMasterPassword', () {
    test('preserva a DEK e passa a aceitar só a nova senha', () async {
      final created = await service.createVault('antiga', params: params);
      addTearDown(created.keys.dispose);

      final newMaterial = await service.changeMasterPassword(
        currentPassword: 'antiga',
        newPassword: 'nova',
        material: created.material,
        newParams: params,
      );

      // Salt muda; a DEK subjacente permanece a mesma.
      expect(newMaterial.kdfSalt, isNot(equals(created.material.kdfSalt)));

      final reUnlocked = await service.unlock('nova', newMaterial);
      addTearDown(reUnlocked.dispose);
      expect(
        await reUnlocked.dataKey.extractBytes(),
        await created.keys.dataKey.extractBytes(),
      );

      // A senha antiga não abre mais o material novo.
      expect(
        () => service.unlock('antiga', newMaterial),
        throwsA(isA<AuthenticationFailure>()),
      );
    });

    test('senha atual errada não permite a troca', () async {
      final created = await service.createVault('antiga', params: params);
      addTearDown(created.keys.dispose);

      expect(
        () => service.changeMasterPassword(
          currentPassword: 'chute-errado',
          newPassword: 'nova',
          material: created.material,
        ),
        throwsA(isA<AuthenticationFailure>()),
      );
    });
  });

  group('VaultKeyService.wrapDek (credencial secundária / PIN)', () {
    test('abre a MESMA DEK com um segredo secundário', () async {
      final created = await service.createVault('senha-mestra', params: params);
      addTearDown(created.keys.dispose);

      final dek = await created.keys.dataKey.extractBytes();
      final pinMaterial = await service.wrapDek(
        Uint8List.fromList(dek),
        '1234',
        params: params,
      );

      final viaPin = await service.unlock('1234', pinMaterial);
      addTearDown(viaPin.dispose);
      expect(
        await viaPin.databaseKey.extractBytes(),
        await created.keys.databaseKey.extractBytes(),
      );
      expect(
        await viaPin.fieldKey.extractBytes(),
        await created.keys.fieldKey.extractBytes(),
      );
    });

    test('segredo secundário incorreto falha', () async {
      final created = await service.createVault('x', params: params);
      addTearDown(created.keys.dispose);
      final dek = await created.keys.dataKey.extractBytes();
      final pinMaterial =
          await service.wrapDek(Uint8List.fromList(dek), '1234', params: params);

      expect(
        () => service.unlock('9999', pinMaterial),
        throwsA(isA<AuthenticationFailure>()),
      );
    });
  });

  group('VaultKeyMaterial serialização', () {
    test('json roundtrip preserva salt, params e DEK embrulhada', () async {
      final created = await service.createVault('x', params: params);
      addTearDown(created.keys.dispose);

      final restored = VaultKeyMaterial.fromJson(created.material.toJson());

      expect(restored.kdfSalt, created.material.kdfSalt);
      expect(restored.kdfParams, created.material.kdfParams);
      expect(restored.wrappedDek.toBytes(), created.material.wrappedDek.toBytes());

      // E o material restaurado destrava normalmente.
      final unlocked = await service.unlock('x', restored);
      addTearDown(unlocked.dispose);
      expect(unlocked.isDisposed, isFalse);
    });
  });
}
