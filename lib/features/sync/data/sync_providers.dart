import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../backup/data/backup_providers.dart';
import '../domain/drive_backup_manager.dart';
import 'google_drive_auth.dart';

/// Sessão de autenticação Google (singleton — mantém a conta em memória).
final googleDriveAuthProvider = Provider<GoogleDriveAuth>(
  (ref) => GoogleDriveAuth(),
);

/// Orquestrador de sincronização via Drive (exige cofre destravado).
final driveBackupManagerProvider = Provider<DriveBackupManager>(
  (ref) => DriveBackupManager(
    auth: ref.watch(googleDriveAuthProvider),
    backup: ref.watch(vaultBackupManagerProvider),
  ),
);
