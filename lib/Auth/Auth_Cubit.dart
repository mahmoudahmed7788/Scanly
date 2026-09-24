// ============================================================
// IMPORTS
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

// ============================================================
// AUTH STATUS
// ============================================================

enum AuthStatus {
  initial,
  loading,
  success,
  failure,
}

// ============================================================
// AUTH STATE
// ============================================================

class AuthState {
  final AuthStatus status;
  final String? errorMessage;
  final User? user;

  const AuthState({
    this.status = AuthStatus.initial,
    this.errorMessage,
    this.user,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? errorMessage,
    User? user,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: clearError
          ? null
          : errorMessage ?? this.errorMessage,
      user: clearUser
          ? null
          : user ?? this.user,
    );
  }
}

// ============================================================
// AUTH CUBIT
// ============================================================

class AuthCubit extends Cubit<AuthState> {
  AuthCubit()
      : super(
          AuthState(
            status: FirebaseAuth.instance.currentUser != null
                ? AuthStatus.success
                : AuthStatus.initial,
            user: FirebaseAuth.instance.currentUser,
          ),
        ) {
    _listenToAuthChanges();
  }

  // ============================================================
  // DEPENDENCIES
  // ============================================================

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final GoogleSignIn _googleSignIn =
      GoogleSignIn.instance;

  // ============================================================
  // GOOGLE INITIALIZATION
  // ============================================================

  late final Future<void> _googleSignInInitialization =
      _initializeGoogleSignIn();

  Future<void> _initializeGoogleSignIn() async {
    await _googleSignIn.initialize(
      serverClientId:
          '431969184661-jdsl5av6b1iplbhgga1jvdrfmh7dh143.apps.googleusercontent.com',
    );
  }

  // ============================================================
  // CURRENT USER
  // ============================================================

  User? get currentUser {
    return _auth.currentUser;
  }

  // ============================================================
  // AUTH STATE LISTENER
  // ============================================================

  void _listenToAuthChanges() {
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        emit(
          AuthState(
            status: AuthStatus.success,
            user: user,
          ),
        );
      } else {
        emit(
          const AuthState(
            status: AuthStatus.initial,
          ),
        );
      }
    });
  }

  // ============================================================
  // EMAIL AUTHENTICATION
  // ============================================================

  // -------------------- REGISTER --------------------

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

  // -------------------- LOGIN --------------------

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
        throw Exception('Could not sign in.');
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
      _emitFirebaseAuthError(
        e,
        prefix: 'Firebase authentication error',
      );
    } catch (e) {
      _emitFailure(
        'Login error: $e',
      );
    }
  }

  // ============================================================
  // SOCIAL AUTHENTICATION
  // ============================================================

  // -------------------- GOOGLE LOGIN --------------------

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

      final String? idToken = googleAuth.idToken;

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

      final User? user = userCredential.user;

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

  // -------------------- FACEBOOK LOGIN --------------------

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

      final User? user = userCredential.user;

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
  // ACCOUNT UPDATES
  // ============================================================

  // -------------------- UPDATE NAME --------------------

  Future<void> updateName(String name) async {
    final user = _auth.currentUser;

    if (user == null) {
      return;
    }

    try {
      final trimmedName = name.trim();

      await user.updateDisplayName(trimmedName);

      await user.reload();

      final updatedUser = _auth.currentUser;

      if (updatedUser == null) {
        return;
      }

      try {
        await _createOrUpdateUserDocument(
          updatedUser,
          name: trimmedName,
        );
      } catch (e) {
        debugPrint(
          'UPDATE NAME FIRESTORE ERROR: $e',
        );
      }

      emit(
        AuthState(
          status: AuthStatus.success,
          user: updatedUser,
        ),
      );
    } on FirebaseAuthException catch (e) {
      _emitFirebaseAuthError(e);
    } catch (e) {
      _emitFailure(
        'Update name error: $e',
      );
    }
  }

  // -------------------- UPDATE EMAIL --------------------

  Future<void> updateEmail(String email) async {
    final user = _auth.currentUser;

    if (user == null) {
      return;
    }

    try {
      final trimmedEmail = email.trim();

      await user.verifyBeforeUpdateEmail(
        trimmedEmail,
      );

      try {
        await _createOrUpdateUserDocument(
          user,
          email: trimmedEmail,
        );
      } catch (e) {
        debugPrint(
          'UPDATE EMAIL FIRESTORE ERROR: $e',
        );
      }

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
        'Update email error: $e',
      );
    }
  }

  // -------------------- UPDATE PASSWORD --------------------

  Future<void> updatePassword(
    String newPassword,
  ) async {
    final user = _auth.currentUser;

    if (user == null) {
      return;
    }

    try {
      await user.updatePassword(newPassword);

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
        'Update password error: $e',
      );
    }
  }

  // ============================================================
  // USER DATA
  // ============================================================

  Future<void> getUserData() async {
    final user = _auth.currentUser;

    if (user == null) {
      emit(
        const AuthState(
          status: AuthStatus.initial,
        ),
      );

      return;
    }

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (snapshot.exists) {
        final data = snapshot.data();

        if (data != null) {
          debugPrint(
            'User data: $data',
          );
        }
      }

      emit(
        AuthState(
          status: AuthStatus.success,
          user: user,
        ),
      );
    } on FirebaseException catch (e) {
      _emitFirebaseError(
        e,
        prefix: 'Firebase Error',
        fallbackMessage: 'Could not get user data',
      );
    } catch (e) {
      _emitFailure(
        'Get user data error: $e',
      );
    }
  }

  // ============================================================
  // EMAIL VERIFICATION
  // ============================================================

  // -------------------- RESEND VERIFICATION --------------------

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

  // -------------------- CHECK EMAIL VERIFIED --------------------

  Future<bool> checkEmailVerified() async {
    final user = _auth.currentUser;

    if (user == null) {
      return false;
    }

    try {
      await user.reload();

      final updatedUser = _auth.currentUser;

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
  // PASSWORD RESET
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
  // LOGOUT
  // ============================================================

  Future<void> logout() async {
    try {
      // -------------------- GOOGLE LOGOUT --------------------

      try {
        await _googleSignIn.signOut();
      } catch (e) {
        debugPrint(
          'Google sign out error: $e',
        );
      }

      // -------------------- FACEBOOK LOGOUT --------------------

      try {
        await FacebookAuth.instance.logOut();
      } catch (e) {
        debugPrint(
          'Facebook logout error: $e',
        );
      }

      // -------------------- FIREBASE LOGOUT --------------------

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

  // ============================================================
  // FIRESTORE USER DOCUMENT
  // ============================================================

  Future<void> _createOrUpdateUserDocument(
    User user, {
    String? name,
    String? firstName,
    String? lastName,
    String? email,
    String? provider,
  }) async {
    final userRef =
        _firestore.collection('users').doc(user.uid);

    final snapshot = await userRef.get();

    final existingData = snapshot.data();

    final Map<String, dynamic> data = {
      'uid': user.uid,

      'email':
          email ??
          user.email ??
          existingData?['email'] ??
          '',

      'name':
          name ??
          user.displayName ??
          existingData?['name'] ??
          '',

      'firstName':
          firstName ??
          existingData?['firstName'] ??
          '',

      'lastName':
          lastName ??
          existingData?['lastName'] ??
          '',

      'photoUrl':
          user.photoURL ??
          existingData?['photoUrl'],

      'emailVerified':
          user.emailVerified,

      'updatedAt':
          FieldValue.serverTimestamp(),
    };

    if (!snapshot.exists) {
      data['createdAt'] =
          FieldValue.serverTimestamp();
    }

    if (provider != null) {
      data['provider'] = provider;
    }

    await userRef.set(
      data,
      SetOptions(merge: true),
    );
  }

  // ============================================================
  // ERROR HANDLING
  // ============================================================

  void _emitFailure(String message) {
    emit(
      AuthState(
        status: AuthStatus.failure,
        errorMessage: message,
      ),
    );
  }

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

  void _emitFirebaseError(
    FirebaseException e, {
    String prefix = 'Firebase Error',
    String fallbackMessage = 'No Firebase message',
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

  String _getErrorMessage(String code) {
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

  // ============================================================
  // CLOSE
  // ============================================================

  @override
  Future<void> close() {
    return super.close();
  }
}