import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

enum AuthStatus {
  initial,
  loading,
  success,
  failure,
}

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
      user: clearUser ? null : user ?? this.user,
    );
  }
}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(const AuthState());

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final GoogleSignIn _googleSignIn =
      GoogleSignIn.instance;

  late final Future<void> _googleSignInInitialization =
      _initializeGoogleSignIn();

  Future<void> _initializeGoogleSignIn() async {
    await _googleSignIn.initialize(
      serverClientId:
          '431969184661-jdsl5av6b1iplbhgga1jvdrfmh7dh143.apps.googleusercontent.com',
    );
  }

  User? get currentUser => _auth.currentUser;

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
      debugPrint('========================================');
      debugPrint('SCANLY REGISTER START');
      debugPrint('Email: ${email.trim()}');
      debugPrint('========================================');

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

      await _createOrUpdateUserDocument(
        user,
        name: fullName,
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        provider: 'email',
      );

      debugPrint('REGISTER SUCCESS');
      debugPrint('UID: ${user.uid}');
      debugPrint('========================================');

      emit(
        AuthState(
          status: AuthStatus.success,
          user: user,
        ),
      );
    } on FirebaseAuthException catch (e, stackTrace) {
      debugPrint('========================================');
      debugPrint('FIREBASE AUTH REGISTER ERROR');
      debugPrint('Code: ${e.code}');
      debugPrint('Message: ${e.message}');
      debugPrint('Plugin: ${e.plugin}');
      debugPrint('Details: ${e.toString()}');
      debugPrint('StackTrace: $stackTrace');
      debugPrint('========================================');

      emit(
        AuthState(
          status: AuthStatus.failure,
          errorMessage:
              'Firebase authentication error: '
              '${e.code}\n'
              '${e.message ?? 'No Firebase message'}',
        ),
      );
    } on FirebaseException catch (e, stackTrace) {
      debugPrint('========================================');
      debugPrint('FIREBASE EXCEPTION DURING REGISTER');
      debugPrint('Plugin: ${e.plugin}');
      debugPrint('Code: ${e.code}');
      debugPrint('Message: ${e.message}');
      debugPrint('Details: ${e.toString()}');
      debugPrint('StackTrace: $stackTrace');
      debugPrint('========================================');

      emit(
        AuthState(
          status: AuthStatus.failure,
          errorMessage:
              'Firebase error: '
              '${e.code}\n'
              '${e.message ?? 'No Firebase message'}',
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('========================================');
      debugPrint('REGISTER UNKNOWN ERROR');
      debugPrint('Error: $e');
      debugPrint('Type: ${e.runtimeType}');
      debugPrint('StackTrace: $stackTrace');
      debugPrint('========================================');

      emit(
        AuthState(
          status: AuthStatus.failure,
          errorMessage:
              'Register error: $e',
        ),
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

      await _createOrUpdateUserDocument(
        user,
        provider: 'email',
      );

      emit(
        AuthState(
          status: AuthStatus.success,
          user: user,
        ),
      );
    } on FirebaseAuthException catch (e, stackTrace) {
      debugPrint('LOGIN AUTH ERROR');
      debugPrint('Code: ${e.code}');
      debugPrint('Message: ${e.message}');
      debugPrint('StackTrace: $stackTrace');

      emit(
        AuthState(
          status: AuthStatus.failure,
          errorMessage:
              'Firebase authentication error: '
              '${e.code}\n'
              '${e.message ?? 'No Firebase message'}',
        ),
      );
    } on FirebaseException catch (e, stackTrace) {
      debugPrint('LOGIN FIREBASE ERROR');
      debugPrint('Code: ${e.code}');
      debugPrint('Message: ${e.message}');
      debugPrint('StackTrace: $stackTrace');

      emit(
        AuthState(
          status: AuthStatus.failure,
          errorMessage:
              'Firebase error: '
              '${e.code}\n'
              '${e.message ?? 'No Firebase message'}',
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('LOGIN UNKNOWN ERROR');
      debugPrint('Error: $e');
      debugPrint('Type: ${e.runtimeType}');
      debugPrint('StackTrace: $stackTrace');

      emit(
        AuthState(
          status: AuthStatus.failure,
          errorMessage:
              'Login error: $e',
        ),
      );
    }
  }

  Future<void> signInWithGoogle() async {
    emit(
      const AuthState(
        status: AuthStatus.loading,
      ),
    );

    try {
      await _googleSignInInitialization;

      if (!_googleSignIn.supportsAuthenticate()) {
        throw Exception(
          'Google Sign-In is not supported on this platform.',
        );
      }

      await _googleSignIn.signOut();

      final GoogleSignInAccount googleUser =
          await _googleSignIn.authenticate();

      final GoogleSignInAuthentication googleAuth =
          googleUser.authentication;

      final String? idToken = googleAuth.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw Exception(
          'Google authentication token was not received.',
        );
      }

      final credential =
          GoogleAuthProvider.credential(
        idToken: idToken,
      );

      final userCredential =
          await _auth.signInWithCredential(
        credential,
      );

      final user = userCredential.user;

      if (user == null) {
        throw Exception(
          'Could not create the Google account.',
        );
      }

      await _createOrUpdateUserDocument(
        user,
        provider: 'google',
      );

      emit(
        AuthState(
          status: AuthStatus.success,
          user: user,
        ),
      );
    } on GoogleSignInException catch (e, stackTrace) {
      debugPrint('GOOGLE SIGN-IN ERROR');
      debugPrint('Code: ${e.code}');
      debugPrint('Description: ${e.description}');
      debugPrint('StackTrace: $stackTrace');

      if (e.code ==
          GoogleSignInExceptionCode.canceled) {
        emit(
          const AuthState(
            status: AuthStatus.initial,
          ),
        );
        return;
      }

      emit(
        AuthState(
          status: AuthStatus.failure,
          errorMessage:
              'Google Sign-In Error: '
              '${e.code} - '
              '${e.description ?? 'Unknown error'}',
        ),
      );
    } on FirebaseAuthException catch (e, stackTrace) {
      debugPrint('GOOGLE FIREBASE AUTH ERROR');
      debugPrint('Code: ${e.code}');
      debugPrint('Message: ${e.message}');
      debugPrint('StackTrace: $stackTrace');

      emit(
        AuthState(
          status: AuthStatus.failure,
          errorMessage:
              'Firebase Error: '
              '${e.code} - '
              '${_getErrorMessage(e.code)}',
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('GOOGLE UNKNOWN ERROR');
      debugPrint('Error: $e');
      debugPrint('Type: ${e.runtimeType}');
      debugPrint('StackTrace: $stackTrace');

      emit(
        AuthState(
          status: AuthStatus.failure,
          errorMessage:
              'Google Error: $e',
        ),
      );
    }
  }

  Future<void> signInWithFacebook() async {
    emit(
      const AuthState(
        status: AuthStatus.loading,
      ),
    );

    try {
      final LoginResult loginResult =
          await FacebookAuth.instance.login();

      if (loginResult.status !=
          LoginStatus.success) {
        if (loginResult.status ==
            LoginStatus.cancelled) {
          emit(
            const AuthState(
              status: AuthStatus.initial,
            ),
          );
          return;
        }

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

      final OAuthCredential credential =
          FacebookAuthProvider.credential(
        accessToken.tokenString,
      );

      final userCredential =
          await _auth.signInWithCredential(
        credential,
      );

      final user = userCredential.user;

      if (user == null) {
        throw Exception(
          'Could not create the Facebook account.',
        );
      }

      await _createOrUpdateUserDocument(
        user,
        provider: 'facebook',
      );

      emit(
        AuthState(
          status: AuthStatus.success,
          user: user,
        ),
      );
    } on FirebaseAuthException catch (e, stackTrace) {
      debugPrint('FACEBOOK FIREBASE AUTH ERROR');
      debugPrint('Code: ${e.code}');
      debugPrint('Message: ${e.message}');
      debugPrint('StackTrace: $stackTrace');

      emit(
        AuthState(
          status: AuthStatus.failure,
          errorMessage:
              'Firebase Error: '
              '${e.code} - '
              '${_getErrorMessage(e.code)}',
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('FACEBOOK UNKNOWN ERROR');
      debugPrint('Error: $e');
      debugPrint('Type: ${e.runtimeType}');
      debugPrint('StackTrace: $stackTrace');

      emit(
        AuthState(
          status: AuthStatus.failure,
          errorMessage:
              'Facebook Error: $e',
        ),
      );
    }
  }

  Future<void> updateName(String name) async {
    final user = _auth.currentUser;

    if (user == null) {
      return;
    }

    try {
      await user.updateDisplayName(name.trim());

      await _createOrUpdateUserDocument(
        user,
        name: name.trim(),
      );

      emit(
        AuthState(
          status: AuthStatus.success,
          user: user,
        ),
      );
    } on FirebaseAuthException catch (e) {
      emit(
        AuthState(
          status: AuthStatus.failure,
          errorMessage:
              _getErrorMessage(e.code),
        ),
      );
    } catch (e) {
      emit(
        AuthState(
          status: AuthStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> updateEmail(String email) async {
    final user = _auth.currentUser;

    if (user == null) {
      return;
    }

    try {
      await user.verifyBeforeUpdateEmail(
        email.trim(),
      );

      await _createOrUpdateUserDocument(
        user,
        email: email.trim(),
      );

      emit(
        AuthState(
          status: AuthStatus.success,
          user: user,
        ),
      );
    } on FirebaseAuthException catch (e) {
      emit(
        AuthState(
          status: AuthStatus.failure,
          errorMessage:
              _getErrorMessage(e.code),
        ),
      );
    } catch (e) {
      emit(
        AuthState(
          status: AuthStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

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
      emit(
        AuthState(
          status: AuthStatus.failure,
          errorMessage:
              _getErrorMessage(e.code),
        ),
      );
    } catch (e) {
      emit(
        AuthState(
          status: AuthStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> getUserData() async {
    final user = _auth.currentUser;

    if (user == null) {
      return;
    }

    try {
      await user.reload();

      final refreshedUser =
          _auth.currentUser;

      emit(
        AuthState(
          status: AuthStatus.success,
          user: refreshedUser,
        ),
      );
    } catch (e) {
      emit(
        AuthState(
          status: AuthStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> resendVerificationEmail() async {
    final user = _auth.currentUser;

    if (user == null) {
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
      emit(
        AuthState(
          status: AuthStatus.failure,
          errorMessage:
              _getErrorMessage(e.code),
        ),
      );
    } catch (e) {
      emit(
        AuthState(
          status: AuthStatus.failure,
          errorMessage: e.toString(),
        ),
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

      final refreshedUser =
          _auth.currentUser;

      return refreshedUser?.emailVerified ??
          false;
    } catch (_) {
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
        const AuthState(
          status: AuthStatus.success,
        ),
      );
    } on FirebaseAuthException catch (e) {
      emit(
        AuthState(
          status: AuthStatus.failure,
          errorMessage:
              _getErrorMessage(e.code),
        ),
      );
    } catch (e) {
      emit(
        AuthState(
          status: AuthStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> logout() async {
    try {
      await _googleSignIn.signOut();

      await FacebookAuth.instance.logOut();

      await _auth.signOut();

      emit(
        const AuthState(
          status: AuthStatus.initial,
        ),
      );
    } catch (e) {
      emit(
        AuthState(
          status: AuthStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

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

    final existingData =
        snapshot.data();

    final Map<String, dynamic> data = {
      'uid': user.uid,
      'email': email ?? user.email,
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
      'emailVerified': user.emailVerified,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (!snapshot.exists) {
      data['createdAt'] =
          FieldValue.serverTimestamp();
    }

    if (provider != null) {
      data['provider'] = provider;
    }

    try {
      await userRef.set(
        data,
        SetOptions(merge: true),
      );
    } on FirebaseException catch (e, stackTrace) {
      debugPrint('========================================');
      debugPrint('FIRESTORE USER DOCUMENT ERROR');
      debugPrint('Code: ${e.code}');
      debugPrint('Plugin: ${e.plugin}');
      debugPrint('Message: ${e.message}');
      debugPrint('StackTrace: $stackTrace');
      debugPrint('========================================');

      rethrow;
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'invalid-email':
        return 'The email address is not valid.';

      case 'user-disabled':
        return 'This account has been disabled.';

      case 'user-not-found':
        return 'No account found with this email.';

      case 'wrong-password':
      case 'invalid-credential':
        return 'The email or password is incorrect.';

      case 'email-already-in-use':
        return 'This email is already in use.';

      case 'weak-password':
        return 'The password is too weak.';

      case 'operation-not-allowed':
        return 'This sign-in method is not enabled in Firebase.';

      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';

      case 'network-request-failed':
        return 'Please check your internet connection.';

      case 'requires-recent-login':
        return 'Please sign in again and try again.';

      case 'user-mismatch':
        return 'The selected account does not match.';

      case 'credential-already-in-use':
        return 'This credential is already linked to another account.';

      case 'account-exists-with-different-credential':
        return 'This email is already registered with another sign-in method.';

      case 'invalid-credential':
        return 'The authentication credential is invalid.';

      default:
        return 'Firebase authentication error: $code';
    }
  }

  @override
  Future<void> close() {
    return super.close();
  }
}