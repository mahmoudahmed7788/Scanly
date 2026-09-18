import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

// =====================================================
// NOTIFICATION MODEL
// =====================================================

class ScanlyNotification {
  final String id;
  final String title;
  final String body;
  final String date;
  bool isRead;

  ScanlyNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.date,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'date': date,
      'isRead': isRead,
    };
  }

  factory ScanlyNotification.fromMap(
    Map<String, dynamic> map,
  ) {
    return ScanlyNotification(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Scanly',
      body: map['body']?.toString() ?? '',
      date: map['date']?.toString() ?? '',
      isRead: map['isRead'] == true,
    );
  }
}

// =====================================================
// BACKGROUND FCM HANDLER
// =====================================================

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  try {
    await Firebase.initializeApp();

    final notification = message.notification;

    if (notification == null) {
      return;
    }

    final prefs =
        await SharedPreferences.getInstance();

    final existing =
        prefs.getStringList(
              'scanly_notifications',
            ) ??
            [];

    final id =
        message.messageId ??
        DateTime.now()
            .millisecondsSinceEpoch
            .toString();

    // Prevent duplicate notification.
    final alreadyExists = existing.any((item) {
      try {
        final map = jsonDecode(item);

        return map['id']?.toString() == id;
      } catch (_) {
        return false;
      }
    });

    if (alreadyExists) {
      return;
    }

    final item = ScanlyNotification(
      id: id,
      title:
          notification.title ?? 'Scanly',
      body:
          notification.body ?? '',
      date:
          DateTime.now()
              .toIso8601String(),
    );

    existing.insert(
      0,
      jsonEncode(item.toMap()),
    );

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

// =====================================================
// NOTIFICATION SERVICE
// =====================================================

class NotificationService {
  static final FirebaseMessaging _messaging =
      FirebaseMessaging.instance;

  static final FlutterLocalNotificationsPlugin
      _localNotifications =
      FlutterLocalNotificationsPlugin();

  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static const String _enabledKey =
      'notifications_enabled';

  static const String _notificationsKey =
      'scanly_notifications';

  static const String _channelId =
      'scanly_notifications';

  static const String _channelName =
      'Scanly Notifications';

  static const String _channelDescription =
      'Notifications from Scanly';

  static const String _topic =
      'scanly_all';

  static bool _initialized = false;

  // =====================================================
  // INITIALIZE
  // =====================================================

  static Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    try {
      // ---------------------------------------------
      // Permission
      // ---------------------------------------------

      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      // ---------------------------------------------
      // Subscribe every device to Scanly broadcast
      // ---------------------------------------------

      await _messaging.subscribeToTopic(
        _topic,
      );

      debugPrint(
        'Subscribed to topic: $_topic',
      );

      // ---------------------------------------------
      // Local notifications
      // ---------------------------------------------

      const androidSettings =
          AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );

      const settings =
          InitializationSettings(
        android: androidSettings,
      );

      await _localNotifications.initialize(
        settings,
        onDidReceiveNotificationResponse:
            _onNotificationTap,
      );

      // ---------------------------------------------
      // Android channel
      // ---------------------------------------------

      const channel =
          AndroidNotificationChannel(
        _channelId,
        _channelName,
        description:
            _channelDescription,
        importance: Importance.high,
      );

      final android =
          _localNotifications
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>();

      await android?.createNotificationChannel(
        channel,
      );

      // ---------------------------------------------
      // Foreground messages
      // ---------------------------------------------

      FirebaseMessaging.onMessage.listen(
        _handleForegroundMessage,
      );

      // ---------------------------------------------
      // Opened notification
      // ---------------------------------------------

      FirebaseMessaging.onMessageOpenedApp.listen(
        _handleNotificationOpened,
      );

      // ---------------------------------------------
      // Terminated app
      // ---------------------------------------------

      final initialMessage =
          await _messaging.getInitialMessage();

      if (initialMessage != null) {
        await _saveRemoteMessage(
          initialMessage,
        );
      }

      // ---------------------------------------------
      // Load broadcast notifications from Firestore
      // ---------------------------------------------

      await _syncBroadcastNotifications();

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

  // =====================================================
  // SYNC BROADCASTS FROM FIRESTORE
  // =====================================================

  static Future<void>
      _syncBroadcastNotifications() async {
    try {
      final snapshot = await _firestore
          .collection('scanly_notifications')
          .orderBy(
            'createdAt',
            descending: true,
          )
          .limit(100)
          .get();

      final existing =
          await getNotifications();

      final existingIds =
          existing.map((e) => e.id).toSet();

      bool changed = false;

      for (final doc in snapshot.docs) {
        if (existingIds.contains(doc.id)) {
          continue;
        }

        final data = doc.data();

        final timestamp =
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

      if (changed) {
        await _saveNotifications(
          existing,
        );
      }
    } catch (e) {
      debugPrint(
        'Broadcast sync error: $e',
      );
    }
  }

  // =====================================================
  // FOREGROUND MESSAGE
  // =====================================================

  static Future<void>
      _handleForegroundMessage(
    RemoteMessage message,
  ) async {
    try {
      if (!await isEnabled()) {
        return;
      }

      await _saveRemoteMessage(
        message,
      );

      final notification =
          message.notification;

      if (notification == null) {
        return;
      }

      await _localNotifications.show(
        notification.hashCode,
        notification.title ?? 'Scanly',
        notification.body ?? '',
        const NotificationDetails(
          android:
              AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription:
                _channelDescription,
            importance:
                Importance.high,
            priority:
                Priority.high,
            icon:
                '@mipmap/ic_launcher',
          ),
        ),
      );
    } catch (e) {
      debugPrint(
        'Foreground notification error: $e',
      );
    }
  }

  // =====================================================
  // OPENED FROM BACKGROUND
  // =====================================================

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

  // =====================================================
  // LOCAL NOTIFICATION TAP
  // =====================================================

  static void _onNotificationTap(
    NotificationResponse response,
  ) {
    debugPrint(
      'Local notification tapped: '
      '${response.payload}',
    );
  }

  // =====================================================
  // SAVE FCM MESSAGE
  // =====================================================

  static Future<void>
      _saveRemoteMessage(
    RemoteMessage message,
  ) async {
    final notification =
        message.notification;

    if (notification == null) {
      return;
    }

    final existing =
        await getNotifications();

    final id =
        message.messageId ??
        DateTime.now()
            .millisecondsSinceEpoch
            .toString();

    if (existing.any(
      (item) => item.id == id,
    )) {
      return;
    }

    existing.insert(
      0,
      ScanlyNotification(
        id: id,
        title:
            notification.title ?? 'Scanly',
        body:
            notification.body ?? '',
        date:
            DateTime.now()
                .toIso8601String(),
      ),
    );

    await _saveNotifications(
      existing,
    );
  }

  // =====================================================
  // GET NOTIFICATIONS
  // =====================================================

  static Future<
          List<ScanlyNotification>>
      getNotifications() async {
    final prefs =
        await SharedPreferences
            .getInstance();

    final data =
        prefs.getStringList(
              _notificationsKey,
            ) ??
            [];

    final notifications =
        <ScanlyNotification>[];

    for (final item in data) {
      try {
        final map =
            jsonDecode(item);

        if (map is Map) {
          notifications.add(
            ScanlyNotification.fromMap(
              Map<String, dynamic>.from(
                map,
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

  // =====================================================
  // SAVE NOTIFICATIONS
  // =====================================================

  static Future<void>
      _saveNotifications(
    List<ScanlyNotification>
        notifications,
  ) async {
    final prefs =
        await SharedPreferences
            .getInstance();

    final data =
        notifications
            .take(100)
            .map(
              (item) =>
                  jsonEncode(
                item.toMap(),
              ),
            )
            .toList();

    await prefs.setStringList(
      _notificationsKey,
      data,
    );
  }

  // =====================================================
  // MARK AS READ
  // =====================================================

  static Future<void> markAsRead(
    String id,
  ) async {
    final notifications =
        await getNotifications();

    for (final item in notifications) {
      if (item.id == id) {
        item.isRead = true;
        break;
      }
    }

    await _saveNotifications(
      notifications,
    );
  }

  // =====================================================
  // MARK ALL AS READ
  // =====================================================

  static Future<void>
      markAllAsRead() async {
    final notifications =
        await getNotifications();

    for (final item in notifications) {
      item.isRead = true;
    }

    await _saveNotifications(
      notifications,
    );
  }

  // =====================================================
  // DELETE
  // =====================================================

  static Future<void> delete(
    String id,
  ) async {
    final notifications =
        await getNotifications();

    notifications.removeWhere(
      (item) => item.id == id,
    );

    await _saveNotifications(
      notifications,
    );
  }

  // =====================================================
  // CLEAR ALL
  // =====================================================

  static Future<void>
      clearAll() async {
    final prefs =
        await SharedPreferences
            .getInstance();

    await prefs.remove(
      _notificationsKey,
    );
  }

  // =====================================================
  // UNREAD COUNT
  // =====================================================

  static Future<int>
      getUnreadCount() async {
    final notifications =
        await getNotifications();

    return notifications
        .where(
          (item) => !item.isRead,
        )
        .length;
  }

  // =====================================================
  // ENABLE / DISABLE
  // =====================================================

  static Future<bool>
      isEnabled() async {
    final prefs =
        await SharedPreferences
            .getInstance();

    return prefs.getBool(
          _enabledKey,
        ) ??
        true;
  }

  static Future<void> setEnabled(
    bool enabled,
  ) async {
    final prefs =
        await SharedPreferences
            .getInstance();

    await prefs.setBool(
      _enabledKey,
      enabled,
    );

    if (!enabled) {
      try {
        await _localNotifications
            .cancelAll();
      } catch (e) {
        debugPrint(
          'Cancel notifications error: $e',
        );
      }
    }
  }

  // =====================================================
  // FCM TOKEN
  // =====================================================

  static Future<String?>
      getToken() async {
    try {
      final token =
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