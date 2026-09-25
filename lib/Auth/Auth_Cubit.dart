// ============================================================
// AUTH CUBIT - MAIN
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

part 'Auth_State.dart';
part 'Auth_Email.dart';
part 'Auth_Social.dart';
part 'Auth_Account.dart';
part 'Auth_Utilities.dart';

// ============================================================
// AUTH CUBIT
// ============================================================

class AuthCubit extends Cubit<AuthState> {
  AuthCubit()
      : super(
          AuthState(
            status:
                FirebaseAuth.instance.currentUser != null
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

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final GoogleSignIn _googleSignIn =
      GoogleSignIn.instance;

  // ============================================================
  // GOOGLE INITIALIZATION
  // ============================================================

  late final Future<void>
      _googleSignInInitialization =
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
  // CLOSE
  // ============================================================

  @override
  Future<void> close() {
    return super.close();
  }
}