// ============================================================
// NOTIFICATION STORAGE SERVICE
// ============================================================

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:scanly/Models/ScanlyNotification.dart';
import 'package:shared_preferences/shared_preferences.dart';



// ============================================================
// NOTIFICATION STORAGE SERVICE
// ============================================================

class NotificationStorageService {
  // ==========================================================
  // KEYS
  // ==========================================================

  static const String notificationsKey =
      'scanly_notifications';

  static const String enabledKey =
      'notifications_enabled';

  // ==========================================================
  // MAX NOTIFICATIONS
  // ==========================================================

  static const int maxNotifications = 100;

  // ==========================================================
  // GET NOTIFICATIONS
  // ==========================================================

  static Future<List<ScanlyNotification>>
      getNotifications() async {
    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    final List<String> data =
        prefs.getStringList(
              notificationsKey,
            ) ??
            [];

    final List<ScanlyNotification> notifications = [];

    for (final String item in data) {
      try {
        final dynamic decoded = jsonDecode(item);

        if (decoded is Map) {
          notifications.add(
            ScanlyNotification.fromMap(
              Map<String, dynamic>.from(
                decoded,
              ),
            ),
          );
        }
      } catch (e) {
        debugPrint(
          'Notification parsing error: $e',
        );
      }
    }

    return notifications;
  }

  // ==========================================================
  // SAVE NOTIFICATIONS
  // ==========================================================

  static Future<void> saveNotifications(
    List<ScanlyNotification> notifications,
  ) async {
    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    final List<String> data =
        notifications
            .take(maxNotifications)
            .map(
              (notification) => jsonEncode(
                notification.toMap(),
              ),
            )
            .toList();

    await prefs.setStringList(
      notificationsKey,
      data,
    );
  }

  // ==========================================================
  // ADD NOTIFICATION
  // ==========================================================

  static Future<void> addNotification(
    ScanlyNotification notification,
  ) async {
    final List<ScanlyNotification> notifications =
        await getNotifications();

    // ========================================================
    // DUPLICATE CHECK
    // ========================================================

    final bool alreadyExists = notifications.any(
      (item) => item.id == notification.id,
    );

    if (alreadyExists) {
      return;
    }

    notifications.insert(
      0,
      notification,
    );

    await saveNotifications(
      notifications,
    );
  }

  // ==========================================================
  // MARK AS READ
  // ==========================================================

  static Future<void> markAsRead(
    String id,
  ) async {
    final List<ScanlyNotification> notifications =
        await getNotifications();

    for (final ScanlyNotification notification
        in notifications) {
      if (notification.id == id) {
        notification.isRead = true;
        break;
      }
    }

    await saveNotifications(
      notifications,
    );
  }

  // ==========================================================
  // MARK ALL AS READ
  // ==========================================================

  static Future<void> markAllAsRead() async {
    final List<ScanlyNotification> notifications =
        await getNotifications();

    for (final ScanlyNotification notification
        in notifications) {
      notification.isRead = true;
    }

    await saveNotifications(
      notifications,
    );
  }

  // ==========================================================
  // DELETE
  // ==========================================================

  static Future<void> delete(
    String id,
  ) async {
    final List<ScanlyNotification> notifications =
        await getNotifications();

    notifications.removeWhere(
      (notification) => notification.id == id,
    );

    await saveNotifications(
      notifications,
    );
  }

  // ==========================================================
  // CLEAR ALL
  // ==========================================================

  static Future<void> clearAll() async {
    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    await prefs.remove(
      notificationsKey,
    );
  }

  // ==========================================================
  // UNREAD COUNT
  // ==========================================================

  static Future<int> getUnreadCount() async {
    final List<ScanlyNotification> notifications =
        await getNotifications();

    return notifications
        .where(
          (notification) => !notification.isRead,
        )
        .length;
  }

  // ==========================================================
  // CHECK ENABLED
  // ==========================================================

  static Future<bool> isEnabled() async {
    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    return prefs.getBool(
          enabledKey,
        ) ??
        true;
  }

  // ==========================================================
  // SET ENABLED
  // ==========================================================

  static Future<void> setEnabled(
    bool enabled,
  ) async {
    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    await prefs.setBool(
      enabledKey,
      enabled,
    );
  }
}