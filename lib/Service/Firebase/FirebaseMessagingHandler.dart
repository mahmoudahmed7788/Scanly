// ============================================================
// FIREBASE MESSAGING BACKGROUND HANDLER
// ============================================================

import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:scanly/Models/ScanlyNotification.dart';
import 'package:shared_preferences/shared_preferences.dart';


// ============================================================
// BACKGROUND FCM HANDLER
// ============================================================

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  try {
    // ========================================================
    // FIREBASE INITIALIZATION
    // ========================================================

    await Firebase.initializeApp();

    final RemoteNotification? notification =
        message.notification;

    if (notification == null) {
      return;
    }

    // ========================================================
    // SHARED PREFERENCES
    // ========================================================

    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    final List<String> existing =
        prefs.getStringList(
              'scanly_notifications',
            ) ??
            [];

    // ========================================================
    // NOTIFICATION ID
    // ========================================================

    final String id =
        message.messageId ??
        DateTime.now()
            .millisecondsSinceEpoch
            .toString();

    // ========================================================
    // DUPLICATE CHECK
    // ========================================================

    final bool alreadyExists = existing.any(
      (item) {
        try {
          final dynamic decoded = jsonDecode(item);

          return decoded is Map &&
              decoded['id']?.toString() == id;
        } catch (_) {
          return false;
        }
      },
    );

    if (alreadyExists) {
      return;
    }

    // ========================================================
    // CREATE NOTIFICATION
    // ========================================================

    final ScanlyNotification item =
        ScanlyNotification(
      id: id,
      title: notification.title ?? 'Scanly',
      body: notification.body ?? '',
      date: DateTime.now().toIso8601String(),
    );

    // ========================================================
    // SAVE
    // ========================================================

    existing.insert(
      0,
      jsonEncode(
        item.toMap(),
      ),
    );

    // ========================================================
    // LIMIT STORAGE
    // ========================================================

    if (existing.length > 100) {
      existing.removeRange(
        100,
        existing.length,
      );
    }

    await prefs.setStringList(
      'scanly_notifications',
      existing,
    );
  } catch (e) {
    debugPrint(
      'Background notification error: $e',
    );
  }
}