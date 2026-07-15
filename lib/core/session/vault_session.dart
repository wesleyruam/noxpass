import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../crypto/unlocked_vault_keys.dart';
import '../database/app_database.dart';

/// Estado de um cofre **destravado**: banco aberto + chaves vivas em memória.
///
/// Existe apenas entre o unlock e o lock. Ao travar, tudo aqui é liberado.
class VaultSession {
  const VaultSession({required this.database, required this.keys});

  final AppDatabase database;
  final UnlockedVaultKeys keys;
}

/// Controla o ciclo de vida da sessão (destravar/travar).
///
/// Será acionado pelo fluxo de onboarding/login (próxima onda). Ao travar,
/// destrói as chaves e fecha o banco — nada sensível permanece em memória.
class VaultSessionController extends Notifier<VaultSession?> {
  @override
  VaultSession? build() {
    ref.onDispose(_disposeCurrent);
    return null;
  }

  /// Instala uma sessão recém-destravada.
  void open(VaultSession session) => state = session;

  /// Trava o cofre: descarta chaves e fecha o banco.
  Future<void> lock() async {
    final current = state;
    state = null;
    if (current != null) {
      current.keys.dispose();
      await current.database.close();
    }
  }

  void _disposeCurrent() {
    state?.keys.dispose();
  }
}

final vaultSessionProvider =
    NotifierProvider<VaultSessionController, VaultSession?>(
  VaultSessionController.new,
);

/// Verdadeiro quando há um cofre destravado.
final isVaultUnlockedProvider = Provider<bool>(
  (ref) => ref.watch(vaultSessionProvider) != null,
);
