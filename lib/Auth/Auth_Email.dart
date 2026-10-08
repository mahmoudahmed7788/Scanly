part of 'Auth_Cubit.dart';

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

      final cleanFirstName = firstName.trim();
      final cleanLastName = lastName.trim();

      final fullName =
          '$cleanFirstName $cleanLastName'.trim();

      await user.updateDisplayName(fullName);

      await UserProfileCache.saveUser(
        uid: user.uid,
        name: fullName,
        firstName: cleanFirstName,
        lastName: cleanLastName,
        email: user.email,
      );

      await UserProfileCache.setOnboardingCompleted(false);

      await user.sendEmailVerification();

      try {
        await _createOrUpdateUserDocument(
          user,
          name: fullName,
          firstName: cleanFirstName,
          lastName: cleanLastName,
          provider: 'email',
        );

        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(
          {
            'onboardingCompleted': false,
          },
          SetOptions(merge: true),
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

      await _cacheLoggedInUser(user);

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
          errorMessage:
              e.message ?? 'Authentication failed.',
          errorCode: e.code,
        ),
      );
    } catch (e) {
      _emitFailure(
        'Login error: $e',
      );
    }
  }

  Future<void> _cacheLoggedInUser(
    User user,
  ) async {
    try {
      String? name;
      String? firstName;
      String? lastName;
      bool onboardingCompleted = false;

      final authName =
          user.displayName?.trim() ?? '';

      if (authName.isNotEmpty) {
        name = authName;

        final parts = authName
            .split(' ')
            .where(
              (part) => part.trim().isNotEmpty,
            )
            .toList();

        if (parts.isNotEmpty) {
          firstName = parts.first;
        }

        if (parts.length > 1) {
          lastName =
              parts.sublist(1).join(' ').trim();
        }
      }

      try {
        final document =
            await _firestore
                .collection('users')
                .doc(user.uid)
                .get();

        final data = document.data();

        if (data != null) {
          final firestoreName =
              data['name']?.toString().trim() ?? '';

          final firestoreFirstName =
              data['firstName']?.toString().trim() ?? '';

          final firestoreLastName =
              data['lastName']?.toString().trim() ?? '';

          if (firestoreName.isNotEmpty) {
            name = firestoreName;
          }

          if (firestoreFirstName.isNotEmpty) {
            firstName = firestoreFirstName;
          }

          if (firestoreLastName.isNotEmpty) {
            lastName = firestoreLastName;
          }

          if ((name == null || name!.isEmpty) &&
              firstName != null &&
              firstName!.isNotEmpty) {
            name = [
              firstName,
              if (lastName != null &&
                  lastName!.isNotEmpty)
                lastName,
            ].join(' ');
          }

          final onboardingValue =
              data['onboardingCompleted'];

          if (onboardingValue is bool) {
            onboardingCompleted =
                onboardingValue;
          }
        }
      } catch (e) {
        debugPrint(
          'LOGIN PROFILE FETCH ERROR: $e',
        );
      }

      await UserProfileCache.saveUser(
        uid: user.uid,
        name: name,
        firstName: firstName,
        lastName: lastName,
        email: user.email,
      );

      await UserProfileCache.setOnboardingCompleted(
        onboardingCompleted,
      );
    } catch (e) {
      debugPrint(
        'LOGIN USER PROFILE CACHE ERROR: $e',
      );
    }
  }

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