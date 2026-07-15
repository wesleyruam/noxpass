import 'package:cryptography/cryptography.dart';

/// Conjunto de chaves **sensíveis** disponível apenas com o cofre destravado.
///
/// Deve viver o menor tempo possível em memória. Chame [dispose] no auto-lock,
/// ao sair da sessão ou assim que as chaves não forem mais necessárias.
class UnlockedVaultKeys {
  UnlockedVaultKeys({
    required this.dataKey,
    required this.databaseKey,
    required this.fieldKey,
  });

  /// A DEK raiz do cofre (nunca usada diretamente para cifrar dados).
  final SecretKey dataKey;

  /// Subchave dedicada ao SQLCipher (chave do banco em repouso).
  final SecretKey databaseKey;

  /// Subchave dedicada ao envelope por campo (AES-256-GCM por segredo).
  final SecretKey fieldKey;

  bool _disposed = false;
  bool get isDisposed => _disposed;

  /// Destrói todo o material de chave em memória. Idempotente.
  void dispose() {
    if (_disposed) return;
    dataKey.destroy();
    databaseKey.destroy();
    fieldKey.destroy();
    _disposed = true;
  }
}
