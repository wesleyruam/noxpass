import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/data/auth_data_providers.dart';

/// Preferência de tema (claro/escuro/sistema), persistida no armazenamento
/// seguro. Não é dado sensível, mas reusa o mesmo storage (sem nova dep).
final themeModeProvider =
    NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);

class ThemeModeController extends Notifier<ThemeMode> {
  static const _key = 'pref.themeMode';

  @override
  ThemeMode build() {
    // Carrega de forma assíncrona; até lá, segue o sistema. O flash não
    // aparece porque a splash é sempre escura.
    _load();
    return ThemeMode.system;
  }

  Future<void> _load() async {
    final raw = await ref.read(secureStorageProvider).read(key: _key);
    final mode = switch (raw) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => null,
    };
    if (mode != null) state = mode;
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await ref
        .read(secureStorageProvider)
        .write(key: _key, value: mode.name);
  }
}

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
