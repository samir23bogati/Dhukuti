import 'package:dhukuti/auth/login_page.dart';

import 'package:go_router/go_router.dart';
import '../routes/app_routes.dart';
import '../splash/splash_page.dart';
import '../auth/auth_state.dart';
import 'package:dhukuti/screens/main_screen.dart';

GoRouter createRouter(AuthState authState) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: authState,

    redirect: (context, state) {
      final loggedIn = authState.isLoggedIn;
      final loggingIn = state.matchedLocation == AppRoutes.login;

      if (!loggedIn && state.matchedLocation == AppRoutes.dashboard) {
        return AppRoutes.login;
      }

      if (loggedIn && loggingIn) {
        return AppRoutes.dashboard;
      }

      // 🚀 Skip splash if already logged in
      if (loggedIn && state.matchedLocation == AppRoutes.splash) {
        return AppRoutes.dashboard;
      }

      return null;
    },

    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),


      GoRoute(
        path: AppRoutes.dashboard,
        builder: (context, state) => const MainScreen(),
      ),
    ],
  );
}
