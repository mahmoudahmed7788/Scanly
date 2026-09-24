// ============================================================
// NOTIFICATION SERVICE
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:scanly/Models/ScanlyNotification.dart';
import 'package:scanly/Widgets/Notifications/NotificationStorageService.dart';


// ============================================================
// NOTIFICATION SERVICE
// ============================================================

class NotificationService {
  // ==========================================================
  // FIREBASE MESSAGING
  // ==========================================================

  static final FirebaseMessaging _messaging =
      FirebaseMessaging.instance;

  // ==========================================================
  // LOCAL NOTIFICATIONS
  // ==========================================================

  static final FlutterLocalNotificationsPlugin
      _localNotifications =
      FlutterLocalNotificationsPlugin();

  // ==========================================================
  // FIRESTORE
  // ==========================================================

  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // ==========================================================
  // CONSTANTS
  // ==========================================================

  static const String channelId =
      'scanly_notifications';

  static const String channelName =
      'Scanly Notifications';

  static const String channelDescription =
      'Notifications from Scanly';

  static const String topic =
      'scanly_all';

  // ==========================================================
  // STATE
  // ==========================================================

  static bool _initialized = false;

  // ==========================================================
  // INITIALIZE
  // ==========================================================

  static Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    try {
      // ======================================================
      // REQUEST PERMISSION
      // ======================================================

      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      // ======================================================
      // SUBSCRIBE TO BROADCAST TOPIC
      // ======================================================

      await _messaging.subscribeToTopic(
        topic,
      );

      debugPrint(
        'Subscribed to topic: $topic',
      );

      // ======================================================
      // INITIALIZE LOCAL NOTIFICATIONS
      // ======================================================

      const AndroidInitializationSettings
          androidSettings =
          AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );

      const InitializationSettings settings =
          InitializationSettings(
        android: androidSettings,
      );

      await _localNotifications.initialize(
        settings,
        onDidReceiveNotificationResponse:
            _onNotificationTap,
      );

      // ======================================================
      // CREATE ANDROID CHANNEL
      // ======================================================

      const AndroidNotificationChannel channel =
          AndroidNotificationChannel(
        channelId,
        channelName,
        description: channelDescription,
        importance: Importance.high,
      );

      final AndroidFlutterLocalNotificationsPlugin?
          android =
          _localNotifications
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>();

      await android?.createNotificationChannel(
        channel,
      );

      // ======================================================
      // FOREGROUND MESSAGES
      // ======================================================

      FirebaseMessaging.onMessage.listen(
        _handleForegroundMessage,
      );

      // ======================================================
      // BACKGROUND MESSAGE OPEN
      // ======================================================

      FirebaseMessaging.onMessageOpenedApp.listen(
        _handleNotificationOpened,
      );

      // ======================================================
      // TERMINATED APP
      // ======================================================

      final RemoteMessage? initialMessage =
          await _messaging.getInitialMessage();

      if (initialMessage != null) {
        await _saveRemoteMessage(
          initialMessage,
        );
      }

      // ======================================================
      // FIRESTORE BROADCAST SYNC
      // ======================================================

      await _syncBroadcastNotifications();

      // ======================================================
      // COMPLETE
      // ======================================================

      _initialized = true;

      debugPrint(
        'Scanly Notifications initialized',
      );
    } catch (e) {
      debugPrint(
        'NotificationService error: $e',
      );
    }
  }

  // ==========================================================
  // SYNC BROADCAST NOTIFICATIONS
  // ==========================================================

  static Future<void>
      _syncBroadcastNotifications() async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await _firestore
              .collection('scanly_notifications')
              .orderBy(
                'createdAt',
                descending: true,
              )
              .limit(100)
              .get();

      final List<ScanlyNotification> existing =
          await getNotifications();

      final Set<String> existingIds =
          existing
              .map(
                (notification) => notification.id,
              )
              .toSet();

      bool changed = false;

      // ======================================================
      // PROCESS FIRESTORE NOTIFICATIONS
      // ======================================================

      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in snapshot.docs) {
        if (existingIds.contains(doc.id)) {
          continue;
        }

        final Map<String, dynamic> data =
            doc.data();

        final dynamic timestamp =
            data['createdAt'];

        String date;

        if (timestamp is Timestamp) {
          date = timestamp
              .toDate()
              .toIso8601String();
        } else {
          date = DateTime.now()
              .toIso8601String();
        }

        existing.insert(
          0,
          ScanlyNotification(
            id: doc.id,
            title:
                data['title']?.toString() ??
                    'Scanly',
            body:
                data['body']?.toString() ??
                    '',
            date: date,
          ),
        );

        changed = true;
      }

      // ======================================================
      // SAVE CHANGES
      // ======================================================

      if (changed) {
        await NotificationStorageService
            .saveNotifications(
          existing,
        );
      }
    } catch (e) {
      debugPrint(
        'Broadcast sync error: $e',
      );
    }
  }

  // ==========================================================
  // FOREGROUND MESSAGE
  // ==========================================================

  static Future<void>
      _handleForegroundMessage(
    RemoteMessage message,
  ) async {
    try {
      if (!await isEnabled()) {
        return;
      }

      // ======================================================
      // SAVE MESSAGE
      // ======================================================

      await _saveRemoteMessage(
        message,
      );

      final RemoteNotification? notification =
          message.notification;

      if (notification == null) {
        return;
      }

      // ======================================================
      // SHOW LOCAL NOTIFICATION
      // ======================================================

      await _localNotifications.show(
        notification.hashCode,
        notification.title ?? 'Scanly',
        notification.body ?? '',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            channelDescription:
                channelDescription,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    } catch (e) {
      debugPrint(
        'Foreground notification error: $e',
      );
    }
  }

  // ==========================================================
  // NOTIFICATION OPENED
  // ==========================================================

  static Future<void>
      _handleNotificationOpened(
    RemoteMessage message,
  ) async {
    try {
      await _saveRemoteMessage(
        message,
      );

      debugPrint(
        'Scanly notification opened',
      );
    } catch (e) {
      debugPrint(
        'Notification opened error: $e',
      );
    }
  }

  // ==========================================================
  // LOCAL NOTIFICATION TAP
  // ==========================================================

  static void _onNotificationTap(
    NotificationResponse response,
  ) {
    debugPrint(
      'Local notification tapped: '
      '${response.payload}',
    );
  }

  // ==========================================================
  // SAVE REMOTE MESSAGE
  // ==========================================================

  static Future<void>
      _saveRemoteMessage(
    RemoteMessage message,
  ) async {
    final RemoteNotification? notification =
        message.notification;

    if (notification == null) {
      return;
    }

    final List<ScanlyNotification> existing =
        await getNotifications();

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

    if (existing.any(
      (item) => item.id == id,
    )) {
      return;
    }

    // ========================================================
    // ADD NOTIFICATION
    // ========================================================

    existing.insert(
      0,
      ScanlyNotification(
        id: id,
        title: notification.title ?? 'Scanly',
        body: notification.body ?? '',
        date: DateTime.now().toIso8601String(),
      ),
    );

    await NotificationStorageService
        .saveNotifications(
      existing,
    );
  }

  // ==========================================================
  // GET NOTIFICATIONS
  // ==========================================================

  static Future<List<ScanlyNotification>>
      getNotifications() {
    return NotificationStorageService
        .getNotifications();
  }

  // ==========================================================
  // MARK AS READ
  // ==========================================================

  static Future<void> markAsRead(
    String id,
  ) async {
    await NotificationStorageService
        .markAsRead(
      id,
    );
  }

  // ==========================================================
  // MARK ALL AS READ
  // ==========================================================

  static Future<void> markAllAsRead() async {
    await NotificationStorageService
        .markAllAsRead();
  }

  // ==========================================================
  // DELETE
  // ==========================================================

  static Future<void> delete(
    String id,
  ) async {
    await NotificationStorageService
        .delete(
      id,
    );
  }

  // ==========================================================
  // CLEAR ALL
  // ==========================================================

  static Future<void> clearAll() async {
    await NotificationStorageService
        .clearAll();
  }

  // ==========================================================
  // UNREAD COUNT
  // ==========================================================

  static Future<int> getUnreadCount() {
    return NotificationStorageService
        .getUnreadCount();
  }

  // ==========================================================
  // ENABLE / DISABLE
  // ==========================================================

  static Future<bool> isEnabled() {
    return NotificationStorageService
        .isEnabled();
  }

  static Future<void> setEnabled(
    bool enabled,
  ) async {
    await NotificationStorageService
        .setEnabled(
      enabled,
    );

    // ========================================================
    // CANCEL LOCAL NOTIFICATIONS
    // ========================================================

    if (!enabled) {
      try {
        await _localNotifications.cancelAll();
      } catch (e) {
        debugPrint(
          'Cancel notifications error: $e',
        );
      }
    }
  }

  // ==========================================================
  // FCM TOKEN
  // ==========================================================

  static Future<String?> getToken() async {
    try {
      final String? token =
          await _messaging.getToken();

      debugPrint(
        'FCM TOKEN: $token',
      );

      return token;
    } catch (e) {
      debugPrint(
        'FCM token error: $e',
      );

      return null;
    }
  }
}