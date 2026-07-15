import 'package:drift/native.dart' show NativeDatabase;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noxpass/core/crypto/kdf_params.dart';
import 'package:noxpass/core/crypto/unlocked_vault_keys.dart';
import 'package:noxpass/core/crypto/vault_key_material.dart';
import 'package:noxpass/core/database/app_database.dart';
import 'package:noxpass/core/session/vault_session.dart';
import 'package:noxpass/features/authentication/data/auth_data_providers.dart';
import 'package:noxpass/features/authentication/data/vault_database_factory.dart';
import 'package:noxpass/features/authentication/data/vault_material_store.dart';
import 'package:noxpass/features/authentication/presentation/auth_controller.dart';
import 'package:noxpass/features/authentication/presentation/auto_lock_scope.dart';

class _FakeMaterialStore implements VaultMaterialStore {
  VaultKeyMaterial? _material;
  @override
  Future<void> clear() async => _material = null;
  @override
  Future<bool> exists() async => _material != null;
  @override
  Future<VaultKeyMaterial?> read() async => _material;
  @override
  Future<void> write(VaultKeyMaterial material) async => _material = material;
}

class _FakeDbFactory implements VaultDatabaseFactory {
  @override
  Future<AppDatabase> open(UnlockedVaultKeys keys) async =>
      AppDatabase(NativeDatabase.memory());
}

void main() {
  testWidgets('trava o cofre ao ir para segundo plano', (tester) async {
    final container = ProviderContainer(
      overrides: [
        vaultMaterialStoreProvider.overrideWithValue(_FakeMaterialStore()),
        vaultDatabaseFactoryProvider.overrideWithValue(_FakeDbFactory()),
        vaultKdfParamsProvider.overrideWithValue(KdfParams.insecureTestOnly),
      ],
    );
    addTearDown(container.dispose);

    await container.read(authControllerProvider.future);
    await container.read(authControllerProvider.notifier).createVault('senha');
    expect(container.read(isVaultUnlockedProvider), isTrue);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: AutoLockScope(child: SizedBox()),
        ),
      ),
    );
    await tester.pump();

    // Simula o app indo para segundo plano.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pumpAndSettle();

    expect(container.read(isVaultUnlockedProvider), isFalse);
  });
}
