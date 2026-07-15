import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/crypto_providers.dart';
import '../../vault/data/vault_providers.dart';
import '../domain/backup_service.dart';
import '../domain/vault_backup_manager.dart';

final backupServiceProvider = Provider<BackupService>(
  (ref) => BackupService(
    keyDerivation: ref.watch(keyDerivationServiceProvider),
    cipher: ref.watch(cipherServiceProvider),
    secureRandom: ref.watch(secureRandomProvider),
  ),
);

/// Orquestrador de backup da sessão atual (exige cofre destravado).
final vaultBackupManagerProvider = Provider<VaultBackupManager>(
  (ref) => VaultBackupManager(
    repository: ref.watch(secretsRepositoryProvider),
    backupService: ref.watch(backupServiceProvider),
  ),
);
