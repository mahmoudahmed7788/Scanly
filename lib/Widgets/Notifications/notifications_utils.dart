import 'package:flutter/material.dart';
import 'package:scanly/Models/ScanlyNotification.dart';

class NotificationsUtils {
  NotificationsUtils._();

  // =====================================================
  // TIME FORMAT
  // =====================================================

  static String formatTime(
    String date,
  ) {
    if (date.isEmpty) {
      return '';
    }

    try {
      final notificationDate =
          DateTime.parse(date);

      final now =
          DateTime.now();

      final difference =
          now.difference(
        notificationDate,
      );

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

  static IconData getIcon(
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
}