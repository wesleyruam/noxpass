import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/crypto_providers.dart';
import '../../../core/session/vault_session.dart';
import '../domain/repositories/secrets_repository.dart';
import 'secrets_repository_impl.dart';

/// Exceção lançada ao tentar acessar segredos com o cofre travado.
class VaultLockedException implements Exception {
  const VaultLockedException();

  @override
  String toString() => 'VaultLockedException: o cofre está travado.';
}

/// Repositório de segredos da sessão atual.
///
/// Depende da sessão destravada: a `fieldKey` e o banco vêm de lá. Enquanto o
/// cofre estiver travado, lançar deixa o erro explícito e cedo.
final secretsRepositoryProvider = Provider<SecretsRepository>((ref) {
  final session = ref.watch(vaultSessionProvider);
  if (session == null) {
    throw const VaultLockedException();
  }
  return SecretsRepositoryImpl(
    database: session.database,
    cipher: ref.watch(cipherServiceProvider),
    fieldKey: session.keys.fieldKey,
  );
});
