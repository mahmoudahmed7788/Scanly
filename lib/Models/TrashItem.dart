import 'dart:convert';

enum TrashItemType {
  document,
  note,
  pdf,
  image,
  qr,
  other,
}

extension TrashItemTypeExtension on TrashItemType {
  String get value {
    switch (this) {
      case TrashItemType.document:
        return 'document';
      case TrashItemType.note:
        return 'note';
      case TrashItemType.pdf:
        return 'pdf';
      case TrashItemType.image:
        return 'image';
      case TrashItemType.qr:
        return 'qr';
      case TrashItemType.other:
        return 'other';
    }
  }

  static TrashItemType fromValue(String value) {
    switch (value) {
      case 'document':
        return TrashItemType.document;
      case 'note':
        return TrashItemType.note;
      case 'pdf':
        return TrashItemType.pdf;
      case 'image':
        return TrashItemType.image;
      case 'qr':
        return TrashItemType.qr;
      default:
        return TrashItemType.other;
    }
  }
}

class TrashItem {
  final String id;
  final TrashItemType type;
  final String title;
  final Map<String, dynamic> data;
  final DateTime deletedAt;

  const TrashItem({
    required this.id,
    required this.type,
    required this.title,
    required this.data,
    required this.deletedAt,
  });

  DateTime get permanentDeleteAt {
    return deletedAt.add(
      const Duration(days: 30),
    );
  }

  Duration get remainingDuration {
    final remaining =
        permanentDeleteAt.difference(DateTime.now());

    if (remaining.isNegative) {
      return Duration.zero;
    }

    return remaining;
  }

  bool get isExpired {
    return DateTime.now().isAfter(
      permanentDeleteAt,
    );
  }

  int get remainingDays {
    final duration = remainingDuration;

    if (duration == Duration.zero) {
      return 0;
    }

    return duration.inHours == 0
        ? 1
        : (duration.inHours / 24).ceil();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.value,
      'title': title,
      'data': data,
      'deletedAt': deletedAt.toIso8601String(),
    };
  }

  String toJson() {
    return jsonEncode(toMap());
  }

  factory TrashItem.fromMap(
    Map<String, dynamic> map,
  ) {
    return TrashItem(
      id: map['id']?.toString() ?? '',
      type: TrashItemTypeExtension.fromValue(
        map['type']?.toString() ?? 'other',
      ),
      title: map['title']?.toString() ?? 'Deleted Item',
      data: Map<String, dynamic>.from(
        map['data'] ?? {},
      ),
      deletedAt: DateTime.tryParse(
            map['deletedAt']?.toString() ?? '',
          ) ??
          DateTime.now(),
    );
  }

  factory TrashItem.fromJson(String value) {
    return TrashItem.fromMap(
      Map<String, dynamic>.from(
        jsonDecode(value),
      ),
    );
  }
}