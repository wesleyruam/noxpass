// Parâmetros nomeados não podem ser privados (this._campo em named args não
// compila), então os campos são atribuídos manualmente.
// ignore_for_file: prefer_initializing_formals

import 'dart:typed_data';

import '../../vault/domain/repositories/secrets_repository.dart';
import 'backup_service.dart';

/// Liga o repositório do cofre ao [BackupService]: reúne os segredos para
/// exportar e recria os importados.
class VaultBackupManager {
  const VaultBackupManager({
    required SecretsRepository repository,
    required BackupService backupService,
  })  : _repository = repository,
        _backupService = backupService;

  final SecretsRepository _repository;
  final BackupService _backupService;

  /// Gera os bytes do backup criptografado dos segredos ativos.
  Future<Uint8List> create(String backupPassword) async {
    final secrets = await _repository.getActive();
    return _backupService.export(secrets, backupPassword);
  }

  /// Restaura os segredos de um backup, recriando-os. Retorna quantos entraram.
  Future<int> restore(Uint8List backupBytes, String backupPassword) async {
    final drafts = await _backupService.import(backupBytes, backupPassword);
    for (final draft in drafts) {
      await _repository.create(draft);
    }
    return drafts.length;
  }
}
