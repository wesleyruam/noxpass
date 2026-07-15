// Parâmetros nomeados não podem ser privados; atribuição manual dos campos.
// ignore_for_file: prefer_initializing_formals

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/brute_force.dart';

/// Persiste o [LockoutState] no armazenamento seguro (sobrevive a reinícios).
abstract interface class LockoutStore {
  Future<LockoutState> read();
  Future<void> write(LockoutState state);
}

class SecureLockoutStore implements LockoutStore {
  const SecureLockoutStore(this._storage);

  final FlutterSecureStorage _storage;
  static const String _key = 'noxpass.lockout.v1';

  @override
  Future<LockoutState> read() async {
    final raw = await _storage.read(key: _key);
    return raw == null ? LockoutState.initial : LockoutState.fromJsonString(raw);
  }

  @override
  Future<void> write(LockoutState state) =>
      _storage.write(key: _key, value: state.toJsonString());
}

/// Une política e persistência: consultado pelo fluxo de desbloqueio.
class BruteForceGuard {
  const BruteForceGuard({
    required LockoutStore store,
    BruteForcePolicy policy = const BruteForcePolicy(),
    DateTime Function() clock = DateTime.now,
  })  : _store = store,
        _policy = policy,
        _clock = clock;

  final LockoutStore _store;
  final BruteForcePolicy _policy;
  final DateTime Function() _clock;

  /// Tempo restante de bloqueio, ou `null` se o desbloqueio está liberado.
  Future<Duration?> currentLockout() async =>
      _policy.remaining(await _store.read(), _clock());

  /// Registra uma tentativa incorreta.
  Future<void> recordFailure() async =>
      _store.write(_policy.onFailure(await _store.read(), _clock()));

  /// Zera o contador após um desbloqueio bem-sucedido.
  Future<void> recordSuccess() async => _store.write(_policy.reset());
}
