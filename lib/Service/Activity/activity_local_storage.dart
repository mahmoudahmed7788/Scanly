import 'dart:convert';

import 'package:scanly/Core/Scanly_Items.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ActivityLocalStorage {
  static const String _favoritesKey = 'scanly_global_favorites';
  static const String _recentKey = 'scanly_global_recent';

  Future<List<ScanlyItem>> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();

    final data = prefs.getStringList(_favoritesKey) ?? [];

    return _decodeItems(data);
  }

  Future<List<ScanlyItem>> loadRecent() async {
    final prefs = await SharedPreferences.getInstance();

    final data = prefs.getStringList(_recentKey) ?? [];

    return _decodeItems(data);
  }

  Future<void> saveFavorites(
    List<ScanlyItem> items,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(
      _favoritesKey,
      _encodeItems(items),
    );
  }

  Future<void> saveRecent(
    List<ScanlyItem> items,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(
      _recentKey,
      _encodeItems(items),
    );
  }

  Future<void> clearFavorites() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_favoritesKey);
  }

  Future<void> clearRecent() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_recentKey);
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_favoritesKey);
    await prefs.remove(_recentKey);
  }

  List<String> _encodeItems(
    List<ScanlyItem> items,
  ) {
    return items
        .map(
          (item) => jsonEncode(
            item.toJson(),
          ),
        )
        .toList();
  }

  List<ScanlyItem> _decodeItems(
    List<String> data,
  ) {
    final result = <ScanlyItem>[];

    for (final item in data) {
      try {
        final decoded = jsonDecode(item);

        if (decoded is Map) {
          result.add(
            ScanlyItem.fromJson(
              Map<String, dynamic>.from(decoded),
            ),
          );
        }
      } catch (_) {
        // Ignore invalid cached items.
      }
    }

    return result;
  }
}
