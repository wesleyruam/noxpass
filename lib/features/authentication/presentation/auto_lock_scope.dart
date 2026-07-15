import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/session/vault_session.dart';
import '../../settings/presentation/settings_providers.dart';
import 'auth_controller.dart';

/// Envolve o app aplicando o bloqueio automático do cofre.
///
/// Trava quando:
///  - o app vai para segundo plano (paused/hidden); e
///  - decorre o tempo de inatividade configurado (reiniciado a cada toque).
class AutoLockScope extends ConsumerStatefulWidget {
  const AutoLockScope({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<AutoLockScope> createState() => _AutoLockScopeState();
}

class _AutoLockScopeState extends ConsumerState<AutoLockScope>
    with WidgetsBindingObserver {
  Timer? _inactivityTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _inactivityTimer?.cancel();
    super.dispose();
  }

  void _restartInactivityTimer() {
    _inactivityTimer?.cancel();
    if (!ref.read(isVaultUnlockedProvider)) return;
    final timeout = ref.read(autoLockTimeoutProvider);
    if (timeout <= Duration.zero) return; // só trava ao sair
    _inactivityTimer = Timer(timeout, _lock);
  }

  void _lock() {
    _inactivityTimer?.cancel();
    if (ref.read(isVaultUnlockedProvider)) {
      unawaited(ref.read(authControllerProvider.notifier).lock());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _lock();
      case AppLifecycleState.resumed:
        _restartInactivityTimer();
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // (Re)inicia ou cancela o timer conforme o cofre destrava/trava.
    ref.listen(isVaultUnlockedProvider, (_, unlocked) {
      if (unlocked) {
        _restartInactivityTimer();
      } else {
        _inactivityTimer?.cancel();
      }
    });

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _restartInactivityTimer(),
      onPointerMove: (_) => _restartInactivityTimer(),
      child: widget.child,
    );
  }
}
