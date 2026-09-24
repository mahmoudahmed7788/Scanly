import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';

class DocumentHiveService {
  DocumentHiveService._();

  static const String boxPrefix = 'scanly_documents_';

  static bool initialized = false;
  static String? activeUid;
  static Box? activeBox;
  static bool authListenerStarted = false;

  // =========================================================
  // INITIALIZE
  // =========================================================

  static Future<void> init() async {
    if (!initialized) {
      await Hive.initFlutter();
      initialized = true;
    }

    if (!authListenerStarted) {
      authListenerStarted = true;

      FirebaseAuth.instance.authStateChanges().listen(
        (user) async {
          try {
            if (user == null) {
              activeUid = null;
              activeBox = null;

              print(
                'DocumentStorage: user logged out.',
              );

              return;
            }

            await switchUser(user.uid);
          } catch (e) {
            print(
              'DocumentStorage auth sync error: $e',
            );
          }
        },
      );
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      await switchUser(user.uid);
    }
  }

  // =========================================================
  // SWITCH USER
  // =========================================================

  static Future<void> switchUser(String uid) async {
    if (uid.isEmpty) {
      return;
    }

    if (activeUid == uid &&
        activeBox != null &&
        activeBox!.isOpen) {
      return;
    }

    final boxName = '$boxPrefix$uid';

    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox(boxName);
    }

    activeUid = uid;
    activeBox = Hive.box(boxName);

    print(
      'DocumentStorage: switched to user $uid',
    );
  }

  // =========================================================
  // CURRENT USER BOX
  // =========================================================

  static Box? get box {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return null;
    }

    if (activeUid != user.uid) {
      return null;
    }

    if (activeBox == null ||
        !activeBox!.isOpen) {
      return null;
    }

    return activeBox;
  }
}