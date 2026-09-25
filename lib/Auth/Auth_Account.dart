// ============================================================
// ACCOUNT + USER DATA
// ============================================================

part of 'Auth_Cubit.dart';

extension AuthAccountMethods on AuthCubit {
  // ============================================================
  // UPDATE NAME
  // ============================================================

  Future<void> updateName(String name) async {
    final user = _auth.currentUser;

    if (user == null) {
      return;
    }

    try {
      final trimmedName = name.trim();

      await user.updateDisplayName(
        trimmedName,
      );

      await user.reload();

      final updatedUser =
          _auth.currentUser;

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

  // ============================================================
  // UPDATE EMAIL
  // ============================================================

  Future<void> updateEmail(
    String email,
  ) async {
    final user = _auth.currentUser;

    if (user == null) {
      return;
    }

    try {
      final trimmedEmail =
          email.trim();

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

  // ============================================================
  // UPDATE PASSWORD
  // ============================================================

  Future<void> updatePassword(
    String newPassword,
  ) async {
    final user = _auth.currentUser;

    if (user == null) {
      return;
    }

    try {
      await user.updatePassword(
        newPassword,
      );

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
  // GET USER DATA
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
      final snapshot =
          await _firestore
              .collection('users')
              .doc(user.uid)
              .get();

      if (snapshot.exists) {
        final data =
            snapshot.data();

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
        fallbackMessage:
            'Could not get user data',
      );
    } catch (e) {
      _emitFailure(
        'Get user data error: $e',
      );
    }
  }

  // ============================================================
  // CREATE / UPDATE USER DOCUMENT
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
        _firestore
            .collection('users')
            .doc(user.uid);

    final snapshot =
        await userRef.get();

    final existingData =
        snapshot.data();

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
      data['provider'] =
          provider;
    }

    await userRef.set(
      data,
      SetOptions(merge: true),
    );
  }
}