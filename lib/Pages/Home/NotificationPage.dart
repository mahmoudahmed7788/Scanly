import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:scanly/Core/NotificationService.dart';
import 'package:scanly/Models/ScanlyNotification.dart';
import 'package:scanly/Widgets/Notifications/NotificationCard.dart';
import 'package:scanly/Widgets/Notifications/NotificationsEmptyState.dart';


class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<ScanlyNotification> notifications = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    _loadNotifications();
  }

  // =====================================================
  // LOAD NOTIFICATIONS
  // =====================================================

  Future<void> _loadNotifications() async {
    try {
      final data = await NotificationService.getNotifications();

      if (!mounted) return;

      setState(() {
        notifications = data;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  // =====================================================
  // MARK ALL AS READ
  // =====================================================

  Future<void> _markAllAsRead() async {
    await NotificationService.markAllAsRead();

    await _loadNotifications();
  }

  // =====================================================
  // MARK ONE AS READ
  // =====================================================

  Future<void> _markAsRead(ScanlyNotification notification) async {
    if (notification.isRead) {
      return;
    }

    await NotificationService.markAsRead(notification.id);

    await _loadNotifications();
  }

  // =====================================================
  // DELETE
  // =====================================================

  Future<void> _deleteNotification(String id) async {
    await NotificationService.delete(id);

    await _loadNotifications();
  }

  // =====================================================
  // NAVIGATION
  // =====================================================

  void _goBackHome() {
    context.go('/home');
  }

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = theme.scaffoldBackgroundColor;

    final cardColor = isDark ? const Color(0xFF1D1D29) : Colors.white;

    final primaryText = theme.colorScheme.onSurface;

    final secondaryText = isDark
        ? const Color(0xFFB8B6CC)
        : const Color(0xFF6F6B98);

    final unreadCount = notifications
        .where((item) => item?.isRead == false)
        .length;

    return Scaffold(
      backgroundColor: backgroundColor,

      // =================================================
      // APP BAR
      // =================================================
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,

        leading: IconButton(
          onPressed: _goBackHome,
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: primaryText),
        ),

        title: Text(
          'Notifications',
          style: TextStyle(color: primaryText, fontWeight: FontWeight.bold),
        ),

        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Read all',
                style: TextStyle(
                  color: Color(0xFF5B5FEF),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),

      // =================================================
      // BODY
      // =================================================
      body: _buildBody(cardColor, primaryText, secondaryText, isDark),
    );
  }

  // =====================================================
  // BODY
  // =====================================================

  Widget _buildBody(
    Color cardColor,
    Color primaryText,
    Color secondaryText,
    bool isDark,
  ) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (notifications.isEmpty) {
      return NotificationsEmptyState(
        primaryText: primaryText,
        secondaryText: secondaryText,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,

      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),

        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),

        itemCount: notifications.length,

        separatorBuilder: (_, __) => const SizedBox(height: 12),

        itemBuilder: (context, index) {
          final notification = notifications[index];

          return NotificationCard(
            notification: notification,
            cardColor: cardColor,
            primaryText: primaryText,
            secondaryText: secondaryText,
            isDark: isDark,
            onMarkAsRead: () => _markAsRead(notification),
            onDelete: () => _deleteNotification(notification.id),
          );
        },
      ),
    );
  }
}

extension on Object? {
  bool? get isRead => null;
}
