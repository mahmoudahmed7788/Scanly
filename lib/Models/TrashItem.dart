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
  /// Number of days an item stays in Trash before automatic deletion.
  static const int retentionDays = 30;

  final String id;
  final TrashItemType type;
  final String title;
  final Map<String, dynamic> data;
  final DateTime deletedAt;

  /// Whether the item was marked as favorite before deletion.
  final bool wasFavorite;

  /// Whether the item existed in Recent before deletion.
  final bool wasRecent;

  const TrashItem({
    required this.id,
    required this.type,
    required this.title,
    required this.data,
    required this.deletedAt,
    this.wasFavorite = false,
    this.wasRecent = false,
  });

  DateTime get permanentDeleteAt {
    return deletedAt.add(
      const Duration(days: retentionDays),
    );
  }

  Duration get remainingDuration {
    final remaining = permanentDeleteAt.difference(DateTime.now());

    if (remaining.isNegative) {
      return Duration.zero;
    }

    return remaining;
  }

  bool get isExpired {
    return !DateTime.now().isBefore(permanentDeleteAt);
  }

  int get remainingDays {
    final remaining = remainingDuration;

    if (remaining == Duration.zero) {
      return 0;
    }

    return (remaining.inHours / 24).ceil();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.value,
      'title': title,
      'data': data,
      'deletedAt': deletedAt.toIso8601String(),
      'wasFavorite': wasFavorite,
      'wasRecent': wasRecent,
    };
  }

  String toJson() {
    return jsonEncode(toMap());
  }

  factory TrashItem.fromMap(Map<String, dynamic> map) {
    final id = map['id']?.toString().trim() ?? '';

    if (id.isEmpty) {
      throw const FormatException(
        'TrashItem is missing a valid id.',
      );
    }

    final rawData = map['data'];

    if (rawData != null && rawData is! Map) {
      throw const FormatException(
        'TrashItem data must be a Map.',
      );
    }

    final deletedAtString = map['deletedAt']?.toString() ?? '';

    final deletedAt = DateTime.tryParse(deletedAtString);

    if (deletedAt == null) {
      throw const FormatException(
        'TrashItem is missing a valid deletedAt value.',
      );
    }

    return TrashItem(
      id: id,
      type: TrashItemTypeExtension.fromValue(
        map['type']?.toString() ?? 'other',
      ),
      title: _sanitizeTitle(
        map['title']?.toString(),
      ),
      data: rawData == null
          ? <String, dynamic>{}
          : Map<String, dynamic>.from(rawData),
      deletedAt: deletedAt,
      wasFavorite: _parseBool(map['wasFavorite']),
      wasRecent: _parseBool(map['wasRecent']),
    );
  }

  factory TrashItem.fromJson(String value) {
    final decoded = jsonDecode(value);

    if (decoded is! Map) {
      throw const FormatException(
        'TrashItem JSON must contain an object.',
      );
    }

    return TrashItem.fromMap(
      Map<String, dynamic>.from(decoded),
    );
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is String) {
      return value.toLowerCase() == 'true';
    }

    return false;
  }

  static String _sanitizeTitle(String? value) {
    final title = value?.trim() ?? '';

    if (title.isEmpty) {
      return 'Deleted Item';
    }

    return title;
  }
}