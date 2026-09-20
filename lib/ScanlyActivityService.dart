import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:scanly/Scanly_Items.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScanlyActivityService {
  static const String _favoritesKey =
      'scanly_global_favorites';

  static const String _recentKey =
      'scanly_global_recent';

  static const int _maxRecentItems = 50;

  static final FirebaseAuth _auth =
      FirebaseAuth.instance;

  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

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

  static User? get _user =>
      _auth.currentUser;

  // ============================================================
  // FIRESTORE COLLECTIONS
  // ============================================================

  static CollectionReference<Map<String, dynamic>>
      get _favoritesCollection {
    final user = _user;

    if (user == null) {
      throw Exception(
        'No authenticated user.',
      );
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('favorites');
  }

  static CollectionReference<Map<String, dynamic>>
      get _recentCollection {
    final user = _user;

    if (user == null) {
      throw Exception(
        'No authenticated user.',
      );
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('recent');
  }

  // ============================================================
  // INIT
  // ============================================================

  static Future<void> init() async {
    // Load local cache first.
    await _loadLocal();

    // Firebase is the source of truth.
    if (_user != null) {
      try {
        await _loadFromCloud();
      } catch (e) {
        debugPrint(
          'Activity cloud sync failed: $e',
        );
      }
    }

    version.value++;
  }

  // ============================================================
  // LOAD LOCAL
  // ============================================================

  static Future<void> _loadLocal() async {
    final prefs =
        await SharedPreferences.getInstance();

    final favoritesJson =
        prefs.getStringList(
              _favoritesKey,
            ) ??
            [];

    final recentJson =
        prefs.getStringList(
              _recentKey,
            ) ??
            [];

    _favorites = _decodeItems(
      favoritesJson,
    );

    _recent = _decodeItems(
      recentJson,
    );
  }

  // ============================================================
  // DECODE
  // ============================================================

  static List<ScanlyItem> _decodeItems(
    List<String> data,
  ) {
    final result = <ScanlyItem>[];

    for (final item in data) {
      try {
        final decoded = jsonDecode(item);

        if (decoded is Map) {
          result.add(
            ScanlyItem.fromJson(
              Map<String, dynamic>.from(
                decoded,
              ),
            ),
          );
        }
      } catch (_) {}
    }

    return result;
  }

  // ============================================================
  // LOCAL FAVORITES
  // ============================================================

  static Future<void> _saveFavoritesLocal() async {
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

  // ============================================================
  // LOCAL RECENT
  // ============================================================

  static Future<void> _saveRecentLocal() async {
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

  // ============================================================
  // IS FAVORITE
  // ============================================================

  static bool isFavorite(
    String id,
  ) {
    return _favorites.any(
      (item) => item.id == id,
    );
  }

  // ============================================================
  // TOGGLE FAVORITE
  // ============================================================

  static Future<void> toggleFavorite(
    ScanlyItem item,
  ) async {
    if (isFavorite(item.id)) {
      await removeFavorite(
        item.id,
      );
    } else {
      await addFavorite(
        item,
      );
    }
  }

  // ============================================================
  // ADD FAVORITE
  // ============================================================

  static Future<void> addFavorite(
    ScanlyItem item,
  ) async {
    _favorites.removeWhere(
      (oldItem) =>
          oldItem.id == item.id,
    );

    _favorites.insert(
      0,
      item,
    );

    await _saveFavoritesLocal();

    if (_user != null) {
      try {
        await _favoritesCollection
            .doc(item.id)
            .set(
          {
            ...item.toJson(),
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
          SetOptions(
            merge: true,
          ),
        );
      } catch (e) {
        debugPrint(
          'Cloud favorite save failed: $e',
        );
      }
    }

    version.value++;
  }

  // ============================================================
  // REMOVE FAVORITE
  // ============================================================

  static Future<void> removeFavorite(
    String id,
  ) async {
    _favorites.removeWhere(
      (item) => item.id == id,
    );

    await _saveFavoritesLocal();

    if (_user != null) {
      try {
        await _favoritesCollection
            .doc(id)
            .delete();
      } catch (e) {
        debugPrint(
          'Cloud favorite delete failed: $e',
        );
      }
    }

    version.value++;
  }

  // ============================================================
  // ADD RECENT
  // ============================================================

  static Future<void> addRecent(
    ScanlyItem item,
  ) async {
    _recent.removeWhere(
      (oldItem) =>
          oldItem.id == item.id,
    );

    _recent.insert(
      0,
      item,
    );

    if (_recent.length >
        _maxRecentItems) {
      _recent = _recent
          .take(
            _maxRecentItems,
          )
          .toList();
    }

    await _saveRecentLocal();

    if (_user != null) {
      try {
        await _recentCollection
            .doc(item.id)
            .set(
          {
            ...item.toJson(),
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
          SetOptions(
            merge: true,
          ),
        );

        await _cleanupCloudRecent();
      } catch (e) {
        debugPrint(
          'Cloud recent save failed: $e',
        );
      }
    }

    version.value++;
  }

  // ============================================================
  // CLEAN OLD RECENT
  // ============================================================

  static Future<void> _cleanupCloudRecent() async {
    if (_user == null) {
      return;
    }

    try {
      final snapshot =
          await _recentCollection.get();

      final documents =
          snapshot.docs.toList();

      documents.sort(
        (a, b) {
          final aData = a.data();
          final bData = b.data();

          final aTimestamp =
              aData['updatedAt'];

          final bTimestamp =
              bData['updatedAt'];

          if (aTimestamp is Timestamp &&
              bTimestamp is Timestamp) {
            return bTimestamp.compareTo(
              aTimestamp,
            );
          }

          if (aTimestamp is Timestamp) {
            return -1;
          }

          if (bTimestamp is Timestamp) {
            return 1;
          }

          return 0;
        },
      );

      if (documents.length <=
          _maxRecentItems) {
        return;
      }

      final batch =
          _firestore.batch();

      for (final doc
          in documents.skip(
        _maxRecentItems,
      )) {
        batch.delete(
          doc.reference,
        );
      }

      await batch.commit();
    } catch (e) {
      debugPrint(
        'Cloud recent cleanup failed: $e',
      );
    }
  }

  // ============================================================
  // REMOVE RECENT
  // ============================================================

  static Future<void> removeRecent(
    String id,
  ) async {
    _recent.removeWhere(
      (item) => item.id == id,
    );

    await _saveRecentLocal();

    if (_user != null) {
      try {
        await _recentCollection
            .doc(id)
            .delete();
      } catch (e) {
        debugPrint(
          'Cloud recent delete failed: $e',
        );
      }
    }

    version.value++;
  }

  // ============================================================
  // CLEAR FAVORITES
  // ============================================================

  static Future<void> clearFavorites() async {
    _favorites.clear();

    await _saveFavoritesLocal();

    if (_user != null) {
      try {
        await _deleteCollection(
          _favoritesCollection,
        );
      } catch (e) {
        debugPrint(
          'Cloud clear favorites failed: $e',
        );
      }
    }

    version.value++;
  }

  // ============================================================
  // CLEAR RECENT
  // ============================================================

  static Future<void> clearRecent() async {
    _recent.clear();

    await _saveRecentLocal();

    if (_user != null) {
      try {
        await _deleteCollection(
          _recentCollection,
        );
      } catch (e) {
        debugPrint(
          'Cloud clear recent failed: $e',
        );
      }
    }

    version.value++;
  }

  // ============================================================
  // CLEAR FIRESTORE COLLECTION
  // ============================================================

  static Future<void> _deleteCollection(
    CollectionReference<Map<String, dynamic>>
        collection,
  ) async {
    final snapshot =
        await collection.get();

    if (snapshot.docs.isEmpty) {
      return;
    }

    final batch =
        _firestore.batch();

    for (final doc
        in snapshot.docs) {
      batch.delete(
        doc.reference,
      );
    }

    await batch.commit();
  }

  // ============================================================
  // CLEAR EVERYTHING
  // ============================================================

  static Future<void> clearAll() async {
    await clearFavorites();
    await clearRecent();

    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove(
      _favoritesKey,
    );

    await prefs.remove(
      _recentKey,
    );

    version.value++;
  }

  // ============================================================
  // LOAD FROM FIRESTORE
  // ============================================================

  static Future<void> _loadFromCloud() async {
    final user = _user;

    if (user == null) {
      return;
    }

    // ----------------------------------------------------------
    // Favorites
    // ----------------------------------------------------------

    final favoritesSnapshot =
        await _favoritesCollection.get();

    _favorites = favoritesSnapshot.docs
        .map(
          (doc) => ScanlyItem.fromJson(
            Map<String, dynamic>.from(
              doc.data(),
            ),
          ),
        )
        .toList();

    // ----------------------------------------------------------
    // Recent
    //
    // Don't use Firestore orderBy here.
    // This avoids problems with old documents
    // that don't have updatedAt.
    // ----------------------------------------------------------

    final recentSnapshot =
        await _recentCollection.get();

    final recentItems =
        <MapEntry<ScanlyItem, DateTime>>[];

    for (final doc
        in recentSnapshot.docs) {
      try {
        final data =
            Map<String, dynamic>.from(
          doc.data(),
        );

        final item =
            ScanlyItem.fromJson(data);

        final timestamp =
            data['updatedAt'];

        DateTime updatedAt;

        if (timestamp is Timestamp) {
          updatedAt =
              timestamp.toDate();
        } else {
          updatedAt =
              DateTime.fromMillisecondsSinceEpoch(
            0,
          );
        }

        recentItems.add(
          MapEntry(
            item,
            updatedAt,
          ),
        );
      } catch (e) {
        debugPrint(
          'Recent item parse error: $e',
        );
      }
    }

    recentItems.sort(
      (a, b) =>
          b.value.compareTo(
        a.value,
      ),
    );

    _recent = recentItems
        .take(
          _maxRecentItems,
        )
        .map(
          (entry) => entry.key,
        )
        .toList();

    // ----------------------------------------------------------
    // Update local cache
    // ----------------------------------------------------------

    await _saveFavoritesLocal();
    await _saveRecentLocal();
  }
}