// ============================================================
// FIREBASE USER SERVICE
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


// ============================================================
// FIREBASE USER SERVICE
// ============================================================

class FirebaseUserService {
  // ==========================================================
  // FIREBASE
  // ==========================================================

  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static FirebaseAuth get _auth {
    return FirebaseAuth.instance;
  }

  // ==========================================================
  // CURRENT USER
  // ==========================================================

  static User? get currentUser {
    return _auth.currentUser;
  }

  static String? get uid {
    return _auth.currentUser?.uid;
  }

  // ==========================================================
  // USER REFERENCE
  // ==========================================================

  static DocumentReference<Map<String, dynamic>>? get userReference {
    final User? user = _auth.currentUser;

    if (user == null) {
      return null;
    }

    return _firestore
        .collection('users')
        .doc(user.uid);
  }

  // ==========================================================
  // ENSURE USER DOCUMENT
  // ==========================================================

  static Future<void> ensureUserDocument() async {
    final User? user = _auth.currentUser;

    if (user == null) {
      return;
    }

    final DocumentReference<Map<String, dynamic>> reference =
        _firestore
            .collection('users')
            .doc(user.uid);

    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await reference.get();

    final Map<String, dynamic> data = {
      'uid': user.uid,
      'email': user.email,
      'name': user.displayName ?? '',
      'photoUrl': user.photoURL,
      'emailVerified': user.emailVerified,
      'lastLoginAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // ========================================================
    // FIRST USER CREATION
    // ========================================================

    if (!snapshot.exists) {
      data['createdAt'] = FieldValue.serverTimestamp();
    }

    // ========================================================
    // SAVE USER
    // ========================================================

    await reference.set(
      data,
      SetOptions(
        merge: true,
      ),
    );
  }
}