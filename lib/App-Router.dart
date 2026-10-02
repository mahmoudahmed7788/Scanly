
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:scanly/Core/AppRouters.dart';
import 'package:scanly/Core/GoRouterRefreshStream.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',

    refreshListenable: GoRouterRefreshStream(
      FirebaseAuth.instance.authStateChanges(),
    ),

    redirect: _redirect,

    routes: AppRoutes.routes,
  );

  static String? _redirect(
    BuildContext context,
    GoRouterState state,
  ) {
    final User? user =
        FirebaseAuth.instance.currentUser;

    final String location =
        state.uri.path;

    if (location == '/') {
      if (user == null) {
        return '/login';
      }

      if (_isUnverifiedEmailUser(user)) {
        return '/verification';
      }

      return '/home';
    }

    final bool isLogin =
        location == '/login';

    final bool isRegister =
        location == '/register';

    final bool isVerification =
        location == '/verification';

    final bool isForgotPassword =
        location == '/forgot-password-verification';

    final bool isResetPassword =
        location == '/reset-password';

    final bool isOnboarding =
        location == '/onboarding';

    final bool isAuthPage =
        isLogin ||
        isRegister ||
        isVerification ||
        isForgotPassword ||
        isResetPassword;

    if (user == null) {
      if (isResetPassword) {
        return null;
      }

      if (isAuthPage || isOnboarding) {
        return null;
      }

      return '/login';
    }

    if (_isUnverifiedEmailUser(user)) {
      if (isResetPassword) {
        return null;
      }

      if (!isVerification) {
        return '/verification';
      }

      return null;
    }

    if (isOnboarding) {
      return null;
    }

    if (isLogin || isRegister) {
      return '/home';
    }

    if (isForgotPassword ||
        isResetPassword) {
      return null;
    }

    if (location == '/trash') {
      return null;
    }

    return null;
  }

  static bool _isEmailUser(User user) {
    return user.providerData.any(
      (provider) =>
          provider.providerId == 'password',
    );
  }

  static bool _isUnverifiedEmailUser(
    User user,
  ) {
    return _isEmailUser(user) &&
        !user.emailVerified;
  }
}
