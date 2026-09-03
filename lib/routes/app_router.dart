import 'package:dhukuti/auth/email_verification_page.dart';
import 'package:dhukuti/auth/login_page.dart';
import 'package:dhukuti/auth/signup_page.dart';
import 'package:dhukuti/screens/main_screen.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_state.dart';
import '../routes/app_routes.dart';
import '../splash/splash_page.dart';

GoRouter createRouter(AuthState authState) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: authState,
    redirect: (context, state) {
      final phase = authState.phase;
      final loc = state.matchedLocation;

      final isSplash = loc == AppRoutes.splash;
      final isLogin = loc == AppRoutes.login;
      final isSignup = loc == AppRoutes.signup;
      final isVerify = loc == AppRoutes.verifyEmail;
      final isAuthFlow = isLogin || isSignup;

      if (phase == AuthPhase.initializing) {
        return isSplash ? null : AppRoutes.splash;
      }

      switch (phase) {
        case AuthPhase.signedOut:
          if (isSplash) return AppRoutes.login;
          if (isAuthFlow) return null;
          return AppRoutes.login;

        case AuthPhase.emailUnverified:
          if (isVerify) return null;
          return AppRoutes.verifyEmail;

        case AuthPhase.signedIn:
          if (isSplash || isAuthFlow || isVerify) {
            return AppRoutes.dashboard;
          }
          return null;

        case AuthPhase.initializing:
          return AppRoutes.splash;
      }
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
        path: AppRoutes.signup,
        builder: (context, state) => const SignupPage(),
      ),
      GoRoute(
        path: AppRoutes.verifyEmail,
        builder: (context, state) => const EmailVerificationPage(),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (context, state) => const MainScreen(),
      ),
    ],
  );
}
