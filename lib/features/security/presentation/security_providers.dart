import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../vault/presentation/secrets_providers.dart';
import '../domain/vault_security.dart';

/// Relatório de segurança derivado, em tempo real, da lista de segredos.
final securityReportProvider = Provider.autoDispose<VaultSecurityReport>((ref) {
  final secrets = ref.watch(secretsListProvider).valueOrNull ?? const [];
  return analyzeVault(secrets);
});
