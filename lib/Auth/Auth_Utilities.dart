// ============================================================
// AUTH UTILITIES
// ============================================================

part of 'Auth_Cubit.dart';

extension AuthUtilityMethods on AuthCubit {
  // ============================================================
  // EMIT FAILURE
  // ============================================================

  void _emitFailure(
    String message,
  ) {
    emit(
      AuthState(
        status: AuthStatus.failure,
        errorMessage: message,
      ),
    );
  }

  // ============================================================
  // FIREBASE AUTH ERROR
  // ============================================================

  void _emitFirebaseAuthError(
    FirebaseAuthException e, {
    String prefix = 'Firebase Error',
  }) {
    emit(
      AuthState(
        status: AuthStatus.failure,
        errorMessage:
            '$prefix: '
            '${e.code}\n'
            '${e.message ?? _getErrorMessage(e.code)}',
      ),
    );
  }

  // ============================================================
  // FIREBASE ERROR
  // ============================================================

  void _emitFirebaseError(
    FirebaseException e, {
    String prefix = 'Firebase Error',
    String fallbackMessage =
        'No Firebase message',
  }) {
    emit(
      AuthState(
        status: AuthStatus.failure,
        errorMessage:
            '$prefix: '
            '${e.code}\n'
            '${e.message ?? fallbackMessage}',
      ),
    );
  }

  // ============================================================
  // FIREBASE ERROR MESSAGES
  // ============================================================

  String _getErrorMessage(
    String code,
  ) {
    switch (code) {
      case 'invalid-email':
        return 'The email address is not valid.';

      case 'user-disabled':
        return 'This user account has been disabled.';

      case 'user-not-found':
        return 'No account was found with this email.';

      case 'wrong-password':
        return 'The password is incorrect.';

      case 'invalid-credential':
        return 'The provided login credential is invalid or expired.';

      case 'email-already-in-use':
        return 'This email is already registered.';

      case 'weak-password':
        return 'The password is too weak.';

      case 'operation-not-allowed':
        return 'This authentication method is not enabled in Firebase.';

      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';

      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';

      case 'requires-recent-login':
        return 'Please log in again before performing this action.';

      case 'account-exists-with-different-credential':
        return 'An account already exists with a different sign-in method.';

      case 'credential-already-in-use':
        return 'This credential is already being used by another account.';

      case 'provider-already-linked':
        return 'This provider is already linked to the account.';

      case 'user-token-expired':
        return 'Your session has expired. Please log in again.';

      case 'user-mismatch':
        return 'The selected account does not match the current user.';

      default:
        return 'Authentication error. Please try again.';
    }
  }
}