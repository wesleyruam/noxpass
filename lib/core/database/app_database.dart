import 'package:drift/drift.dart';

import 'tables.dart';

part 'app_database.g.dart';

/// Banco de dados local do NoxPass (Drift).
///
/// Em produção é aberto sobre SQLCipher (banco inteiro cifrado em repouso);
/// em testes recebe um executor em memória. O executor é injetado, então a
/// classe não sabe — nem precisa saber — como a conexão foi cifrada.
@DriftDatabase(
  tables: [Categories, Secrets, Tags, SecretTags, SecretVersions],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        beforeOpen: (details) async {
          // Integridade referencial (lixeira em cascata, tags, versões).
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
