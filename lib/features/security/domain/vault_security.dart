import '../../../shared/security/password_strength.dart';
import '../../vault/domain/entities/secret.dart';
import '../../vault/domain/entities/secret_payload.dart';

/// Diagnóstico de segurança do cofre, derivado dos segredos já decifrados.
///
/// Objeto de valor imutável, produto de [analyzeVault] — função pura, portanto
/// trivialmente testável e sem efeitos colaterais.
class VaultSecurityReport {
  const VaultSecurityReport({
    required this.total,
    required this.favorites,
    required this.weakSecrets,
    required this.reusedGroups,
  });

  const VaultSecurityReport.empty()
      : total = 0,
        favorites = 0,
        weakSecrets = const [],
        reusedGroups = const [];

  /// Total de segredos ativos.
  final int total;

  /// Quantidade marcada como favorita.
  final int favorites;

  /// Segredos com senha fraca (muito fraca ou fraca).
  final List<Secret> weakSecrets;

  /// Grupos de segredos que compartilham a mesma senha (cada grupo tem 2+).
  final List<List<Secret>> reusedGroups;

  int get weakCount => weakSecrets.length;

  /// Total de segredos envolvidos em reutilização de senha.
  int get reusedCount =>
      reusedGroups.fold(0, (sum, group) => sum + group.length);

  bool get hasIssues => weakCount > 0 || reusedCount > 0;
}

/// Analisa a saúde de segurança de uma lista de segredos.
VaultSecurityReport analyzeVault(List<Secret> secrets) {
  if (secrets.isEmpty) return const VaultSecurityReport.empty();

  final weak = <Secret>[];
  final byPassword = <String, List<Secret>>{};
  var favorites = 0;

  for (final secret in secrets) {
    if (secret.isFavorite) favorites++;

    final password = secret.payload[SecretPayload.password];
    if (password == null || password.isEmpty) continue;

    final strength = evaluatePasswordStrength(password).strength;
    if (strength.index <= PasswordStrength.weak.index) {
      weak.add(secret);
    }
    byPassword.putIfAbsent(password, () => <Secret>[]).add(secret);
  }

  final reusedGroups = byPassword.values
      .where((group) => group.length >= 2)
      .toList(growable: false);

  return VaultSecurityReport(
    total: secrets.length,
    favorites: favorites,
    weakSecrets: weak,
    reusedGroups: reusedGroups,
  );
}
