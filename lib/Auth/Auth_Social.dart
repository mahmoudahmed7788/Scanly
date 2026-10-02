part of 'Auth_Cubit.dart';

extension AuthSocialMethods on AuthCubit {
  Future<void> signInWithGoogle() async {
    await _handleGoogleAuthentication(
      isRegistering: false,
    );
  }

  Future<void> registerWithGoogle() async {
    await _handleGoogleAuthentication(
      isRegistering: true,
    );
  }

  Future<void> _handleGoogleAuthentication({
    required bool isRegistering,
  }) async {
    emit(const AuthState(status: AuthStatus.loading));

    try {
      debugPrint(
        'GOOGLE: ${isRegistering ? 'REGISTER' : 'LOGIN'} started.',
      );

      await _googleSignInInitialization;

      if (!_googleSignIn.supportsAuthenticate()) {
        throw Exception(
          'Google Sign-In is not supported on this platform.',
        );
      }

      debugPrint('GOOGLE: Opening account picker...');

      final GoogleSignInAccount googleUser =
          await _googleSignIn.authenticate();

      debugPrint(
        'GOOGLE: Account selected: ${googleUser.email}',
      );

      final GoogleSignInAuthentication googleAuth =
          googleUser.authentication;

      final String? idToken = googleAuth.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw Exception(
          'Google authentication token was not received.',
        );
      }

      final OAuthCredential credential =
          GoogleAuthProvider.credential(
        idToken: idToken,
      );

      debugPrint('GOOGLE: Signing in to Firebase...');

      final UserCredential userCredential =
          await _auth.signInWithCredential(
        credential,
      );

      final User? user = userCredential.user;

      if (user == null) {
        throw Exception(
          'Could not authenticate with Google.',
        );
      }

      debugPrint(
        'GOOGLE: Firebase authentication successful.',
      );

      final DocumentSnapshot<Map<String, dynamic>> userDocument =
          await _firestore
              .collection('users')
              .doc(user.uid)
              .get();

      final bool isRegistered = userDocument.exists;

      debugPrint(
        'GOOGLE: Scanly account exists = $isRegistered',
      );

      if (!isRegistering) {
        if (!isRegistered) {
          debugPrint(
            'GOOGLE: Account is not registered in Scanly.',
          );

          await _signOutSocialUser();

          emit(
            const AuthState(
              status: AuthStatus.notRegistered,
            ),
          );

          return;
        }

        emit(
          AuthState(
            status: AuthStatus.success,
            user: user,
          ),
        );

        return;
      }

      if (isRegistered) {
        debugPrint(
          'GOOGLE: Account is already registered in Scanly.',
        );

        await _signOutSocialUser();

        emit(
          const AuthState(
            status: AuthStatus.alreadyRegistered,
          ),
        );

        return;
      }

      await _createOrUpdateUserDocument(
        user,
        provider: 'google',
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

      debugPrint(
        'GOOGLE: New Scanly account created.',
      );

      emit(
        AuthState(
          status: AuthStatus.success,
          user: user,
        ),
      );
    } on GoogleSignInException catch (e) {
      debugPrint(
        'GOOGLE SIGN-IN EXCEPTION: ${e.code}',
      );

      debugPrint(
        'GOOGLE DESCRIPTION: ${e.description}',
      );

      if (e.code == GoogleSignInExceptionCode.canceled) {
        emit(
          const AuthState(
            status: AuthStatus.initial,
          ),
        );

        return;
      }

      _emitFailure(
        'Google sign-in failed. Please try again.',
      );
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'GOOGLE FIREBASE ERROR: ${e.code}',
      );

      debugPrint(
        'GOOGLE FIREBASE MESSAGE: ${e.message}',
      );

      _emitFirebaseAuthError(
        e,
        prefix: 'GOOGLE FIREBASE ERROR',
      );
    } catch (e) {
      debugPrint(
        'GOOGLE ERROR: $e',
      );

      _emitFailure(
        'Google sign-in failed. Please try again.',
      );
    }
  }

  Future<void> signInWithFacebook() async {
    await _handleFacebookAuthentication(
      isRegistering: false,
    );
  }

  Future<void> registerWithFacebook() async {
    await _handleFacebookAuthentication(
      isRegistering: true,
    );
  }

  Future<void> _handleFacebookAuthentication({
    required bool isRegistering,
  }) async {
    emit(const AuthState(status: AuthStatus.loading));

    try {
      debugPrint(
        'FACEBOOK: ${isRegistering ? 'REGISTER' : 'LOGIN'} started.',
      );

      final LoginResult loginResult =
          await FacebookAuth.instance.login(
        permissions: <String>[
          'public_profile',
          'email',
        ],
      );

      debugPrint(
        'FACEBOOK: Login status: ${loginResult.status}',
      );

      debugPrint(
        'FACEBOOK: Login message: ${loginResult.message}',
      );

      if (loginResult.status == LoginStatus.cancelled) {
        emit(
          const AuthState(
            status: AuthStatus.initial,
          ),
        );

        return;
      }

      if (loginResult.status != LoginStatus.success) {
        _emitFailure(
          'Facebook sign-in failed. Please try again.',
        );

        return;
      }

      final AccessToken? accessToken =
          loginResult.accessToken;

      if (accessToken == null) {
        _emitFailure(
          'Facebook sign-in failed. Please try again.',
        );

        return;
      }

      debugPrint(
        'FACEBOOK: Access token received.',
      );

      final OAuthCredential credential =
          FacebookAuthProvider.credential(
        accessToken.tokenString,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(
        credential,
      );

      final User? user = userCredential.user;

      if (user == null) {
        _emitFailure(
          'Facebook sign-in failed. Please try again.',
        );

        return;
      }

      debugPrint(
        'FACEBOOK: Firebase authentication successful.',
      );

      debugPrint(
        'FACEBOOK: UID = ${user.uid}',
      );

      debugPrint(
        'FACEBOOK: Email = ${user.email}',
      );

      final DocumentSnapshot<Map<String, dynamic>> userDocument =
          await _firestore
              .collection('users')
              .doc(user.uid)
              .get();

      final bool isRegistered = userDocument.exists;

      debugPrint(
        'FACEBOOK: Scanly account exists = $isRegistered',
      );

      if (!isRegistering) {
        if (!isRegistered) {
          debugPrint(
            'FACEBOOK: Account is not registered in Scanly.',
          );

          await _signOutSocialUser();

          emit(
            const AuthState(
              status: AuthStatus.notRegistered,
            ),
          );

          return;
        }

        emit(
          AuthState(
            status: AuthStatus.success,
            user: user,
          ),
        );

        return;
      }

      if (isRegistered) {
        debugPrint(
          'FACEBOOK: Account is already registered in Scanly.',
        );

        await _signOutSocialUser();

        emit(
          const AuthState(
            status: AuthStatus.alreadyRegistered,
          ),
        );

        return;
      }

      await _createOrUpdateUserDocument(
        user,
        provider: 'facebook',
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

      debugPrint(
        'FACEBOOK: New Scanly account created.',
      );

      emit(
        AuthState(
          status: AuthStatus.success,
          user: user,
        ),
      );
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'FACEBOOK FIREBASE ERROR: ${e.code}',
      );

      debugPrint(
        'FACEBOOK FIREBASE MESSAGE: ${e.message}',
      );

      _emitFirebaseAuthError(
        e,
        prefix: 'FACEBOOK FIREBASE ERROR',
      );
    } catch (e) {
      debugPrint(
        'FACEBOOK ERROR: $e',
      );

      _emitFailure(
        'Facebook sign-in failed. Please try again.',
      );
    }
  }

  Future<void> _signOutSocialUser() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint(
        'Firebase social sign out error: $e',
      );
    }

    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint(
        'Google sign out error: $e',
      );
    }

    try {
      await FacebookAuth.instance.logOut();
    } catch (e) {
      debugPrint(
        'Facebook logout error: $e',
      );
    }
  }

  Future<void> logout() async {
    try {
      try {
        await _googleSignIn.signOut();
      } catch (e) {
        debugPrint(
          'Google sign out error: $e',
        );
      }

      try {
        await FacebookAuth.instance.logOut();
      } catch (e) {
        debugPrint(
          'Facebook logout error: $e',
        );
      }

      await _auth.signOut();

      emit(
        const AuthState(
          status: AuthStatus.initial,
        ),
      );
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'LOGOUT FIREBASE ERROR: ${e.code}',
      );

      debugPrint(
        'LOGOUT FIREBASE MESSAGE: ${e.message}',
      );

      _emitFirebaseAuthError(
        e,
        prefix: 'LOGOUT FIREBASE ERROR',
      );
    } catch (e) {
      debugPrint(
        'LOGOUT ERROR: $e',
      );

      _emitFailure(
        'Logout failed. Please try again.',
      );
    }
  }
}
