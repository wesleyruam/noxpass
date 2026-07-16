// Campos privados não podem virar parâmetros nomeados (this._campo em named
// args não compila), então são atribuídos manualmente.
// ignore_for_file: prefer_initializing_formals

import 'dart:typed_data';

import '../../backup/domain/vault_backup_manager.dart';
import '../data/google_drive_auth.dart';
import 'drive_sync_service.dart';

/// Não havia backup remoto para restaurar.
class NoRemoteBackup implements Exception {
  const NoRemoteBackup();
}

/// Orquestra backup/restauração do cofre via Google Drive, reaproveitando o
/// [VaultBackupManager] (mesma cifra AES-256-GCM + Argon2id do backup local).
///
/// Zero-Knowledge preservado: os bytes já saem cifrados sob a senha de backup;
/// o Drive nunca vê texto claro, a senha mestra nem a de backup.
class DriveBackupManager {
  DriveBackupManager({
    required GoogleDriveAuth auth,
    required VaultBackupManager backup,
  }) : _auth = auth,
       _backup = backup;

  final GoogleDriveAuth _auth;
  final VaultBackupManager _backup;

  String? get email => _auth.email;
  bool get isConnected => _auth.isSignedIn;

  Future<String?> connect() async => (await _auth.signIn()).email;
  Future<void> disconnect() => _auth.signOut();

  /// Reconecta uma sessão anterior sem interação. Retorna o e-mail ou null.
  Future<String?> restoreSession() async => (await _auth.restore())?.email;

  /// Cifra o cofre com [backupPassword] e envia para o Drive do usuário.
  Future<void> backupToDrive(String backupPassword) async {
    final bytes = await _backup.create(backupPassword);
    final api = await _auth.driveApi();
    await DriveSyncService(api).upload(bytes);
  }

  /// Baixa os bytes cifrados do backup remoto (a reconciliação com o cofre é
  /// feita depois, pelo [VaultBackupManager]).
  /// Lança [NoRemoteBackup] se não houver backup na conta.
  Future<Uint8List> downloadBytes() async {
    final api = await _auth.driveApi();
    final bytes = await DriveSyncService(api).download();
    if (bytes == null) throw const NoRemoteBackup();
    return bytes;
  }

  /// Data da última modificação do backup remoto (sem interação). Null se não
  /// houver backup ou se ainda não estiver conectado/autorizado.
  Future<DateTime?> lastRemoteChange() async {
    if (!_auth.isSignedIn) return null;
    final api = await _auth.driveApi(interactive: false);
    return DriveSyncService(api).remoteModifiedTime();
  }
}
