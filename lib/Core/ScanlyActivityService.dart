import 'package:flutter/foundation.dart';
import 'package:scanly/Core/Scanly_Items.dart';
import 'package:scanly/Service/Activity/activity_cloud_storage.dart';
import 'package:scanly/Service/Activity/activity_local_storage.dart';

class ScanlyActivityService {
  static const int _maxRecentItems = 50;

  static final ActivityLocalStorage _localStorage =
      ActivityLocalStorage();

  static final ActivityCloudStorage _cloudStorage =
      ActivityCloudStorage();

  static final ValueNotifier<int> version =
      ValueNotifier<int>(0);

  static List<ScanlyItem> _favorites = [];

  static List<ScanlyItem> _recent = [];

  // ============================================================
  // GETTERS
  // ============================================================

  static List<ScanlyItem> get favorites =>
      List.unmodifiable(_favorites);

  static List<ScanlyItem> get recent =>
      List.unmodifiable(_recent);

  static List<ScanlyItem> get favoritePreview =>
      _favorites.take(5).toList();

  static List<ScanlyItem> get recentPreview =>
      _recent.take(5).toList();

  // ============================================================
  // INIT
  // ============================================================

  static Future<void> init() async {
    await _loadLocal();

    try {
      await _loadFromCloud();
    } catch (e) {
      debugPrint(
        'Activity cloud sync failed: $e',
      );
    }

    _notify();
  }

  // ============================================================
  // LOAD LOCAL
  // ============================================================

  static Future<void> _loadLocal() async {
    _favorites =
        await _localStorage.loadFavorites();

    _recent =
        await _localStorage.loadRecent();
  }

  // ============================================================
  // LOAD CLOUD
  // ============================================================

  static Future<void> _loadFromCloud() async {
    final cloudFavorites =
        await _cloudStorage.loadFavorites();

    final cloudRecent =
        await _cloudStorage.loadRecent();

    // If there is no logged-in user,
    // cloud storage simply returns empty lists.
    //
    // Local cache remains untouched in that case.
    if (cloudFavorites.isEmpty &&
        cloudRecent.isEmpty) {
      return;
    }

    _favorites = cloudFavorites;

    _recent = cloudRecent;

    await _saveLocal();
  }

  // ============================================================
  // FAVORITE
  // ============================================================

  static bool isFavorite(
    String id,
  ) {
    return _favorites.any(
      (item) => item.id == id,
    );
  }

  static Future<void> toggleFavorite(
    ScanlyItem item,
  ) async {
    if (isFavorite(item.id)) {
      await removeFavorite(item.id);
    } else {
      await addFavorite(item);
    }
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

    await _localStorage.saveFavorites(
      _favorites,
    );

    await _cloudStorage.saveFavorite(
      item,
    );

    _notify();
  }

  static Future<void> removeFavorite(
    String id,
  ) async {
    _favorites.removeWhere(
      (item) => item.id == id,
    );

    await _localStorage.saveFavorites(
      _favorites,
    );

    await _cloudStorage.deleteFavorite(
      id,
    );

    _notify();
  }

  // ============================================================
  // RECENT
  // ============================================================

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
      _recent = _recent
          .take(_maxRecentItems)
          .toList();
    }

    await _localStorage.saveRecent(
      _recent,
    );

    await _cloudStorage.saveRecent(
      item,
    );

    _notify();
  }

  static Future<void> removeRecent(
    String id,
  ) async {
    _recent.removeWhere(
      (item) => item.id == id,
    );

    await _localStorage.saveRecent(
      _recent,
    );

    await _cloudStorage.deleteRecent(
      id,
    );

    _notify();
  }

  // ============================================================
  // CLEAR FAVORITES
  // ============================================================

  static Future<void> clearFavorites() async {
    _favorites.clear();

    await _localStorage.clearFavorites();

    await _cloudStorage.clearFavorites();

    _notify();
  }

  // ============================================================
  // CLEAR RECENT
  // ============================================================

  static Future<void> clearRecent() async {
    _recent.clear();

    await _localStorage.clearRecent();

    await _cloudStorage.clearRecent();

    _notify();
  }

  // ============================================================
  // CLEAR EVERYTHING
  // ============================================================

  static Future<void> clearAll() async {
    _favorites.clear();
    _recent.clear();

    await _localStorage.clearAll();

    await _cloudStorage.clearAll();

    _notify();
  }

  // ============================================================
  // SAVE LOCAL
  // ============================================================

  static Future<void> _saveLocal() async {
    await _localStorage.saveFavorites(
      _favorites,
    );

    await _localStorage.saveRecent(
      _recent,
    );
  }

  // ============================================================
  // NOTIFY
  // ============================================================

  static void _notify() {
    version.value++;
  }
}