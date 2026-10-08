import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:scanly/Core/Scanly_Items.dart';
import 'package:scanly/Service/Activity/activity_cloud_storage.dart';
import 'package:scanly/Service/Activity/activity_local_storage.dart';

class ScanlyActivityService {
  static final List<ScanlyItem> _favorites = [];
  static final List<ScanlyItem> _recent = [];
  static final List<TrashItem> _trash = [];

  static final ValueNotifier<int> version = ValueNotifier<int>(0);

  static bool _initialized = false;
  static bool _initializing = false;
  static bool _authListenerStarted = false;
  static String? _activeUid;

  static Future<void>? _initializationFuture;

  static List<ScanlyItem> get favorites {
    return List.unmodifiable(_favorites);
  }

  static List<ScanlyItem> get recent {
    return List.unmodifiable(_recent);
  }

  static List<TrashItem> get trash {
    return List.unmodifiable(_trash);
  }

  static String? get activeUid {
    return _activeUid;
  }

  static Future<void> init({
    bool force = false,
  }) async {
    _startAuthListener();

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      resetForLogout();
      return;
    }

    final uid = user.uid;

    if (_activeUid != null && _activeUid != uid) {
      _clearMemory();
      _initialized = false;
    }

    if (_initializing && _initializationFuture != null) {
      await _initializationFuture;
      return;
    }

    if (_initialized && !force && _activeUid == uid) {
      await _removeExpiredTrash();
      return;
    }

    _activeUid = uid;
    _initializing = true;

    final future = _initializeLocal(uid);
    _initializationFuture = future;

    try {
      await future;
    } finally {
      if (identical(_initializationFuture, future)) {
        _initializationFuture = null;
        _initializing = false;
      }
    }
  }

  static Future<void> _initializeLocal(String uid) async {
    try {
      await _loadLocal();

      if (_activeUid != uid ||
          FirebaseAuth.instance.currentUser?.uid != uid) {
        return;
      }

      await _removeExpiredTrash(
        notify: false,
      );

      _initialized = true;

      _notify();

      unawaited(
        _syncFromCloudInBackground(),
      );
    } catch (e) {
      debugPrint(
        'Activity local initialization error: $e',
      );
      rethrow;
    }
  }

  static Future<void> _syncFromCloudInBackground() async {
    if (FirebaseAuth.instance.currentUser == null) {
      return;
    }

    final uid = FirebaseAuth.instance.currentUser!.uid;

    if (_activeUid != uid) {
      return;
    }

    try {
      final cloudFavorites =
          await ActivityCloudStorage.loadFavorites();

      final cloudRecent =
          await ActivityCloudStorage.loadRecent();

      final cloudTrash =
          await ActivityCloudStorage.loadTrash();

      if (_activeUid != uid ||
          FirebaseAuth.instance.currentUser?.uid != uid) {
        return;
      }

      _mergeTrash(
        cloudTrash,
      );

      await _removeExpiredTrash(
        notify: false,
      );

      final trashedIds = _trash
          .map(
            (item) => item.item.id,
          )
          .toSet();

      _mergeFavorites(
        cloudFavorites,
        excludedIds: trashedIds,
      );

      _mergeRecent(
        cloudRecent,
        excludedIds: trashedIds,
      );

      await _removeItemsThatAreInTrash();

      await _saveLocal();

      await _uploadMissingItems(
        cloudFavorites,
        cloudRecent,
        cloudTrash,
      );

      _notify();
    } catch (e) {
      debugPrint(
        'Activity background cloud sync error: $e',
      );
    }
  }

  static Future<void> reload() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      resetForLogout();
      return;
    }

    await init(
      force: true,
    );
  }

  static void resetForLogout() {
    _clearMemory();

    _activeUid = null;
    _initialized = false;
    _initializing = false;
    _initializationFuture = null;

    _notify();
  }

  static void _startAuthListener() {
    if (_authListenerStarted) {
      return;
    }

    _authListenerStarted = true;

    FirebaseAuth.instance.authStateChanges().listen(
      (user) async {
        if (user == null) {
          resetForLogout();
          return;
        }

        final uid = user.uid;

        if (_activeUid == uid && _initialized) {
          return;
        }

        if (_activeUid != null && _activeUid != uid) {
          _clearMemory();

          _initialized = false;

          _notify();
        }

        try {
          await init(
            force: true,
          );
        } catch (e) {
          debugPrint(
            'Activity auth reload error: $e',
          );
        }
      },
    );
  }

  static void _clearMemory() {
    _favorites.clear();
    _recent.clear();
    _trash.clear();
  }

  static Future<void> _loadLocal() async {
    final localFavorites =
        await ActivityLocalStorage.loadFavorites();

    final localRecent =
        await ActivityLocalStorage.loadRecent();

    final localTrash =
        await ActivityLocalStorage.loadTrash();

    _favorites
      ..clear()
      ..addAll(localFavorites);

    _recent
      ..clear()
      ..addAll(localRecent);

    _trash
      ..clear()
      ..addAll(localTrash);

    await _removeItemsThatAreInTrash();

    _recent.sort(
      (a, b) => b.createdAt.compareTo(
        a.createdAt,
      ),
    );

    if (_recent.length > 50) {
      _recent.removeRange(
        50,
        _recent.length,
      );
    }

    _trash.sort(
      (a, b) => b.deletedAt.compareTo(
        a.deletedAt,
      ),
    );
  }

  static Future<void> _saveLocal() async {
    if (FirebaseAuth.instance.currentUser == null) {
      return;
    }

    await ActivityLocalStorage.saveFavorites(
      _favorites,
    );

    await ActivityLocalStorage.saveRecent(
      _recent,
    );

    await ActivityLocalStorage.saveTrash(
      _trash,
    );
  }

  static void _notify() {
    version.value++;
  }

  static void _mergeFavorites(
    List<ScanlyItem> items, {
    Set<String> excludedIds = const {},
  }) {
    final existingIds = _favorites
        .map(
          (item) => item.id,
        )
        .toSet();

    for (final item in items) {
      if (excludedIds.contains(item.id)) {
        continue;
      }

      if (!existingIds.contains(item.id)) {
        _favorites.add(item);
      }
    }
  }

  static void _mergeRecent(
    List<ScanlyItem> items, {
    Set<String> excludedIds = const {},
  }) {
    final existingIds = _recent
        .map(
          (item) => item.id,
        )
        .toSet();

    for (final item in items) {
      if (excludedIds.contains(item.id)) {
        continue;
      }

      if (!existingIds.contains(item.id)) {
        _recent.add(item);
      }
    }

    _recent.sort(
      (a, b) => b.createdAt.compareTo(
        a.createdAt,
      ),
    );

    if (_recent.length > 50) {
      _recent.removeRange(
        50,
        _recent.length,
      );
    }
  }

  static void _mergeTrash(
    List<TrashItem> items,
  ) {
    final existingIds = _trash
        .map(
          (item) => item.item.id,
        )
        .toSet();

    for (final item in items) {
      if (!existingIds.contains(item.item.id)) {
        _trash.add(item);
      }
    }

    _trash.sort(
      (a, b) => b.deletedAt.compareTo(
        a.deletedAt,
      ),
    );
  }

  static Future<void> _removeItemsThatAreInTrash() async {
    final trashIds = _trash
        .map(
          (item) => item.item.id,
        )
        .toSet();

    if (trashIds.isEmpty) {
      return;
    }

    _favorites.removeWhere(
      (item) => trashIds.contains(item.id),
    );

    _recent.removeWhere(
      (item) => trashIds.contains(item.id),
    );
  }

  static Future<void> _uploadMissingItems(
    List<ScanlyItem> cloudFavorites,
    List<ScanlyItem> cloudRecent,
    List<TrashItem> cloudTrash,
  ) async {
    final cloudFavoriteIds = cloudFavorites
        .map(
          (item) => item.id,
        )
        .toSet();

    final cloudRecentIds = cloudRecent
        .map(
          (item) => item.id,
        )
        .toSet();

    final cloudTrashIds = cloudTrash
        .map(
          (item) => item.item.id,
        )
        .toSet();

    final localTrashIds = _trash
        .map(
          (item) => item.item.id,
        )
        .toSet();

    for (final item in _favorites) {
      if (localTrashIds.contains(item.id)) {
        continue;
      }

      if (!cloudFavoriteIds.contains(item.id)) {
        try {
          await ActivityCloudStorage.saveFavorite(
            item,
          );
        } catch (_) {}
      }
    }

    for (final item in _recent) {
      if (localTrashIds.contains(item.id)) {
        continue;
      }

      if (!cloudRecentIds.contains(item.id)) {
        try {
          await ActivityCloudStorage.saveRecent(
            item,
          );
        } catch (_) {}
      }
    }

    for (final item in _trash) {
      if (!cloudTrashIds.contains(item.item.id)) {
        try {
          await ActivityCloudStorage.saveTrash(
            item,
          );
        } catch (_) {}
      }

      try {
        await ActivityCloudStorage.deleteFavorite(
          item.item.id,
        );
      } catch (_) {}

      try {
        await ActivityCloudStorage.deleteRecent(
          item.item.id,
        );
      } catch (_) {}
    }
  }

  static bool isFavorite(
    String id,
  ) {
    return _favorites.any(
      (item) => item.id == id,
    );
  }

  static bool isRecent(
    String id,
  ) {
    return _recent.any(
      (item) => item.id == id,
    );
  }

  static bool isInTrash(
    String id,
  ) {
    return _trash.any(
      (item) => item.item.id == id,
    );
  }

  static Future<void> addFavorite(
    ScanlyItem item,
  ) async {
    if (FirebaseAuth.instance.currentUser == null) {
      return;
    }

    await init();

    _trash.removeWhere(
      (trashItem) => trashItem.item.id == item.id,
    );

    _favorites.removeWhere(
      (existing) => existing.id == item.id,
    );

    _favorites.insert(
      0,
      item,
    );

    await ActivityLocalStorage.saveFavorites(
      _favorites,
    );

    await ActivityLocalStorage.saveTrash(
      _trash,
    );

    _notify();

    unawaited(
      _syncFavoriteToCloud(
        item,
      ),
    );
  }

  static Future<void> _syncFavoriteToCloud(
    ScanlyItem item,
  ) async {
    try {
      await ActivityCloudStorage.saveFavorite(
        item,
      );

      await ActivityCloudStorage.deleteTrash(
        item.id,
      );
    } catch (_) {}
  }

  static Future<void> removeFavorite(
    ScanlyItem item,
  ) async {
    await moveToTrash(item);
  }

  static Future<void> addRecent(
    ScanlyItem item,
  ) async {
    if (FirebaseAuth.instance.currentUser == null) {
      return;
    }

    await init();

    _trash.removeWhere(
      (trashItem) => trashItem.item.id == item.id,
    );

    _recent.removeWhere(
      (existing) => existing.id == item.id,
    );

    _recent.insert(
      0,
      item,
    );

    if (_recent.length > 50) {
      _recent.removeRange(
        50,
        _recent.length,
      );
    }

    await ActivityLocalStorage.saveRecent(
      _recent,
    );

    await ActivityLocalStorage.saveTrash(
      _trash,
    );

    _notify();

    unawaited(
      _syncRecentToCloud(
        item,
      ),
    );
  }

  static Future<void> _syncRecentToCloud(
    ScanlyItem item,
  ) async {
    try {
      await ActivityCloudStorage.saveRecent(
        item,
      );

      await ActivityCloudStorage.deleteTrash(
        item.id,
      );
    } catch (_) {}
  }

  static Future<void> removeRecent(
    ScanlyItem item,
  ) async {
    await moveToTrash(item);
  }

  static Future<void> moveToTrash(
    ScanlyItem item,
  ) async {
    if (FirebaseAuth.instance.currentUser == null) {
      return;
    }

    await init();

    final wasFavorite = _favorites.any(
      (existing) => existing.id == item.id,
    );

    final wasRecent = _recent.any(
      (existing) => existing.id == item.id,
    );

    _favorites.removeWhere(
      (existing) => existing.id == item.id,
    );

    _recent.removeWhere(
      (existing) => existing.id == item.id,
    );

    _trash.removeWhere(
      (trashItem) => trashItem.item.id == item.id,
    );

    final trashItem = TrashItem(
      item: item,
      wasFavorite: wasFavorite,
      wasRecent: wasRecent,
      deletedAt: DateTime.now().millisecondsSinceEpoch,
    );

    _trash.insert(
      0,
      trashItem,
    );

    await _saveLocal();

    _notify();

    unawaited(
      _syncMoveToTrashToCloud(
        item,
        wasFavorite,
        wasRecent,
        trashItem,
      ),
    );
  }

  static Future<void> _syncMoveToTrashToCloud(
    ScanlyItem item,
    bool wasFavorite,
    bool wasRecent,
    TrashItem trashItem,
  ) async {
    try {
      if (wasFavorite) {
        await ActivityCloudStorage.deleteFavorite(
          item.id,
        );
      }

      if (wasRecent) {
        await ActivityCloudStorage.deleteRecent(
          item.id,
        );
      }

      await ActivityCloudStorage.saveTrash(
        trashItem,
      );
    } catch (_) {}
  }

  static Future<void> restoreTrashItem(
    String id,
  ) async {
    if (FirebaseAuth.instance.currentUser == null) {
      return;
    }

    await init();

    final index = _trash.indexWhere(
      (item) => item.item.id == id,
    );

    if (index == -1) {
      return;
    }

    final trashItem = _trash[index];

    if (trashItem.isExpired) {
      await deleteTrashItem(id);
      return;
    }

    _trash.removeAt(index);

    if (trashItem.wasFavorite) {
      _favorites.removeWhere(
        (item) => item.id == trashItem.item.id,
      );

      _favorites.insert(
        0,
        trashItem.item,
      );
    }

    if (trashItem.wasRecent) {
      _recent.removeWhere(
        (item) => item.id == trashItem.item.id,
      );

      _recent.insert(
        0,
        trashItem.item,
      );
    }

    if (_recent.length > 50) {
      _recent.removeRange(
        50,
        _recent.length,
      );
    }

    await _saveLocal();

    _notify();

    unawaited(
      _syncRestoreToCloud(
        trashItem,
      ),
    );
  }

  static Future<void> _syncRestoreToCloud(
    TrashItem trashItem,
  ) async {
    try {
      await ActivityCloudStorage.deleteTrash(
        trashItem.item.id,
      );

      if (trashItem.wasFavorite) {
        await ActivityCloudStorage.saveFavorite(
          trashItem.item,
        );
      }

      if (trashItem.wasRecent) {
        await ActivityCloudStorage.saveRecent(
          trashItem.item,
        );
      }
    } catch (_) {}
  }

  static Future<void> deleteTrashItem(
    String id,
  ) async {
    if (FirebaseAuth.instance.currentUser == null) {
      return;
    }

    await init();

    _trash.removeWhere(
      (item) => item.item.id == id,
    );

    await ActivityLocalStorage.saveTrash(
      _trash,
    );

    _notify();

    unawaited(
      _deleteTrashFromCloud(
        id,
      ),
    );
  }

  static Future<void> _deleteTrashFromCloud(
    String id,
  ) async {
    try {
      await ActivityCloudStorage.deleteTrash(
        id,
      );
    } catch (_) {}
  }

  static Future<void> clearTrash() async {
    if (FirebaseAuth.instance.currentUser == null) {
      return;
    }

    await init();

    _trash.clear();

    await ActivityLocalStorage.clearTrash();

    _notify();

    unawaited(
      _clearTrashFromCloud(),
    );
  }

  static Future<void> _clearTrashFromCloud() async {
    try {
      await ActivityCloudStorage.clearTrash();
    } catch (_) {}
  }

  static Future<void> _removeExpiredTrash({
    bool notify = true,
  }) async {
    final expired = _trash
        .where(
          (item) => item.isExpired,
        )
        .toList();

    if (expired.isEmpty) {
      return;
    }

    for (final item in expired) {
      _trash.removeWhere(
        (trashItem) =>
            trashItem.item.id == item.item.id,
      );

      unawaited(
        _deleteTrashFromCloud(
          item.item.id,
        ),
      );
    }

    await ActivityLocalStorage.saveTrash(
      _trash,
    );

    if (notify) {
      _notify();
    }
  }

  static Future<void> cleanupTrash() async {
    await _removeExpiredTrash();
  }

  static Future<void> removeItemFromAll(
    String id,
  ) async {
    if (FirebaseAuth.instance.currentUser == null) {
      return;
    }

    await init();

    ScanlyItem? item;

    for (final favorite in _favorites) {
      if (favorite.id == id) {
        item = favorite;
        break;
      }
    }

    item ??= _recent.cast<ScanlyItem?>().firstWhere(
          (recent) => recent?.id == id,
          orElse: () => null,
        );

    if (item == null) {
      final trashIndex = _trash.indexWhere(
        (trashItem) => trashItem.item.id == id,
      );

      if (trashIndex != -1) {
        await deleteTrashItem(id);
      }

      return;
    }

    await moveToTrash(item);
  }

  static Future<void> clearQrFavorites() async {
    final qrItems = _favorites
        .where(
          (item) => _normalizeType(item.type) == 'qr',
        )
        .toList();

    for (final item in qrItems) {
      await moveToTrash(item);
    }
  }

  static Future<void> clearFavorites() async {
    final items = List<ScanlyItem>.from(
      _favorites,
    );

    for (final item in items) {
      await moveToTrash(item);
    }
  }

  static Future<void> clearRecent() async {
    final items = List<ScanlyItem>.from(
      _recent,
    );

    for (final item in items) {
      await moveToTrash(item);
    }
  }

  static Future<void> restoreItemReferences(
    ScanlyItem item, {
    bool favorite = false,
    bool recent = false,
  }) async {
    if (FirebaseAuth.instance.currentUser == null) {
      return;
    }

    await init();

    _trash.removeWhere(
      (trashItem) => trashItem.item.id == item.id,
    );

    _favorites.removeWhere(
      (existing) => existing.id == item.id,
    );

    _recent.removeWhere(
      (existing) => existing.id == item.id,
    );

    if (favorite) {
      _favorites.insert(
        0,
        item,
      );
    }

    if (recent) {
      _recent.insert(
        0,
        item,
      );
    }

    if (_recent.length > 50) {
      _recent.removeRange(
        50,
        _recent.length,
      );
    }

    await _saveLocal();

    _notify();

    unawaited(
      _syncRestoredReferencesToCloud(
        item,
        favorite,
        recent,
      ),
    );
  }

  static Future<void> _syncRestoredReferencesToCloud(
    ScanlyItem item,
    bool favorite,
    bool recent,
  ) async {
    try {
      await ActivityCloudStorage.deleteTrash(
        item.id,
      );

      if (favorite) {
        await ActivityCloudStorage.saveFavorite(
          item,
        );
      } else {
        await ActivityCloudStorage.deleteFavorite(
          item.id,
        );
      }

      if (recent) {
        await ActivityCloudStorage.saveRecent(
          item,
        );
      } else {
        await ActivityCloudStorage.deleteRecent(
          item.id,
        );
      }
    } catch (_) {}
  }

  static String _normalizeType(
    String type,
  ) {
    final normalized = type
        .toLowerCase()
        .trim()
        .replaceAll('-', '_')
        .replaceAll(' ', '_');

    if (normalized == 'qr' ||
        normalized == 'qrcode' ||
        normalized == 'qr_code') {
      return 'qr';
    }

    if (normalized == 'note' ||
        normalized == 'notes') {
      return 'note';
    }

    if (normalized == 'image_to_text' ||
        normalized == 'imagetotext' ||
        normalized == 'ocr') {
      return 'image_to_text';
    }

    return normalized;
  }
}