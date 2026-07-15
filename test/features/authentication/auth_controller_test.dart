import 'package:drift/native.dart' show NativeDatabase;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noxpass/core/crypto/kdf_params.dart';
import 'package:noxpass/core/crypto/unlocked_vault_keys.dart';
import 'package:noxpass/core/crypto/vault_key_material.dart';
import 'package:noxpass/core/database/app_database.dart';
import 'package:noxpass/core/session/vault_session.dart';
import 'package:noxpass/features/authentication/data/auth_data_providers.dart';
import 'package:noxpass/features/authentication/data/brute_force_guard.dart';
import 'package:noxpass/features/authentication/data/pin_credential_store.dart';
import 'package:noxpass/features/authentication/data/vault_database_factory.dart';
import 'package:noxpass/features/authentication/data/vault_material_store.dart';
import 'package:noxpass/features/authentication/domain/auth_state.dart';
import 'package:noxpass/features/authentication/domain/brute_force.dart';
import 'package:noxpass/features/authentication/presentation/auth_controller.dart';

/// Armazenamento de material em memória.
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

/// Fábrica que devolve um banco em memória (sem arquivos nem SQLCipher).
class _FakeDbFactory implements VaultDatabaseFactory {
  @override
  Future<AppDatabase> open(UnlockedVaultKeys keys) async =>
      AppDatabase(NativeDatabase.memory());
}

/// Registro de bloqueio em memória (sem secure storage).
class _FakeLockoutStore implements LockoutStore {
  LockoutState _state = LockoutState.initial;
  @override
  Future<LockoutState> read() async => _state;
  @override
  Future<void> write(LockoutState state) async => _state = state;
}

/// Credencial de PIN em memória.
class _FakePinStore implements PinCredentialStore {
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

void main() {
  late ProviderContainer container;
  late _FakeMaterialStore store;

  setUp(() {
    store = _FakeMaterialStore();
    container = ProviderContainer(
      overrides: [
        vaultMaterialStoreProvider.overrideWithValue(store),
        vaultDatabaseFactoryProvider.overrideWithValue(_FakeDbFactory()),
        // Argon2id barato para o teste rodar rápido.
        vaultKdfParamsProvider.overrideWithValue(KdfParams.insecureTestOnly),
        bruteForceGuardProvider.overrideWithValue(
          BruteForceGuard(store: _FakeLockoutStore()),
        ),
        pinCredentialStoreProvider.overrideWithValue(_FakePinStore()),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('primeiro uso: estado inicial é unregistered', () async {
    final state = await container.read(authControllerProvider.future);
    expect(state.status, VaultStatus.unregistered);
  });

  test('createVault destrava, persiste material e abre sessão', () async {
    await container.read(authControllerProvider.future);
    await container.read(authControllerProvider.notifier).createVault('minha-senha');

    final state = container.read(authControllerProvider).valueOrNull;
    expect(state?.status, VaultStatus.unlocked);
    expect(await store.exists(), isTrue);
    expect(container.read(vaultSessionProvider), isNotNull);
  });

  test('unlock aceita a senha certa e recusa a errada', () async {
    await container.read(authControllerProvider.future);
    final notifier = container.read(authControllerProvider.notifier);

    await notifier.createVault('correta');
    await notifier.lock();
    expect(container.read(vaultSessionProvider), isNull);
    expect(
      container.read(authControllerProvider).valueOrNull?.status,
      VaultStatus.locked,
    );

    await notifier.unlock('errada');
    final afterWrong = container.read(authControllerProvider).valueOrNull;
    expect(afterWrong?.status, VaultStatus.locked);
    expect(afterWrong?.error, isNotNull);
    expect(container.read(vaultSessionProvider), isNull);

    await notifier.unlock('correta');
    expect(
      container.read(authControllerProvider).valueOrNull?.status,
      VaultStatus.unlocked,
    );
    expect(container.read(vaultSessionProvider), isNotNull);
  });

  test('PIN: cadastra, destrava com PIN certo e recusa o errado', () async {
    await container.read(authControllerProvider.future);
    final notifier = container.read(authControllerProvider.notifier);

    await notifier.createVault('senha-mestra');
    await notifier.enrollPin('1234');
    expect(await container.read(isPinEnabledProvider.future), isTrue);

    await notifier.lock();
    expect(container.read(vaultSessionProvider), isNull);

    await notifier.unlockWithPin('1234');
    expect(
      container.read(authControllerProvider).valueOrNull?.status,
      VaultStatus.unlocked,
    );
    expect(container.read(vaultSessionProvider), isNotNull);

    await notifier.lock();
    await notifier.unlockWithPin('0000');
    final afterWrong = container.read(authControllerProvider).valueOrNull;
    expect(afterWrong?.status, VaultStatus.locked);
    expect(afterWrong?.error, isNotNull);
  });
}
