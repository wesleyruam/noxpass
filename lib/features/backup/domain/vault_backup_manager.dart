// Parâmetros nomeados não podem ser privados (this._campo em named args não
// compila), então os campos são atribuídos manualmente.
// ignore_for_file: prefer_initializing_formals

import 'dart:typed_data';

import '../../vault/domain/repositories/secrets_repository.dart';
import 'backup_service.dart';
import 'restore_plan.dart';

/// Liga o repositório do cofre ao [BackupService]: reúne os segredos para
/// exportar e reconcilia os importados com o cofre atual.
class VaultBackupManager {
  const VaultBackupManager({
    required SecretsRepository repository,
    required BackupService backupService,
  }) : _repository = repository,
       _backupService = backupService;

  final SecretsRepository _repository;
  final BackupService _backupService;

  /// Gera os bytes do backup criptografado dos segredos ativos.
  Future<Uint8List> create(String backupPassword) async {
    final secrets = await _repository.getActive();
    return _backupService.export(secrets, backupPassword);
  }

  /// Decifra o backup e o compara com o cofre atual, montando a prévia do
  /// restore (novos, conflitos e idênticos). Não altera nada ainda.
  Future<RestorePlan> planRestore(
    Uint8List backupBytes,
    String backupPassword,
  ) async {
    final drafts = await _backupService.import(backupBytes, backupPassword);
    final existing = await _repository.getActive();
    return const RestorePlanner().plan(drafts, existing);
  }

  /// Aplica um plano (já com as resoluções escolhidas). Retorna o resumo.
  Future<RestoreSummary> applyRestore(RestorePlan plan) async {
    var added = 0, replaced = 0, skipped = 0;
    for (final item in plan.items) {
      switch (item.resolution) {
        case RestoreResolution.skip:
          skipped++;
        case RestoreResolution.duplicate:
          await _repository.create(item.incoming);
          added++;
        case RestoreResolution.replace:
          await _repository.update(item.existing!.id, item.incoming);
          replaced++;
      }
    }
    return RestoreSummary(added: added, replaced: replaced, skipped: skipped);
  }
}
