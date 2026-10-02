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
    // ----------------------------------------------------------
    // REAL FIREBASE ERROR -> CONSOLE ONLY
    // ----------------------------------------------------------

    debugPrint(
      '$prefix: '
      '${e.code}\n'
      '${e.message ?? 'No Firebase message'}',
    );

    // ----------------------------------------------------------
    // USER -> FRIENDLY MESSAGE ONLY
    // ----------------------------------------------------------

    emit(
      AuthState(
        status: AuthStatus.failure,
        errorMessage: _getErrorMessage(e.code),
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
        'Something went wrong. Please try again.',
  }) {
    // ----------------------------------------------------------
    // REAL FIREBASE ERROR -> CONSOLE ONLY
    // ----------------------------------------------------------

    debugPrint(
      '$prefix: '
      '${e.code}\n'
      '${e.message ?? fallbackMessage}',
    );

    // ----------------------------------------------------------
    // USER -> FRIENDLY MESSAGE ONLY
    // ----------------------------------------------------------

    emit(
      AuthState(
        status: AuthStatus.failure,
        errorMessage: _getFirebaseErrorMessage(e.code),
      ),
    );
  }

  // ============================================================
  // FIREBASE AUTH ERROR MESSAGES
  // ============================================================

  String _getErrorMessage(
    String code,
  ) {
    switch (code) {
      // --------------------------------------------------------
      // EMAIL
      // --------------------------------------------------------

      case 'invalid-email':
        return 'Please enter a valid email address.';

      // --------------------------------------------------------
      // ACCOUNT
      // --------------------------------------------------------

      case 'user-disabled':
        return 'This account has been disabled.';

      case 'user-not-found':
        return 'Email or password is incorrect.';

      // --------------------------------------------------------
      // PASSWORD
      // --------------------------------------------------------

      case 'wrong-password':
        return 'Email or password is incorrect.';

      case 'invalid-credential':
        return 'Email or password is incorrect.';

      case 'weak-password':
        return 'Your password is too weak. Please choose a stronger password.';

      // --------------------------------------------------------
      // REGISTRATION
      // --------------------------------------------------------

      case 'email-already-in-use':
        return 'This email is already registered.';

      // --------------------------------------------------------
      // AUTHENTICATION
      // --------------------------------------------------------

      case 'operation-not-allowed':
        return 'This sign-in method is currently unavailable.';

      case 'account-exists-with-different-credential':
        return 'An account already exists with this email using a different sign-in method.';

      case 'credential-already-in-use':
        return 'This sign-in credential is already linked to another account.';

      case 'provider-already-linked':
        return 'This sign-in method is already linked to your account.';

      // --------------------------------------------------------
      // SECURITY / SESSION
      // --------------------------------------------------------

      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';

      case 'requires-recent-login':
        return 'Please log in again before performing this action.';

      case 'user-token-expired':
        return 'Your session has expired. Please log in again.';

      case 'user-mismatch':
        return 'The selected account does not match the current user.';

      // --------------------------------------------------------
      // NETWORK
      // --------------------------------------------------------

      case 'network-request-failed':
        return 'Please check your internet connection and try again.';

      // --------------------------------------------------------
      // DEFAULT
      // --------------------------------------------------------

      default:
        return 'Something went wrong. Please try again.';
    }
  }

  // ============================================================
  // FIREBASE GENERAL ERROR MESSAGES
  // ============================================================

  String _getFirebaseErrorMessage(
    String code,
  ) {
    switch (code) {
      // --------------------------------------------------------
      // NETWORK
      // --------------------------------------------------------

      case 'unavailable':
        return 'The service is temporarily unavailable. Please try again.';

      case 'deadline-exceeded':
        return 'The request took too long. Please try again.';

      // --------------------------------------------------------
      // PERMISSION
      // --------------------------------------------------------

      case 'permission-denied':
        return 'You do not have permission to perform this action.';

      // --------------------------------------------------------
      // NOT FOUND
      // --------------------------------------------------------

      case 'not-found':
        return 'The requested data could not be found.';

      // --------------------------------------------------------
      // ALREADY EXISTS
      // --------------------------------------------------------

      case 'already-exists':
        return 'This data already exists.';

      // --------------------------------------------------------
      // RESOURCE EXHAUSTED
      // --------------------------------------------------------

      case 'resource-exhausted':
        return 'Too many requests. Please try again later.';

      // --------------------------------------------------------
      // UNAUTHENTICATED
      // --------------------------------------------------------

      case 'unauthenticated':
        return 'Your session has expired. Please log in again.';

      // --------------------------------------------------------
      // ABORTED
      // --------------------------------------------------------

      case 'aborted':
        return 'The operation was interrupted. Please try again.';

      // --------------------------------------------------------
      // CANCELLED
      // --------------------------------------------------------

      case 'cancelled':
        return 'The operation was cancelled.';

      // --------------------------------------------------------
      // INVALID ARGUMENT
      // --------------------------------------------------------

      case 'invalid-argument':
        return 'Invalid information was provided.';

      // --------------------------------------------------------
      // FAILED PRECONDITION
      // --------------------------------------------------------

      case 'failed-precondition':
        return 'This action cannot be completed right now.';

      // --------------------------------------------------------
      // DEFAULT
      // --------------------------------------------------------

      default:
        return 'Something went wrong. Please try again.';
    }
  }
}