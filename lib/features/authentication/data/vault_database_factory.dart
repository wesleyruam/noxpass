import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/crypto/unlocked_vault_keys.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/sqlcipher.dart';

/// Abre o [AppDatabase] cifrado da sessão a partir das chaves destravadas.
///
/// Abstraído para permitir substituição por um banco em memória nos testes,
/// sem tocar em arquivos nem no SQLCipher.
abstract interface class VaultDatabaseFactory {
  Future<AppDatabase> open(UnlockedVaultKeys keys);
}

/// Implementação de produção: banco cifrado por SQLCipher no diretório de
/// suporte do app, com a `databaseKey` derivada da DEK.
class SqlCipherVaultDatabaseFactory implements VaultDatabaseFactory {
  const SqlCipherVaultDatabaseFactory();

  static const String _dbFileName = 'noxpass_vault.db';

  @override
  Future<AppDatabase> open(UnlockedVaultKeys keys) async {
    final dir = await getApplicationSupportDirectory();
    final file = File(p.join(dir.path, _dbFileName));
    final keyBytes = await keys.databaseKey.extractBytes();
    return AppDatabase(
      openEncryptedDatabase(file: file, databaseKey: keyBytes),
    );
  }
}
