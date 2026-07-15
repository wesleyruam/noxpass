import 'dart:convert';

/// Estado persistente de tentativas de desbloqueio (resiste a reinícios do app,
/// impedindo que fechar/abrir zere o contador).
class LockoutState {
  const LockoutState({this.failedAttempts = 0, this.lockedUntil});

  factory LockoutState.fromJson(Map<String, dynamic> json) => LockoutState(
        failedAttempts: json['failed'] as int? ?? 0,
        lockedUntil: switch (json['until']) {
          final int ms => DateTime.fromMillisecondsSinceEpoch(ms),
          _ => null,
        },
      );

  final int failedAttempts;
  final DateTime? lockedUntil;

  static const LockoutState initial = LockoutState();

  Map<String, dynamic> toJson() => {
        'failed': failedAttempts,
        'until': lockedUntil?.millisecondsSinceEpoch,
      };

  String toJsonString() => jsonEncode(toJson());
  static LockoutState fromJsonString(String s) =>
      LockoutState.fromJson(jsonDecode(s) as Map<String, dynamic>);
}

/// Política de proteção contra força bruta na senha mestra.
///
/// As primeiras [freeAttempts] tentativas erradas não bloqueiam; a partir daí,
/// cada erro impõe uma espera crescente (backoff exponencial), até [maxCooldown].
class BruteForcePolicy {
  const BruteForcePolicy({
    this.freeAttempts = 4,
    this.baseCooldown = const Duration(seconds: 30),
    this.maxCooldown = const Duration(minutes: 15),
  });

  final int freeAttempts;
  final Duration baseCooldown;
  final Duration maxCooldown;

  /// Registra uma falha e devolve o novo estado.
  LockoutState onFailure(LockoutState current, DateTime now) {
    final attempts = current.failedAttempts + 1;
    if (attempts <= freeAttempts) {
      return LockoutState(failedAttempts: attempts);
    }
    final overBy = attempts - freeAttempts; // 1, 2, 3, ...
    final factor = 1 << (overBy - 1); // 2^(overBy-1)
    var cooldown = baseCooldown * factor;
    if (cooldown > maxCooldown) cooldown = maxCooldown;
    return LockoutState(
      failedAttempts: attempts,
      lockedUntil: now.add(cooldown),
    );
  }

  /// Estado limpo após um desbloqueio bem-sucedido.
  LockoutState reset() => LockoutState.initial;

  /// Tempo restante de bloqueio, ou `null` se liberado.
  Duration? remaining(LockoutState state, DateTime now) {
    final until = state.lockedUntil;
    if (until == null || !until.isAfter(now)) return null;
    return until.difference(now);
  }

  bool isLocked(LockoutState state, DateTime now) =>
      remaining(state, now) != null;
}
