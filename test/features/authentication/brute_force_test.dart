import 'package:flutter_test/flutter_test.dart';
import 'package:noxpass/features/authentication/domain/brute_force.dart';

void main() {
  const policy = BruteForcePolicy(
    freeAttempts: 3,
    baseCooldown: Duration(seconds: 30),
    maxCooldown: Duration(minutes: 15),
  );
  final now = DateTime(2026, 7, 15, 12);

  group('BruteForcePolicy', () {
    test('as primeiras tentativas livres não bloqueiam', () {
      var state = LockoutState.initial;
      for (var i = 0; i < 3; i++) {
        state = policy.onFailure(state, now);
        expect(policy.isLocked(state, now), isFalse);
      }
      expect(state.failedAttempts, 3);
    });

    test('bloqueia após exceder o limite, com backoff exponencial', () {
      var state = LockoutState.initial;
      for (var i = 0; i < 3; i++) {
        state = policy.onFailure(state, now);
      }
      // 4ª falha: 30s
      state = policy.onFailure(state, now);
      expect(policy.remaining(state, now), const Duration(seconds: 30));
      // 5ª falha: 60s
      state = policy.onFailure(state, now);
      expect(policy.remaining(state, now), const Duration(seconds: 60));
      // 6ª falha: 120s
      state = policy.onFailure(state, now);
      expect(policy.remaining(state, now), const Duration(seconds: 120));
    });

    test('respeita o teto de bloqueio', () {
      var state = LockoutState.initial;
      for (var i = 0; i < 20; i++) {
        state = policy.onFailure(state, now);
      }
      expect(policy.remaining(state, now), const Duration(minutes: 15));
    });

    test('o bloqueio expira com o tempo', () {
      var state = LockoutState.initial;
      for (var i = 0; i < 4; i++) {
        state = policy.onFailure(state, now);
      }
      expect(policy.isLocked(state, now), isTrue);
      final later = now.add(const Duration(seconds: 31));
      expect(policy.isLocked(state, later), isFalse);
    });

    test('reset limpa o estado', () {
      final reset = policy.reset();
      expect(reset.failedAttempts, 0);
      expect(policy.isLocked(reset, now), isFalse);
    });

    test('serialização json preserva o estado', () {
      final state = LockoutState(failedAttempts: 5, lockedUntil: now);
      final restored = LockoutState.fromJsonString(state.toJsonString());
      expect(restored.failedAttempts, 5);
      expect(restored.lockedUntil, now);
    });
  });
}
