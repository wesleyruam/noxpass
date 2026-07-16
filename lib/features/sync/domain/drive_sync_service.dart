import 'dart:typed_data';

import 'package:googleapis/drive/v3.dart' as drive;

/// Operações de baixo nível na pasta privada (`appDataFolder`) do NoxPass no
/// Drive do usuário. Mantém um único arquivo de backup cifrado, sobrescrito a
/// cada envio ("última gravação vence").
class DriveSyncService {
  DriveSyncService(this._api);

  final drive.DriveApi _api;

  static const String _fileName = 'noxpass-vault.backup';
  static const String _appFolder = 'appDataFolder';

  /// Metadados do backup remoto, ou null se ainda não existir.
  Future<drive.File?> _find() async {
    final result = await _api.files.list(
      spaces: _appFolder,
      q: "name = '$_fileName'",
      orderBy: 'modifiedTime desc',
      $fields: 'files(id,modifiedTime,size)',
    );
    final files = result.files;
    if (files == null || files.isEmpty) return null;
    return files.first;
  }

  /// Data da última modificação do backup remoto, ou null se não houver.
  Future<DateTime?> remoteModifiedTime() async => (await _find())?.modifiedTime;

  /// Envia o backup cifrado, criando o arquivo ou substituindo o existente.
  Future<void> upload(Uint8List bytes) async {
    final media = drive.Media(Stream.value(bytes), bytes.length);
    final existing = await _find();
    if (existing == null) {
      final metadata = drive.File()
        ..name = _fileName
        ..parents = <String>[_appFolder];
      await _api.files.create(metadata, uploadMedia: media);
    } else {
      await _api.files.update(drive.File(), existing.id!, uploadMedia: media);
    }
  }

  /// Baixa os bytes do backup remoto, ou null se não houver nenhum.
  Future<Uint8List?> download() async {
    final existing = await _find();
    if (existing == null) return null;
    final media =
        await _api.files.get(
              existing.id!,
              downloadOptions: drive.DownloadOptions.fullMedia,
            )
            as drive.Media;
    final builder = BytesBuilder(copy: false);
    await for (final chunk in media.stream) {
      builder.add(chunk);
    }
    return builder.takeBytes();
  }
}
