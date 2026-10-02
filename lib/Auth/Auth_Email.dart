// ============================================================
// EMAIL AUTHENTICATION
// ============================================================

part of 'Auth_Cubit.dart';

// ============================================================
// REGISTER
// ============================================================

extension AuthEmailMethods on AuthCubit {
  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    emit(
      const AuthState(
        status: AuthStatus.loading,
      ),
    );

    try {
      final userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = userCredential.user;

      if (user == null) {
        throw Exception(
          'Firebase created the account but returned no user.',
        );
      }

      final fullName =
          '${firstName.trim()} ${lastName.trim()}'.trim();

      await user.updateDisplayName(fullName);

      await user.sendEmailVerification();

      try {
        await _createOrUpdateUserDocument(
          user,
          name: fullName,
          firstName: firstName.trim(),
          lastName: lastName.trim(),
          provider: 'email',
        );
      } catch (e) {
        debugPrint(
          'REGISTER FIRESTORE ERROR: $e',
        );
      }

      emit(
        AuthState(
          status: AuthStatus.success,
          user: user,
        ),
      );
    } on FirebaseAuthException catch (e) {
      _emitFirebaseAuthError(
        e,
        prefix: 'Firebase authentication error',
      );
    } on FirebaseException catch (e) {
      _emitFirebaseError(
        e,
        prefix: 'Firebase error',
      );
    } catch (e) {
      _emitFailure(
        'Register error: $e',
      );
    }
  }

  // ============================================================
  // LOGIN
  // ============================================================

  Future<void> login({
    required String email,
    required String password,
  }) async {
    emit(
      const AuthState(
        status: AuthStatus.loading,
      ),
    );

    try {
      final userCredential =
          await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = userCredential.user;

      if (user == null) {
        throw Exception(
          'Could not sign in.',
        );
      }

      try {
        await _createOrUpdateUserDocument(
          user,
          provider: 'email',
        );
      } catch (e) {
        debugPrint(
          'LOGIN FIRESTORE ERROR: $e',
        );
      }

      emit(
        AuthState(
          status: AuthStatus.success,
          user: user,
        ),
      );
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'LOGIN FIREBASE ERROR: ${e.code} - ${e.message}',
      );

      if (e.code == 'user-not-found') {
        emit(
          AuthState(
            status: AuthStatus.notRegistered,
            errorMessage:
                'This account is not registered. Please create an account first.',
            errorCode: e.code,
          ),
        );

        return;
      }

      emit(
        AuthState(
          status: AuthStatus.failure,
          errorMessage: e.message ??
              'Authentication failed.',
          errorCode: e.code,
        ),
      );
    } catch (e) {
      _emitFailure(
        'Login error: $e',
      );
    }
  }

  // ============================================================
  // RESEND VERIFICATION
  // ============================================================

  Future<void> resendVerificationEmail() async {
    final user = _auth.currentUser;

    if (user == null) {
      _emitFailure(
        'No authenticated user.',
      );

      return;
    }

    try {
      await user.sendEmailVerification();

      emit(
        AuthState(
          status: AuthStatus.success,
          user: user,
        ),
      );
    } on FirebaseAuthException catch (e) {
      _emitFirebaseAuthError(e);
    } catch (e) {
      _emitFailure(
        'Verification email error: $e',
      );
    }
  }

  // ============================================================
  // CHECK EMAIL VERIFIED
  // ============================================================

  Future<bool> checkEmailVerified() async {
    final user = _auth.currentUser;

    if (user == null) {
      return false;
    }

    try {
      await user.reload();

      final updatedUser =
          _auth.currentUser;

      if (updatedUser == null) {
        return false;
      }

      emit(
        AuthState(
          status: AuthStatus.success,
          user: updatedUser,
        ),
      );

      return updatedUser.emailVerified;
    } catch (e) {
      debugPrint(
        'Check email verification error: $e',
      );

      return false;
    }
  }

  // ============================================================
  // SEND PASSWORD RESET EMAIL
  // ============================================================

  Future<void> sendPasswordResetEmail(
    String email,
  ) async {
    emit(
      const AuthState(
        status: AuthStatus.loading,
      ),
    );

    try {
      await _auth.sendPasswordResetEmail(
        email: email.trim(),
      );

      emit(
        AuthState(
          status: AuthStatus.success,
          user: _auth.currentUser,
        ),
      );
    } on FirebaseAuthException catch (e) {
      _emitFirebaseAuthError(e);
    } catch (e) {
      _emitFailure(
        'Password reset error: $e',
      );
    }
  }

  // ============================================================
  // VERIFY PASSWORD RESET CODE
  // ============================================================

  Future<String?> verifyPasswordResetCode(
    String code,
  ) async {
    try {
      final email =
          await _auth.verifyPasswordResetCode(
        code,
      );

      debugPrint(
        'PASSWORD RESET CODE VERIFIED FOR: $email',
      );

      return email;
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'VERIFY PASSWORD RESET CODE ERROR: '
        '${e.code} - ${e.message}',
      );

      return null;
    } catch (e) {
      debugPrint(
        'VERIFY PASSWORD RESET CODE ERROR: $e',
      );

      return null;
    }
  }

  // ============================================================
  // CONFIRM PASSWORD RESET
  // ============================================================

  Future<bool> confirmPasswordReset({
    required String code,
    required String newPassword,
  }) async {
    emit(
      const AuthState(
        status: AuthStatus.loading,
      ),
    );

    try {
      await _auth.confirmPasswordReset(
        code: code,
        newPassword: newPassword,
      );

      debugPrint(
        'PASSWORD RESET: Password updated successfully.',
      );

      emit(
        AuthState(
          status: AuthStatus.success,
          user: _auth.currentUser,
        ),
      );

      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'CONFIRM PASSWORD RESET ERROR: '
        '${e.code} - ${e.message}',
      );

      _emitFirebaseAuthError(e);

      return false;
    } catch (e) {
      debugPrint(
        'CONFIRM PASSWORD RESET ERROR: $e',
      );

      _emitFailure(
        'Password reset error: $e',
      );

      return false;
    }
  }
}