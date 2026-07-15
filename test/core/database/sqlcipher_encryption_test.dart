@Tags(['sqlcipher'])
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:noxpass/core/database/app_database.dart';
import 'package:noxpass/core/database/sqlcipher.dart';
import 'package:path/path.dart' as p;

/// Teste de integração REAL do SQLCipher (usa a libsqlcipher do sistema no
/// host). Exercita o opener de produção `openEncryptedDatabase`, que no Linux
/// registra o override para `libsqlcipher.so`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final key = List<int>.generate(32, (i) => (i * 7 + 1) % 256);
  late Directory dir;
  late File dbFile;

  SecretsCompanion sampleSecret(String title) => SecretsCompanion.insert(
        id: 'id-1',
        type: 'password',
        title: title,
        encryptedPayload: Uint8List.fromList(const [1, 2, 3, 4]),
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

  setUp(() {
    dir = Directory.systemTemp.createTempSync('noxpass_sqlcipher');
    dbFile = File(p.join(dir.path, 'vault.db'));
  });

  tearDown(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  test('cifra em repouso e reabre com a chave correta', () async {
    const marker = 'TITULO-SECRETO-NO-DISCO';
    final db = AppDatabase(openEncryptedDatabase(file: dbFile, databaseKey: key));
    await db.into(db.secrets).insert(sampleSecret(marker));
    await db.close();

    // O arquivo em repouso não deve conter o texto puro nem o header do SQLite
    // (o SQLCipher cifra inclusive o cabeçalho).
    final bytes = dbFile.readAsBytesSync();
    final asText = latin1.decode(bytes, allowInvalid: true);
    expect(asText.contains(marker), isFalse, reason: 'vazou texto puro no disco');
    expect(asText.startsWith('SQLite format 3'), isFalse,
        reason: 'header não cifrado — SQLCipher não está atuando');

    // Reabrir com a chave certa recupera o dado.
    final db2 =
        AppDatabase(openEncryptedDatabase(file: dbFile, databaseKey: key));
    final row = await db2.select(db2.secrets).getSingle();
    expect(row.title, marker);
    await db2.close();
  });

  test('reabrir com chave errada falha (não decifra)', () async {
    final db = AppDatabase(openEncryptedDatabase(file: dbFile, databaseKey: key));
    await db.into(db.secrets).insert(sampleSecret('qualquer'));
    await db.close();

    final wrongKey = List<int>.generate(32, (i) => 255 - i);
    final db2 =
        AppDatabase(openEncryptedDatabase(file: dbFile, databaseKey: wrongKey));
    await expectLater(db2.select(db2.secrets).get(), throwsA(anything));
    try {
      await db2.close();
    } catch (_) {
      // Fechar um banco que nunca abriu direito pode lançar — irrelevante aqui.
    }
  });
}
