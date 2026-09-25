// ============================================================
// SOCIAL AUTHENTICATION
// ============================================================

part of 'Auth_Cubit.dart';

extension AuthSocialMethods on AuthCubit {
  // ============================================================
  // GOOGLE LOGIN
  // ============================================================

  Future<void> signInWithGoogle() async {
    emit(
      const AuthState(
        status: AuthStatus.loading,
      ),
    );

    try {
      debugPrint(
        'GOOGLE: Waiting for initialization...',
      );

      await _googleSignInInitialization;

      debugPrint(
        'GOOGLE: Initialization completed.',
      );

      if (!_googleSignIn.supportsAuthenticate()) {
        throw Exception(
          'Google Sign-In is not supported on this platform.',
        );
      }

      debugPrint(
        'GOOGLE: Opening account picker...',
      );

      final GoogleSignInAccount googleUser =
          await _googleSignIn.authenticate();

      debugPrint(
        'GOOGLE: Account selected: ${googleUser.email}',
      );

      final GoogleSignInAuthentication googleAuth =
          googleUser.authentication;

      final String? idToken =
          googleAuth.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw Exception(
          'Google authentication token was not received.',
        );
      }

      debugPrint(
        'GOOGLE: ID token received.',
      );

      final OAuthCredential credential =
          GoogleAuthProvider.credential(
        idToken: idToken,
      );

      debugPrint(
        'GOOGLE: Signing in to Firebase...',
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(
        credential,
      );

      final User? user =
          userCredential.user;

      if (user == null) {
        throw Exception(
          'Could not create the Google account.',
        );
      }

      debugPrint(
        'GOOGLE: Firebase login successful: ${user.email}',
      );

      try {
        await _createOrUpdateUserDocument(
          user,
          provider: 'google',
        );

        debugPrint(
          'GOOGLE: Firestore user document saved.',
        );
      } catch (e) {
        debugPrint(
          'GOOGLE: Firestore error: $e',
        );
      }

      emit(
        AuthState(
          status: AuthStatus.success,
          user: user,
        ),
      );

      debugPrint(
        'GOOGLE: AuthStatus.success emitted.',
      );
    } on GoogleSignInException catch (e) {
      debugPrint(
        'GOOGLE SIGN-IN EXCEPTION: ${e.code}',
      );

      debugPrint(
        'GOOGLE DESCRIPTION: ${e.description}',
      );

      if (e.code ==
          GoogleSignInExceptionCode.canceled) {
        emit(
          const AuthState(
            status: AuthStatus.initial,
          ),
        );

        return;
      }

      _emitFailure(
        'Google Sign-In Error: '
        '${e.code} - '
        '${e.description ?? 'Unknown error'}',
      );
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'GOOGLE FIREBASE ERROR: ${e.code}',
      );

      debugPrint(
        'GOOGLE FIREBASE MESSAGE: ${e.message}',
      );

      _emitFailure(
        'Firebase Error: '
        '${e.code} - '
        '${_getErrorMessage(e.code)}',
      );
    } catch (e) {
      debugPrint(
        'GOOGLE ERROR: $e',
      );

      _emitFailure(
        'Google Error: $e',
      );
    }
  }

  // ============================================================
  // FACEBOOK LOGIN
  // ============================================================

  Future<void> signInWithFacebook() async {
    emit(
      const AuthState(
        status: AuthStatus.loading,
      ),
    );

    try {
      debugPrint(
        'FACEBOOK: Opening Facebook login...',
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

      if (loginResult.status ==
          LoginStatus.cancelled) {
        emit(
          const AuthState(
            status: AuthStatus.initial,
          ),
        );

        return;
      }

      if (loginResult.status !=
          LoginStatus.success) {
        throw Exception(
          loginResult.message ??
              'Facebook login failed.',
        );
      }

      final AccessToken? accessToken =
          loginResult.accessToken;

      if (accessToken == null) {
        throw Exception(
          'Facebook access token was not received.',
        );
      }

      debugPrint(
        'FACEBOOK: Access token received.',
      );

      final OAuthCredential credential =
          FacebookAuthProvider.credential(
        accessToken.tokenString,
      );

      debugPrint(
        'FACEBOOK: Signing in to Firebase...',
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(
        credential,
      );

      final User? user =
          userCredential.user;

      if (user == null) {
        throw Exception(
          'Could not create the Facebook account.',
        );
      }

      debugPrint(
        'FACEBOOK: Firebase login successful.',
      );

      debugPrint(
        'FACEBOOK: UID = ${user.uid}',
      );

      debugPrint(
        'FACEBOOK: Email = ${user.email}',
      );

      try {
        await _createOrUpdateUserDocument(
          user,
          provider: 'facebook',
        );

        debugPrint(
          'FACEBOOK: Firestore user document saved.',
        );
      } catch (e) {
        debugPrint(
          'FACEBOOK: Firestore error: $e',
        );
      }

      emit(
        AuthState(
          status: AuthStatus.success,
          user: user,
        ),
      );

      debugPrint(
        'FACEBOOK: AuthStatus.success emitted.',
      );
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'FACEBOOK FIREBASE ERROR: ${e.code}',
      );

      debugPrint(
        'FACEBOOK FIREBASE MESSAGE: ${e.message}',
      );

      _emitFailure(
        'Firebase Error: '
        '${e.code} - '
        '${_getErrorMessage(e.code)}',
      );
    } catch (e) {
      debugPrint(
        'FACEBOOK ERROR: $e',
      );

      _emitFailure(
        'Facebook Error: $e',
      );
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> logout() async {
    try {
      // --------------------------------------------------------
      // GOOGLE LOGOUT
      // --------------------------------------------------------

      try {
        await _googleSignIn.signOut();
      } catch (e) {
        debugPrint(
          'Google sign out error: $e',
        );
      }

      // --------------------------------------------------------
      // FACEBOOK LOGOUT
      // --------------------------------------------------------

      try {
        await FacebookAuth.instance.logOut();
      } catch (e) {
        debugPrint(
          'Facebook logout error: $e',
        );
      }

      // --------------------------------------------------------
      // FIREBASE LOGOUT
      // --------------------------------------------------------

      await _auth.signOut();

      emit(
        const AuthState(
          status: AuthStatus.initial,
        ),
      );
    } catch (e) {
      _emitFailure(
        'Logout error: $e',
      );
    }
  }
}