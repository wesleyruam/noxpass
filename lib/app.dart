import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/authentication/presentation/auto_lock_scope.dart';
import 'features/settings/presentation/settings_providers.dart';
import 'routes/app_router.dart';
import 'shared/theme/app_theme.dart';

/// Widget raiz do aplicativo.
///
/// Segue o tema do sistema (claro/escuro) e delega a navegação ao GoRouter
/// injetado por Riverpod.
class NoxPassApp extends ConsumerWidget {
  const NoxPassApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'NoxPass',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(themeModeProvider),
      routerConfig: router,
      // Aplica o bloqueio automático por cima de toda a árvore de navegação.
      builder: (context, child) =>
          AutoLockScope(child: child ?? const SizedBox.shrink()),
    );
  }
}
