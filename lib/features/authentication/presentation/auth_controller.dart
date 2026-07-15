import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/crypto/crypto_failure.dart';
import '../../../core/crypto/unlocked_vault_keys.dart';
import '../../../core/di/crypto_providers.dart';
import '../../../core/session/vault_session.dart';
import '../../vault/data/builtin_categories.dart';
import '../data/auth_data_providers.dart';
import '../data/biometric_credential_store.dart';
import '../domain/auth_state.dart';

/// Orquestra o ciclo de acesso ao cofre: cadastro, unlock e lock.
///
/// É o único lugar que conecta senha mestra → chaves → banco cifrado → sessão.
/// Estado assíncrono para a UI refletir carregamento e erros diretamente.
class AuthController extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    final exists = await ref.read(vaultMaterialStoreProvider).exists();
    return AuthState(
      exists ? VaultStatus.locked : VaultStatus.unregistered,
    );
  }

  /// Cria o cofre a partir de uma senha mestra nova e já o destrava.
  Future<void> createVault(String masterPassword) async {
    state = const AsyncLoading<AuthState>().copyWithPrevious(state);
    state = await AsyncValue.guard(() async {
      final creation = await ref
          .read(vaultKeyServiceProvider)
          .createVault(masterPassword, params: ref.read(vaultKdfParamsProvider));
      await ref.read(vaultMaterialStoreProvider).write(creation.material);
      final db = await ref.read(vaultDatabaseFactoryProvider).open(creation.keys);
      await seedBuiltInCategories(db);
      ref
          .read(vaultSessionProvider.notifier)
          .open(VaultSession(database: db, keys: creation.keys));
      return const AuthState(VaultStatus.unlocked);
    });
  }

  /// Destrava um cofre existente. Senha incorreta não é erro fatal: volta a
  /// [VaultStatus.locked] com uma mensagem. Protegido contra força bruta.
  Future<void> unlock(String masterPassword) async {
    state = const AsyncLoading<AuthState>().copyWithPrevious(state);
    state = await AsyncValue.guard(() async {
      final guard = ref.read(bruteForceGuardProvider);

      // Já bloqueado por tentativas demais?
      final blocked = await guard.currentLockout();
      if (blocked != null) {
        return AuthState(
          VaultStatus.locked,
          error: 'Muitas tentativas. Aguarde ${_formatDuration(blocked)}.',
        );
      }

      final material = await ref.read(vaultMaterialStoreProvider).read();
      if (material == null) {
        return const AuthState(VaultStatus.unregistered);
      }

      final UnlockedVaultKeys keys;
      try {
        keys = await ref.read(vaultKeyServiceProvider).unlock(masterPassword, material);
      } on AuthenticationFailure {
        await guard.recordFailure();
        final penalty = await guard.currentLockout();
        return AuthState(
          VaultStatus.locked,
          error: penalty != null
              ? 'Senha incorreta. Bloqueado por ${_formatDuration(penalty)}.'
              : 'Senha mestra incorreta.',
        );
      }

      await guard.recordSuccess();
      final db = await ref.read(vaultDatabaseFactoryProvider).open(keys);
      ref
          .read(vaultSessionProvider.notifier)
          .open(VaultSession(database: db, keys: keys));
      return const AuthState(VaultStatus.unlocked);
    });
  }

  String _formatDuration(Duration d) {
    if (d.inMinutes >= 1) return '${d.inMinutes} min';
    return '${d.inSeconds.clamp(1, 59)} s';
  }

  /// Cadastra um PIN de desbloqueio rápido, embrulhando a DEK atual sob ele.
  /// Requer o cofre destravado.
  Future<void> enrollPin(String pin) async {
    final session = ref.read(vaultSessionProvider);
    if (session == null) {
      throw StateError('É preciso estar com o cofre destravado.');
    }
    final dek = await session.keys.dataKey.extractBytes();
    final material = await ref.read(vaultKeyServiceProvider).wrapDek(
          Uint8List.fromList(dek),
          pin,
          params: ref.read(vaultKdfParamsProvider),
        );
    await ref.read(pinCredentialStoreProvider).write(material);
    ref.invalidate(isPinEnabledProvider);
  }

  /// Remove o PIN de desbloqueio rápido.
  Future<void> disablePin() async {
    await ref.read(pinCredentialStoreProvider).clear();
    ref.invalidate(isPinEnabledProvider);
  }

  /// Destrava o cofre pelo PIN. Sujeito à mesma proteção de força bruta.
  Future<void> unlockWithPin(String pin) async {
    state = const AsyncLoading<AuthState>().copyWithPrevious(state);
    state = await AsyncValue.guard(() async {
      final guard = ref.read(bruteForceGuardProvider);
      final blocked = await guard.currentLockout();
      if (blocked != null) {
        return AuthState(
          VaultStatus.locked,
          error: 'Muitas tentativas. Aguarde ${_formatDuration(blocked)}.',
        );
      }

      final material = await ref.read(pinCredentialStoreProvider).read();
      if (material == null) {
        return const AuthState(VaultStatus.locked, error: 'PIN não configurado.');
      }

      final UnlockedVaultKeys keys;
      try {
        keys = await ref.read(vaultKeyServiceProvider).unlock(pin, material);
      } on AuthenticationFailure {
        await guard.recordFailure();
        final penalty = await guard.currentLockout();
        return AuthState(
          VaultStatus.locked,
          error: penalty != null
              ? 'PIN incorreto. Bloqueado por ${_formatDuration(penalty)}.'
              : 'PIN incorreto.',
        );
      }

      await guard.recordSuccess();
      final db = await ref.read(vaultDatabaseFactoryProvider).open(keys);
      ref
          .read(vaultSessionProvider.notifier)
          .open(VaultSession(database: db, keys: keys));
      return const AuthState(VaultStatus.unlocked);
    });
  }

  /// Cadastra a biometria: embrulha a DEK sob um segredo aleatório de alta
  /// entropia guardado no armazenamento seguro. Requer o cofre destravado.
  Future<void> enrollBiometric() async {
    final session = ref.read(vaultSessionProvider);
    if (session == null) {
      throw StateError('É preciso estar com o cofre destravado.');
    }
    final dek = await session.keys.dataKey.extractBytes();
    final secret = base64Encode(ref.read(secureRandomProvider).nextBytes(32));
    final material = await ref.read(vaultKeyServiceProvider).wrapDek(
          Uint8List.fromList(dek),
          secret,
          params: ref.read(vaultKdfParamsProvider),
        );
    await ref
        .read(biometricCredentialStoreProvider)
        .write(BiometricCredential(secret: secret, material: material));
    ref.invalidate(isBiometricEnabledProvider);
  }

  Future<void> disableBiometric() async {
    await ref.read(biometricCredentialStoreProvider).clear();
    ref.invalidate(isBiometricEnabledProvider);
  }

  /// Destrava por biometria: confirma a identidade e, se ok, abre o cofre.
  Future<void> unlockWithBiometric() async {
    final credential = await ref.read(biometricCredentialStoreProvider).read();
    if (credential == null) return;

    final confirmed = await ref
        .read(biometricAuthenticatorProvider)
        .authenticate('Desbloquear o NoxPass');
    if (!confirmed) {
      state = const AsyncData(
        AuthState(VaultStatus.locked, error: 'Biometria não confirmada.'),
      );
      return;
    }

    state = const AsyncLoading<AuthState>().copyWithPrevious(state);
    state = await AsyncValue.guard(() async {
      final keys = await ref
          .read(vaultKeyServiceProvider)
          .unlock(credential.secret, credential.material);
      final db = await ref.read(vaultDatabaseFactoryProvider).open(keys);
      ref
          .read(vaultSessionProvider.notifier)
          .open(VaultSession(database: db, keys: keys));
      return const AuthState(VaultStatus.unlocked);
    });
  }

  /// Trava o cofre (descarta chaves, fecha o banco).
  Future<void> lock() async {
    await ref.read(vaultSessionProvider.notifier).lock();
    state = const AsyncData(AuthState(VaultStatus.locked));
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthState>(AuthController.new);
