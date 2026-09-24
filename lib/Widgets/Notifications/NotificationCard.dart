import 'package:flutter/material.dart';
import 'package:scanly/Models/ScanlyNotification.dart';
import 'package:scanly/Widgets/Notifications/notifications_utils.dart';


class NotificationCard
    extends StatelessWidget {
  final ScanlyNotification notification;

  final Color cardColor;
  final Color primaryText;
  final Color secondaryText;

  final bool isDark;

  final VoidCallback onMarkAsRead;
  final VoidCallback onDelete;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.cardColor,
    required this.primaryText,
    required this.secondaryText,
    required this.isDark,
    required this.onMarkAsRead,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
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
        onDelete();
      },
      background: _buildDismissBackground(),
      child: GestureDetector(
        onTap: onMarkAsRead,
        child: AnimatedContainer(
          duration:
              const Duration(
            milliseconds: 200,
          ),
          padding:
              const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius:
                BorderRadius.circular(20),
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
                  isDark
                      ? 0.12
                      : 0.05,
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
              _buildIcon(),

              const SizedBox(
                width: 14,
              ),

              _buildContent(isRead),
            ],
          ),
        ),
      ),
    );
  }

  // =====================================================
  // DISMISS BACKGROUND
  // =====================================================

  Widget _buildDismissBackground() {
    return Container(
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
            BorderRadius.circular(20),
      ),
      child: const Icon(
        Icons.delete_outline_rounded,
        color: Colors.white,
      ),
    );
  }

  // =====================================================
  // ICON
  // =====================================================

  Widget _buildIcon() {
    return Container(
      width: 50,
      height: 50,
      decoration:
          BoxDecoration(
        color:
            const Color(0xFF5B5FEF)
                .withOpacity(0.12),
        borderRadius:
            BorderRadius.circular(15),
      ),
      child: Icon(
        NotificationsUtils.getIcon(
          notification,
        ),
        color:
            const Color(0xFF5B5FEF),
        size: 25,
      ),
    );
  }

  // =====================================================
  // CONTENT
  // =====================================================

  Widget _buildContent(
    bool isRead,
  ) {
    return Expanded(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  notification.title,
                  style: TextStyle(
                    color:
                        primaryText,
                    fontSize: 16,
                    fontWeight: isRead
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
                        Color(0xFF5B5FEF),
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
            notification.body,
            style: TextStyle(
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
            NotificationsUtils.formatTime(
              notification.date,
            ),
            style: TextStyle(
              color: secondaryText
                  .withOpacity(0.75),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}