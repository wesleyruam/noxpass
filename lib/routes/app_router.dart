import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/authentication/domain/auth_state.dart';
import '../features/authentication/presentation/auth_controller.dart';
import '../features/authentication/presentation/pages/create_master_password_page.dart';
import '../features/authentication/presentation/pages/splash_page.dart';
import '../features/authentication/presentation/pages/unlock_page.dart';
import '../features/security/presentation/pages/security_report_page.dart';
import '../features/settings/presentation/pages/settings_page.dart';
import '../features/vault/presentation/pages/home_page.dart';
import '../features/vault/presentation/pages/trash_page.dart';
import 'app_routes.dart';

/// Roteador raiz do NoxPass, com guardas de sessão baseadas no estado de
/// autenticação: o usuário é sempre levado à tela coerente com o cofre
/// (cadastro / desbloqueio / conteúdo).
final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.onDispose(refresh.dispose);
  ref.listen(authControllerProvider, (_, _) => refresh.value++);

  return GoRouter(
    initialLocation: AppRoutes.splashPath,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider).valueOrNull;
      final location = state.matchedLocation;

      // Ainda verificando se há cofre cadastrado: mantém na splash.
      if (auth == null) {
        return location == AppRoutes.splashPath ? null : AppRoutes.splashPath;
      }

      return switch (auth.status) {
        VaultStatus.unregistered =>
          location == AppRoutes.createPath ? null : AppRoutes.createPath,
        VaultStatus.locked =>
          location == AppRoutes.unlockPath ? null : AppRoutes.unlockPath,
        VaultStatus.unlocked => _isGate(location) ? AppRoutes.homePath : null,
      };
    },
    routes: [
      GoRoute(
        path: AppRoutes.splashPath,
        name: AppRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.createPath,
        name: AppRoutes.create,
        builder: (context, state) => const CreateMasterPasswordPage(),
      ),
      GoRoute(
        path: AppRoutes.unlockPath,
        name: AppRoutes.unlock,
        builder: (context, state) => const UnlockPage(),
      ),
      GoRoute(
        path: AppRoutes.homePath,
        name: AppRoutes.home,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: AppRoutes.securityPath,
        name: AppRoutes.security,
        builder: (context, state) => const SecurityReportPage(),
      ),
      GoRoute(
        path: AppRoutes.settingsPath,
        name: AppRoutes.settings,
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: AppRoutes.trashPath,
        name: AppRoutes.trash,
        builder: (context, state) => const TrashPage(),
      ),
    ],
  );
});

/// Telas de "portão" (pré-cofre) das quais um cofre destravado deve sair.
bool _isGate(String location) =>
    location == AppRoutes.splashPath ||
    location == AppRoutes.createPath ||
    location == AppRoutes.unlockPath;
