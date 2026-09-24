import 'package:flutter/material.dart';
import 'package:scanly/Core/Scanly_Items.dart';

class HomeActivityUtils {
  HomeActivityUtils._();

  // ============================================================
  // TYPE
  // ============================================================

  static String displayType(String type) {
    final normalized = type.trim().toLowerCase();

    switch (normalized) {
      case 'qr':
      case 'qrcode':
      case 'qr_code':
      case 'qr code':
        return 'QR Code';

      case 'pdf':
        return 'PDF';

      case 'image':
      case 'images':
        return 'Image';

      case 'note':
      case 'notes':
        return 'Note';

      case 'document':
      case 'doc':
        return 'Document';

      case 'voice':
      case 'audio':
        return 'Voice';

      case 'text':
        return 'Text';

      default:
        return type.trim().isEmpty ? 'Item' : type.trim();
    }
  }

  static IconData iconForType(String type) {
    final normalized = type.trim().toLowerCase();

    switch (normalized) {
      case 'qr':
      case 'qrcode':
      case 'qr_code':
      case 'qr code':
        return Icons.qr_code_2_rounded;

      case 'pdf':
        return Icons.picture_as_pdf_rounded;

      case 'image':
      case 'images':
        return Icons.image_rounded;

      case 'note':
      case 'notes':
        return Icons.note_alt_rounded;

      case 'document':
      case 'doc':
        return Icons.description_rounded;

      case 'voice':
      case 'audio':
        return Icons.mic_rounded;

      case 'text':
        return Icons.text_snippet_rounded;

      default:
        return Icons.folder_rounded;
    }
  }

  // ============================================================
  // DATE / TIME
  // ============================================================

  static String formatDateTime(dynamic value) {
    if (value == null) {
      return 'Recently';
    }

    DateTime? date;

    if (value is DateTime) {
      date = value;
    } else if (value is String) {
      final text = value.trim();

      if (text.isEmpty) {
        return 'Recently';
      }

      final number = int.tryParse(text);

      if (number != null) {
        date = timestampToDateTime(number);
      } else {
        date = DateTime.tryParse(text);
      }
    } else if (value is int) {
      date = timestampToDateTime(value);
    } else if (value is double) {
      date = timestampToDateTime(value.toInt());
    }

    if (date == null) {
      return 'Recently';
    }

    final local = date.toLocal();
    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final itemDay = DateTime(
      local.year,
      local.month,
      local.day,
    );

    final difference = today.difference(itemDay).inDays;

    final hour = local.hour % 12 == 0
        ? 12
        : local.hour % 12;

    final minute = local.minute
        .toString()
        .padLeft(2, '0');

    final period = local.hour >= 12
        ? 'PM'
        : 'AM';

    final time = '$hour:$minute $period';

    if (difference == 0) {
      return 'Today • $time';
    }

    if (difference == 1) {
      return 'Yesterday • $time';
    }

    if (difference > 1 && difference < 7) {
      return '${weekday(local.weekday)} • $time';
    }

    final day = local.day
        .toString()
        .padLeft(2, '0');

    final month = local.month
        .toString()
        .padLeft(2, '0');

    return '$day/$month/${local.year} • $time';
  }

  // ============================================================
  // TIMESTAMP
  // ============================================================

  static DateTime timestampToDateTime(
    int timestamp,
  ) {
    if (timestamp.abs() >= 100000000000) {
      return DateTime.fromMillisecondsSinceEpoch(
        timestamp,
      );
    }

    return DateTime.fromMillisecondsSinceEpoch(
      timestamp * 1000,
    );
  }

  // ============================================================
  // WEEKDAY
  // ============================================================

  static String weekday(int day) {
    switch (day) {
      case DateTime.monday:
        return 'Mon';

      case DateTime.tuesday:
        return 'Tue';

      case DateTime.wednesday:
        return 'Wed';

      case DateTime.thursday:
        return 'Thu';

      case DateTime.friday:
        return 'Fri';

      case DateTime.saturday:
        return 'Sat';

      case DateTime.sunday:
        return 'Sun';

      default:
        return '';
    }
  }

  // ============================================================
  // SCANLY ITEM DATE
  // ============================================================

  static String extractItemDateTime(
    ScanlyItem item,
  ) {
    final dynamic rawItem = item;

    try {
      final value = rawItem.dateTime;

      if (value != null) {
        return formatDateTime(value);
      }
    } catch (_) {}

    try {
      final value = rawItem.date;

      if (value != null) {
        return formatDateTime(value);
      }
    } catch (_) {}

    try {
      final value = rawItem.createdAt;

      if (value != null) {
        return formatDateTime(value);
      }
    } catch (_) {}

    try {
      final value = rawItem.openedAt;

      if (value != null) {
        return formatDateTime(value);
      }
    } catch (_) {}

    return 'Recently';
  }

  // ============================================================
  // DOCUMENT DATE
  // ============================================================

  static String extractDocumentDateTime(
    dynamic document,
  ) {
    return formatDateTime(
      document.date,
    );
  }
}