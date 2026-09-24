import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:scanly/Core/AppRouters.dart';
import 'package:scanly/Core/GoRouterRefreshStream.dart';



// ============================================================
// APP ROUTER
// ============================================================

class AppRouter {
  // ==========================================================
  // ROUTER INSTANCE
  // ==========================================================

  static final GoRouter router = GoRouter(
    // ========================================================
    // STARTING POINT
    // ========================================================

    initialLocation: '/',

    // ========================================================
    // AUTH STATE LISTENER
    // ========================================================

    refreshListenable: GoRouterRefreshStream(
      FirebaseAuth.instance.authStateChanges(),
    ),

    // ========================================================
    // AUTH REDIRECT
    // ========================================================

    redirect: _redirect,

    // ========================================================
    // ROUTES
    // ========================================================

    routes: AppRoutes.routes,
  );

  // ==========================================================
  // REDIRECT / AUTH GUARD
  // ==========================================================

  static String? _redirect(
    context,
    GoRouterState state,
  ) {
    final User? user = FirebaseAuth.instance.currentUser;
    final String location = state.uri.path;

    // ========================================================
    // ROOT
    // ========================================================

    if (location == '/') {
      if (user == null) {
        return '/login';
      }

      if (_isUnverifiedEmailUser(user)) {
        return '/verification';
      }

      return '/home';
    }

    // ========================================================
    // AUTH PAGES
    // ========================================================

    final bool isLogin = location == '/login';
    final bool isRegister = location == '/register';
    final bool isVerification = location == '/verification';
    final bool isForgotPassword =
        location == '/forgot-password-verification';
    final bool isOnboarding = location == '/onboarding';

    final bool isAuthPage =
        isLogin ||
        isRegister ||
        isVerification ||
        isForgotPassword;

    // ========================================================
    // USER NOT LOGGED IN
    // ========================================================

    if (user == null) {
      if (isAuthPage || isOnboarding) {
        return null;
      }

      return '/login';
    }

    // ========================================================
    // EMAIL USER NOT VERIFIED
    // ========================================================

    if (_isUnverifiedEmailUser(user)) {
      if (!isVerification) {
        return '/verification';
      }

      return null;
    }

    // ========================================================
    // LOGGED-IN USER TRYING AUTH PAGES
    // ========================================================

    if (isLogin || isRegister) {
      return '/home';
    }

    // ========================================================
    // ALLOW CURRENT LOCATION
    // ========================================================

    return null;
  }

  // ==========================================================
  // AUTH HELPERS
  // ==========================================================

  static bool _isEmailUser(User user) {
    return user.providerData.any(
      (provider) => provider.providerId == 'password',
    );
  }

  static bool _isUnverifiedEmailUser(User user) {
    return _isEmailUser(user) && !user.emailVerified;
  }
}