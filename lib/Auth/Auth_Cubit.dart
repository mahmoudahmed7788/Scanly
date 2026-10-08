import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:scanly/Core/UserProfileCache.dart';

part 'Auth_State.dart';
part 'Auth_Email.dart';
part 'Auth_Social.dart';
part 'Auth_Account.dart';
part 'Auth_Utilities.dart';

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

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final GoogleSignIn _googleSignIn =
      GoogleSignIn.instance;

  Future<void>? _googleSignInInitialization;

  Future<void> _initializeGoogleSignIn() {
    return _googleSignInInitialization ??=
        _googleSignIn.initialize(
      serverClientId:
          '431969184661-jdsl5av6b1iplbhgga1jvdrfmh7dh143.apps.googleusercontent.com',
    );
  }

  User? get currentUser {
    return _auth.currentUser;
  }

  void _listenToAuthChanges() {
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        _cacheUser(user);

        emit(
          AuthState(
            status: AuthStatus.success,
            user: user,
          ),
        );
      } else {
        UserProfileCache.clear();

        emit(
          const AuthState(
            status: AuthStatus.initial,
          ),
        );
      }
    });
  }

  Future<void> _cacheUser(User user) async {
    try {
      final displayName =
          user.displayName?.trim() ?? '';

      final email =
          user.email?.trim() ?? '';

      String? firstName;
      String? lastName;

      if (displayName.isNotEmpty) {
        final parts = displayName
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

      await UserProfileCache.saveUser(
        uid: user.uid,
        name: displayName.isNotEmpty
            ? displayName
            : null,
        firstName: firstName,
        lastName: lastName,
        email: email.isNotEmpty
            ? email
            : null,
      );
    } catch (e) {
      debugPrint(
        'USER PROFILE CACHE ERROR: $e',
      );
    }
  }

  @override
  Future<void> close() {
    return super.close();
  }
}