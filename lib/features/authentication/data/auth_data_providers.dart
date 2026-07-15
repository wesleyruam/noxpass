import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/crypto/kdf_params.dart';
import 'brute_force_guard.dart';
import 'pin_credential_store.dart';
import 'vault_database_factory.dart';
import 'vault_material_store.dart';

/// Dependências de dados da autenticação (substituíveis em testes por fakes).

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  ),
);

final vaultMaterialStoreProvider = Provider<VaultMaterialStore>(
  (ref) => SecureVaultMaterialStore(ref.watch(secureStorageProvider)),
);

final vaultDatabaseFactoryProvider = Provider<VaultDatabaseFactory>(
  (ref) => const SqlCipherVaultDatabaseFactory(),
);

/// Parâmetros do Argon2id usados ao criar o cofre (testes reduzem o custo).
final vaultKdfParamsProvider = Provider<KdfParams>(
  (ref) => KdfParams.owaspDefault,
);

/// Proteção contra força bruta no desbloqueio da senha mestra.
final bruteForceGuardProvider = Provider<BruteForceGuard>(
  (ref) => BruteForceGuard(
    store: SecureLockoutStore(ref.watch(secureStorageProvider)),
  ),
);

/// Credencial de desbloqueio rápido por PIN.
final pinCredentialStoreProvider = Provider<PinCredentialStore>(
  (ref) => SecurePinCredentialStore(ref.watch(secureStorageProvider)),
);

/// Verdadeiro quando há um PIN configurado.
final isPinEnabledProvider = FutureProvider<bool>(
  (ref) => ref.watch(pinCredentialStoreProvider).exists(),
);
