import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:scanly/NotificationsService.dart';


class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() =>
      _NotificationsPageState();
}

class _NotificationsPageState
    extends State<NotificationsPage> {
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
    final data =
        await NotificationService.getNotifications();

    if (!mounted) return;

    setState(() {
      notifications = data;
      isLoading = false;
    });
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

  Future<void> _markAsRead(
    ScanlyNotification notification,
  ) async {
    if (notification.isRead) {
      return;
    }

    await NotificationService.markAsRead(
      notification.id,
    );

    await _loadNotifications();
  }

  // =====================================================
  // DELETE
  // =====================================================

  Future<void> _deleteNotification(
    String id,
  ) async {
    await NotificationService.delete(id);

    await _loadNotifications();
  }

  // =====================================================
  // TIME FORMAT
  // =====================================================

  String _formatTime(String date) {
    if (date.isEmpty) {
      return '';
    }

    try {
      final notificationDate =
          DateTime.parse(date);

      final now = DateTime.now();

      final difference =
          now.difference(notificationDate);

      if (difference.inSeconds < 60) {
        return 'Just now';
      }

      if (difference.inMinutes < 60) {
        return '${difference.inMinutes} min ago';
      }

      if (difference.inHours < 24) {
        return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
      }

      if (difference.inDays == 1) {
        return 'Yesterday';
      }

      if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      }

      return '${notificationDate.day}/${notificationDate.month}/${notificationDate.year}';
    } catch (_) {
      return '';
    }
  }

  // =====================================================
  // NOTIFICATION ICON
  // =====================================================

  IconData _getIcon(
    ScanlyNotification notification,
  ) {
    final title =
        notification.title.toLowerCase();

    final body =
        notification.body.toLowerCase();

    final text =
        '$title $body';

    if (text.contains('qr')) {
      return Icons.qr_code_scanner_rounded;
    }

    if (text.contains('scan')) {
      return Icons.document_scanner_outlined;
    }

    if (text.contains('document')) {
      return Icons.description_outlined;
    }

    if (text.contains('welcome')) {
      return Icons.waving_hand_rounded;
    }

    if (text.contains('reminder')) {
      return Icons.alarm_outlined;
    }

    if (text.contains('success')) {
      return Icons.check_circle_outline_rounded;
    }

    if (text.contains('error')) {
      return Icons.error_outline_rounded;
    }

    return Icons.notifications_none_rounded;
  }

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final isDark =
        theme.brightness == Brightness.dark;

    final backgroundColor =
        theme.scaffoldBackgroundColor;

    final cardColor = isDark
        ? const Color(0xFF1D1D29)
        : Colors.white;

    final primaryText =
        theme.colorScheme.onSurface;

    final secondaryText = isDark
        ? const Color(0xFFB8B6CC)
        : const Color(0xFF6F6B98);

    final unreadCount =
        notifications
            .where(
              (item) => !item.isRead,
            )
            .length;

    return Scaffold(
      backgroundColor:
          backgroundColor,

      // =================================================
      // APP BAR
      // =================================================

      appBar: AppBar(
        backgroundColor:
            backgroundColor,

        elevation: 0,

        leading: IconButton(
          onPressed: () {
            context.go('/home');
          },
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: primaryText,
          ),
        ),

        title: Text(
          'Notifications',
          style: TextStyle(
            color: primaryText,
            fontWeight:
                FontWeight.bold,
          ),
        ),

        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed:
                  _markAllAsRead,
              child: const Text(
                'Read all',
                style: TextStyle(
                  color:
                      Color(0xFF5B5FEF),
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),
        ],
      ),

      // =================================================
      // BODY
      // =================================================

      body: isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : notifications.isEmpty
              ? _buildEmptyState(
                  primaryText,
                  secondaryText,
                )
              : RefreshIndicator(
                  onRefresh:
                      _loadNotifications,

                  child:
                      ListView.separated(
                    physics:
                        const AlwaysScrollableScrollPhysics(),

                    padding:
                        const EdgeInsets.fromLTRB(
                      20,
                      10,
                      20,
                      30,
                    ),

                    itemCount:
                        notifications.length,

                    separatorBuilder:
                        (_, __) =>
                            const SizedBox(
                      height: 12,
                    ),

                    itemBuilder:
                        (context, index) {
                      final notification =
                          notifications[
                              index];

                      return _buildNotificationCard(
                        notification,
                        cardColor,
                        primaryText,
                        secondaryText,
                        isDark,
                      );
                    },
                  ),
                ),
    );
  }

  // =====================================================
  // EMPTY STATE
  // =====================================================

  Widget _buildEmptyState(
    Color primaryText,
    Color secondaryText,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration:
                BoxDecoration(
              color:
                  const Color(0xFF5B5FEF)
                      .withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              size: 45,
              color:
                  Color(0xFF5B5FEF),
            ),
          ),

          const SizedBox(height: 20),

          Text(
            'No Notifications',
            style: TextStyle(
              color: primaryText,
              fontSize: 22,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'You are all caught up!',
            style: TextStyle(
              color: secondaryText,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // NOTIFICATION CARD
  // =====================================================

  Widget _buildNotificationCard(
    ScanlyNotification notification,
    Color cardColor,
    Color primaryText,
    Color secondaryText,
    bool isDark,
  ) {
    final isRead =
        notification.isRead;

    return Dismissible(
      key: ValueKey(
        notification.id,
      ),

      direction:
          DismissDirection.endToStart,

      confirmDismiss: (_) async {
        return true;
      },

      onDismissed: (_) {
        _deleteNotification(
          notification.id,
        );
      },

      background: Container(
        alignment:
            Alignment.centerRight,

        padding:
            const EdgeInsets.only(
          right: 25,
        ),

        decoration:
            BoxDecoration(
          color: Colors.redAccent,
          borderRadius:
              BorderRadius.circular(
            20,
          ),
        ),

        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
        ),
      ),

      child: GestureDetector(
        onTap: () {
          _markAsRead(
            notification,
          );
        },

        child: AnimatedContainer(
          duration:
              const Duration(
            milliseconds: 200,
          ),

          padding:
              const EdgeInsets.all(
            16,
          ),

          decoration:
              BoxDecoration(
            color: cardColor,

            borderRadius:
                BorderRadius.circular(
              20,
            ),

            border: !isRead
                ? Border.all(
                    color:
                        const Color(
                      0xFF5B5FEF,
                    ).withOpacity(
                      0.35,
                    ),
                  )
                : null,

            boxShadow: [
              BoxShadow(
                color:
                    Colors.black.withOpacity(
                  isDark ? 0.12 : 0.05,
                ),
                blurRadius: 12,
                offset:
                    const Offset(0, 4),
              ),
            ],
          ),

          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              // =========================================
              // ICON
              // =========================================

              Container(
                width: 50,
                height: 50,

                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xFF5B5FEF,
                  ).withOpacity(
                    0.12,
                  ),

                  borderRadius:
                      BorderRadius.circular(
                    15,
                  ),
                ),

                child: Icon(
                  _getIcon(
                    notification,
                  ),
                  color:
                      const Color(
                    0xFF5B5FEF,
                  ),
                  size: 25,
                ),
              ),

              const SizedBox(
                width: 14,
              ),

              // =========================================
              // CONTENT
              // =========================================

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification
                                .title,

                            style:
                                TextStyle(
                              color:
                                  primaryText,
                              fontSize: 16,
                              fontWeight:
                                  isRead
                                      ? FontWeight.w600
                                      : FontWeight.bold,
                            ),
                          ),
                        ),

                        if (!isRead)
                          Container(
                            width: 9,
                            height: 9,

                            decoration:
                                const BoxDecoration(
                              color:
                                  Color(
                                0xFF5B5FEF,
                              ),
                              shape:
                                  BoxShape.circle,
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(
                      height: 6,
                    ),

                    Text(
                      notification
                          .body,

                      style:
                          TextStyle(
                        color:
                            secondaryText,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    Text(
                      _formatTime(
                        notification
                            .date,
                      ),

                      style:
                          TextStyle(
                        color:
                            secondaryText
                                .withOpacity(
                          0.75,
                        ),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
