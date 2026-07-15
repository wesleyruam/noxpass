import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/onboarding/presentation/welcome_page.dart';
import 'app_routes.dart';

/// Roteador raiz do NoxPass (GoRouter exposto via Riverpod).
///
/// Guardas de sessão (auto-lock, exigir cofre destravado) serão adicionadas
/// aqui via `redirect`, observando o estado de autenticação — sem alterar as
/// telas em si.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.welcomePath,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.welcomePath,
        name: AppRoutes.welcome,
        builder: (context, state) => const WelcomePage(),
      ),
    ],
  );
});
