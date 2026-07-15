import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tempo de inatividade até o cofre travar sozinho.
///
/// `Duration.zero` significa "somente ao sair do app" (sem timer de
/// inatividade). O cofre sempre trava ao ir para segundo plano.
///
/// Em memória por enquanto (reinicia a cada sessão); persistência virá depois.
final autoLockTimeoutProvider = StateProvider<Duration>(
  (ref) => const Duration(minutes: 3),
);

/// Opções apresentadas na tela de ajustes (rótulo → duração).
const Map<String, Duration> kAutoLockOptions = {
  'Somente ao sair': Duration.zero,
  '1 minuto': Duration(minutes: 1),
  '3 minutos': Duration(minutes: 3),
  '5 minutos': Duration(minutes: 5),
  '15 minutos': Duration(minutes: 15),
};
