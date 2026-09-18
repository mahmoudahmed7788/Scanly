import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:scanly/Scanly_Items.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScanlyActivityService {
  static const String _favoritesKey =
      'scanly_global_favorites';

  static const String _recentKey =
      'scanly_global_recent';

  static const int _maxRecentItems = 50;

  static final ValueNotifier<int> version =
      ValueNotifier<int>(0);

  static List<ScanlyItem> _favorites = [];

  static List<ScanlyItem> _recent = [];

  static List<ScanlyItem> get favorites =>
      List.unmodifiable(_favorites);

  static List<ScanlyItem> get recent =>
      List.unmodifiable(_recent);

  static List<ScanlyItem> get favoritePreview =>
      _favorites.take(5).toList();

  static List<ScanlyItem> get recentPreview =>
      _recent.take(5).toList();

  static Future<void> init() async {
    final prefs =
        await SharedPreferences.getInstance();

    final favoritesJson =
        prefs.getStringList(_favoritesKey) ?? [];

    final recentJson =
        prefs.getStringList(_recentKey) ?? [];

    _favorites = favoritesJson
        .map(
          (item) => ScanlyItem.fromJson(
            jsonDecode(item)
                as Map<String, dynamic>,
          ),
        )
        .toList();

    _recent = recentJson
        .map(
          (item) => ScanlyItem.fromJson(
            jsonDecode(item)
                as Map<String, dynamic>,
          ),
        )
        .toList();

    version.value++;
  }

  static Future<void> _saveFavorites() async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setStringList(
      _favoritesKey,
      _favorites
          .map(
            (item) => jsonEncode(
              item.toJson(),
            ),
          )
          .toList(),
    );
  }

  static Future<void> _saveRecent() async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setStringList(
      _recentKey,
      _recent
          .map(
            (item) => jsonEncode(
              item.toJson(),
            ),
          )
          .toList(),
    );
  }

  static bool isFavorite(String id) {
    return _favorites.any(
      (item) => item.id == id,
    );
  }

  static Future<void> toggleFavorite(
    ScanlyItem item,
  ) async {
    final exists = _favorites.any(
      (oldItem) => oldItem.id == item.id,
    );

    if (exists) {
      _favorites.removeWhere(
        (oldItem) => oldItem.id == item.id,
      );
    } else {
      _favorites.insert(
        0,
        item,
      );
    }

    await _saveFavorites();

    version.value++;
  }

  static Future<void> addFavorite(
    ScanlyItem item,
  ) async {
    _favorites.removeWhere(
      (oldItem) => oldItem.id == item.id,
    );

    _favorites.insert(
      0,
      item,
    );

    await _saveFavorites();

    version.value++;
  }

  static Future<void> removeFavorite(
    String id,
  ) async {
    _favorites.removeWhere(
      (item) => item.id == id,
    );

    await _saveFavorites();

    version.value++;
  }

  static Future<void> addRecent(
    ScanlyItem item,
  ) async {
    _recent.removeWhere(
      (oldItem) => oldItem.id == item.id,
    );

    _recent.insert(
      0,
      item,
    );

    if (_recent.length > _maxRecentItems) {
      _recent =
          _recent.take(_maxRecentItems).toList();
    }

    await _saveRecent();

    version.value++;
  }

  static Future<void> removeRecent(
    String id,
  ) async {
    _recent.removeWhere(
      (item) => item.id == id,
    );

    await _saveRecent();

    version.value++;
  }

  static Future<void> clearFavorites() async {
    _favorites.clear();

    await _saveFavorites();

    version.value++;
  }

  static Future<void> clearRecent() async {
    _recent.clear();

    await _saveRecent();

    version.value++;
  }

  static Future<void> clearAll() async {
    _favorites.clear();
    _recent.clear();

    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove(_favoritesKey);
    await prefs.remove(_recentKey);

    version.value++;
  }
}

