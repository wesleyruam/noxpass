import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import 'package:sqlite3/open.dart';

import 'sqlcipher_key.dart';

/// Abertura do banco cifrado com SQLCipher (código de plataforma; roda apenas
/// no app/device, não nos testes de host).
///
/// A `databaseKey` é a subchave HKDF dedicada ao banco (ver `VaultKeyService`).

bool _openConfigured = false;

/// Aponta o `sqlite3` para a biblioteca do SQLCipher em cada plataforma.
void _configureSqlCipherOpen() {
  if (_openConfigured) return;
  open
    ..overrideFor(OperatingSystem.android, openCipherOnAndroid)
    ..overrideFor(
      OperatingSystem.linux,
      () => DynamicLibrary.open('libsqlcipher.so'),
    )
    ..overrideFor(
      OperatingSystem.windows,
      () => DynamicLibrary.open('sqlcipher.dll'),
    );
  // iOS e macOS: SQLCipher é linkado estaticamente; o padrão (process) resolve.
  _openConfigured = true;
}

/// Garante que a biblioteca do SQLCipher está pronta para uso.
Future<void> ensureSqlCipherReady() async {
  _configureSqlCipherOpen();
  await applyWorkaroundToOpenSqlCipherOnOldAndroidVersions();
}

/// Cria um executor Drift sobre um arquivo cifrado por SQLCipher.
///
/// Roda no isolate atual (não em background) para que o override de `open`
/// configurado acima esteja em vigor no momento da abertura.
QueryExecutor openEncryptedDatabase({
  required File file,
  required List<int> databaseKey,
}) {
  final keyPragma = formatRawKeyPragma(databaseKey);
  return LazyDatabase(() async {
    await ensureSqlCipherReady();
    return NativeDatabase(
      file,
      setup: (rawDb) {
        // A chave DEVE ser aplicada antes de qualquer outra operação.
        rawDb.execute(keyPragma);
        // Sanidade: confirma que a biblioteca ativa é mesmo o SQLCipher.
        final cipher = rawDb.select('PRAGMA cipher_version;');
        if (cipher.isEmpty) {
          throw StateError(
            'SQLCipher não está ativo — a biblioteca nativa carregada não '
            'suporta cifragem.',
          );
        }
      },
    );
  });
}
