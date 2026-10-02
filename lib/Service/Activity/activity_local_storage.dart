import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:scanly/Core/Scanly_Items.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TrashItem {
  final ScanlyItem item;
  final bool wasFavorite;
  final bool wasRecent;
  final int deletedAt;

  const TrashItem({
    required this.item,
    required this.wasFavorite,
    required this.wasRecent,
    required this.deletedAt,
  });

  static const int expiryDays = 30;

  int get expiryTime {
    return deletedAt +
        const Duration(days: expiryDays).inMilliseconds;
  }

  int get remainingMilliseconds {
    final remaining =
        expiryTime - DateTime.now().millisecondsSinceEpoch;

    return remaining < 0 ? 0 : remaining;
  }

  int get remainingDays {
    final remaining = remainingMilliseconds;

    if (remaining <= 0) {
      return 0;
    }

    return (remaining /
            const Duration(days: 1).inMilliseconds)
        .ceil();
  }

  bool get isExpired {
    return remainingMilliseconds <= 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'item': item.toJson(),
      'wasFavorite': wasFavorite,
      'wasRecent': wasRecent,
      'deletedAt': deletedAt,
    };
  }

  factory TrashItem.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawItem = json['item'];

    return TrashItem(
      item: ScanlyItem.fromJson(
        rawItem is Map
            ? Map<String, dynamic>.from(rawItem)
            : <String, dynamic>{},
      ),
      wasFavorite:
          json['wasFavorite'] as bool? ?? false,
      wasRecent:
          json['wasRecent'] as bool? ?? false,
      deletedAt:
          json['deletedAt'] as int? ?? 0,
    );
  }
}

class ActivityLocalStorage {
  static const String _legacyFavoritesKey =
      'scanly_global_favorites';

  static const String _legacyRecentKey =
      'scanly_global_recent';

  static const String _legacyTrashKey =
      'scanly_global_trash';

  static const String _migrationPrefix =
      'scanly_activity_migrated_';

  static Future<SharedPreferences> get _prefs async {
    return SharedPreferences.getInstance();
  }

  static String _favoritesKey(String uid) {
    return 'scanly_favorites_$uid';
  }

  static String _recentKey(String uid) {
    return 'scanly_recent_$uid';
  }

  static String _trashKey(String uid) {
    return 'scanly_trash_$uid';
  }

  static String _migrationKey(String uid) {
    return '$_migrationPrefix$uid';
  }

  static String? get _currentUid {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  static Future<String?> _getUid() async {
    final uid = _currentUid;

    if (uid == null || uid.isEmpty) {
      return null;
    }

    await _migrateLegacyData(uid);

    return uid;
  }

  static Future<dynamic> _readValue(
    String key,
  ) async {
    final prefs = await _prefs;

    try {
      return prefs.get(key);
    } catch (_) {
      return null;
    }
  }

  static Future<List<dynamic>> _readList(
    String key,
  ) async {
    final value = await _readValue(key);

    if (value == null) {
      return [];
    }

    if (value is String) {
      if (value.isEmpty) {
        return [];
      }

      try {
        final decoded = jsonDecode(value);

        if (decoded is List) {
          return decoded;
        }

        return [];
      } catch (_) {
        return [];
      }
    }

    if (value is List) {
      return value;
    }

    return [];
  }

  static Future<void> _saveJsonList(
    String key,
    List<dynamic> items,
  ) async {
    final prefs = await _prefs;

    await prefs.setString(
      key,
      jsonEncode(items),
    );
  }

  static Future<void> _migrateLegacyData(
    String uid,
  ) async {
    final prefs = await _prefs;

    final migrationKey = _migrationKey(uid);

    if (prefs.getBool(migrationKey) == true) {
      return;
    }

    final userFavoritesKey = _favoritesKey(uid);
    final userRecentKey = _recentKey(uid);
    final userTrashKey = _trashKey(uid);

    final hasUserFavorites =
        prefs.containsKey(userFavoritesKey);

    final hasUserRecent =
        prefs.containsKey(userRecentKey);

    final hasUserTrash =
        prefs.containsKey(userTrashKey);

    if (!hasUserFavorites &&
        prefs.containsKey(_legacyFavoritesKey)) {
      final legacyFavorites =
          await _readList(_legacyFavoritesKey);

      if (legacyFavorites.isNotEmpty) {
        await _saveJsonList(
          userFavoritesKey,
          legacyFavorites,
        );
      }
    }

    if (!hasUserRecent &&
        prefs.containsKey(_legacyRecentKey)) {
      final legacyRecent =
          await _readList(_legacyRecentKey);

      if (legacyRecent.isNotEmpty) {
        await _saveJsonList(
          userRecentKey,
          legacyRecent,
        );
      }
    }

    if (!hasUserTrash &&
        prefs.containsKey(_legacyTrashKey)) {
      final legacyTrash =
          await _readList(_legacyTrashKey);

      if (legacyTrash.isNotEmpty) {
        await _saveJsonList(
          userTrashKey,
          legacyTrash,
        );
      }
    }

    await prefs.remove(
      _legacyFavoritesKey,
    );

    await prefs.remove(
      _legacyRecentKey,
    );

    await prefs.remove(
      _legacyTrashKey,
    );

    await prefs.setBool(
      migrationKey,
      true,
    );
  }

  static Future<List<ScanlyItem>> loadFavorites() async {
    final uid = await _getUid();

    if (uid == null) {
      return [];
    }

    final key = _favoritesKey(uid);

    final rawItems = await _readList(key);

    final items = <ScanlyItem>[];

    for (final rawItem in rawItems) {
      try {
        if (rawItem is Map) {
          items.add(
            ScanlyItem.fromJson(
              Map<String, dynamic>.from(rawItem),
            ),
          );
        } else if (rawItem is String) {
          try {
            final decoded = jsonDecode(rawItem);

            if (decoded is Map) {
              items.add(
                ScanlyItem.fromJson(
                  Map<String, dynamic>.from(decoded),
                ),
              );
            }
          } catch (_) {}
        }
      } catch (_) {}
    }

    if (items.isEmpty && rawItems.isNotEmpty) {
      final prefs = await _prefs;

      await prefs.remove(key);
    } else if (rawItems.isNotEmpty) {
      await _saveJsonList(
        key,
        items.map(
          (item) => item.toJson(),
        ).toList(),
      );
    }

    return items;
  }

  static Future<void> saveFavorites(
    List<ScanlyItem> items,
  ) async {
    final uid = await _getUid();

    if (uid == null) {
      return;
    }

    await _saveJsonList(
      _favoritesKey(uid),
      items.map(
        (item) => item.toJson(),
      ).toList(),
    );
  }

  static Future<void> clearFavorites() async {
    final uid = await _getUid();

    if (uid == null) {
      return;
    }

    final prefs = await _prefs;

    await prefs.remove(
      _favoritesKey(uid),
    );
  }

  static Future<List<ScanlyItem>> loadRecent() async {
    final uid = await _getUid();

    if (uid == null) {
      return [];
    }

    final key = _recentKey(uid);

    final rawItems = await _readList(key);

    final items = <ScanlyItem>[];

    for (final rawItem in rawItems) {
      try {
        if (rawItem is Map) {
          items.add(
            ScanlyItem.fromJson(
              Map<String, dynamic>.from(rawItem),
            ),
          );
        } else if (rawItem is String) {
          try {
            final decoded = jsonDecode(rawItem);

            if (decoded is Map) {
              items.add(
                ScanlyItem.fromJson(
                  Map<String, dynamic>.from(decoded),
                ),
              );
            }
          } catch (_) {}
        }
      } catch (_) {}
    }

    if (items.isEmpty && rawItems.isNotEmpty) {
      final prefs = await _prefs;

      await prefs.remove(key);
    } else if (rawItems.isNotEmpty) {
      await _saveJsonList(
        key,
        items.map(
          (item) => item.toJson(),
        ).toList(),
      );
    }

    return items;
  }

  static Future<void> saveRecent(
    List<ScanlyItem> items,
  ) async {
    final uid = await _getUid();

    if (uid == null) {
      return;
    }

    await _saveJsonList(
      _recentKey(uid),
      items.map(
        (item) => item.toJson(),
      ).toList(),
    );
  }

  static Future<void> clearRecent() async {
    final uid = await _getUid();

    if (uid == null) {
      return;
    }

    final prefs = await _prefs;

    await prefs.remove(
      _recentKey(uid),
    );
  }

  static Future<List<TrashItem>> loadTrash() async {
    final uid = await _getUid();

    if (uid == null) {
      return [];
    }

    final key = _trashKey(uid);

    final rawItems = await _readList(key);

    final items = <TrashItem>[];

    for (final rawItem in rawItems) {
      try {
        if (rawItem is Map) {
          items.add(
            TrashItem.fromJson(
              Map<String, dynamic>.from(rawItem),
            ),
          );
        } else if (rawItem is String) {
          try {
            final decoded = jsonDecode(rawItem);

            if (decoded is Map) {
              items.add(
                TrashItem.fromJson(
                  Map<String, dynamic>.from(decoded),
                ),
              );
            }
          } catch (_) {}
        }
      } catch (_) {}
    }

    if (items.isEmpty && rawItems.isNotEmpty) {
      final prefs = await _prefs;

      await prefs.remove(key);
    } else if (rawItems.isNotEmpty) {
      await _saveJsonList(
        key,
        items.map(
          (item) => item.toJson(),
        ).toList(),
      );
    }

    return items;
  }

  static Future<void> saveTrash(
    List<TrashItem> items,
  ) async {
    final uid = await _getUid();

    if (uid == null) {
      return;
    }

    await _saveJsonList(
      _trashKey(uid),
      items.map(
        (item) => item.toJson(),
      ).toList(),
    );
  }

  static Future<void> clearTrash() async {
    final uid = await _getUid();

    if (uid == null) {
      return;
    }

    final prefs = await _prefs;

    await prefs.remove(
      _trashKey(uid),
    );
  }

  static Future<void> clearAll() async {
    final uid = await _getUid();

    if (uid == null) {
      return;
    }

    final prefs = await _prefs;

    await prefs.remove(
      _favoritesKey(uid),
    );

    await prefs.remove(
      _recentKey(uid),
    );

    await prefs.remove(
      _trashKey(uid),
    );
  }
}