import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:scanly/Core/Scanly_Items.dart';

class ActivityCloudStorage {
  static const int maxRecentItems = 50;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  ActivityCloudStorage({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  User? get _user => _auth.currentUser;

  CollectionReference<Map<String, dynamic>>
      get _favoritesCollection {
    final user = _user;

    if (user == null) {
      throw Exception('No authenticated user.');
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('favorites');
  }

  CollectionReference<Map<String, dynamic>>
      get _recentCollection {
    final user = _user;

    if (user == null) {
      throw Exception('No authenticated user.');
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('recent');
  }

  Future<void> saveFavorite(
    ScanlyItem item,
  ) async {
    if (_user == null) {
      return;
    }

    try {
      await _favoritesCollection
          .doc(item.id)
          .set(
        {
          ...item.toJson(),
          'updatedAt': FieldValue.serverTimestamp(),
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

  Future<void> deleteFavorite(
    String id,
  ) async {
    if (_user == null) {
      return;
    }

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

  Future<void> saveRecent(
    ScanlyItem item,
  ) async {
    if (_user == null) {
      return;
    }

    try {
      await _recentCollection
          .doc(item.id)
          .set(
        {
          ...item.toJson(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(
          merge: true,
        ),
      );

      await cleanupRecent();
    } catch (e) {
      debugPrint(
        'Cloud recent save failed: $e',
      );
    }
  }

  Future<void> deleteRecent(
    String id,
  ) async {
    if (_user == null) {
      return;
    }

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

  Future<void> clearFavorites() async {
    if (_user == null) {
      return;
    }

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

  Future<void> clearRecent() async {
    if (_user == null) {
      return;
    }

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

  Future<List<ScanlyItem>> loadFavorites() async {
    if (_user == null) {
      return [];
    }

    final snapshot =
        await _favoritesCollection.get();

    final items = <ScanlyItem>[];

    for (final doc in snapshot.docs) {
      try {
        items.add(
          ScanlyItem.fromJson(
            Map<String, dynamic>.from(
              doc.data(),
            ),
          ),
        );
      } catch (e) {
        debugPrint(
          'Favorite item parse error: $e',
        );
      }
    }

    return items;
  }

  Future<List<ScanlyItem>> loadRecent() async {
    if (_user == null) {
      return [];
    }

    final snapshot =
        await _recentCollection.get();

    final recentItems =
        <MapEntry<ScanlyItem, DateTime>>[];

    for (final doc in snapshot.docs) {
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
          updatedAt = timestamp.toDate();
        } else {
          updatedAt =
              DateTime.fromMillisecondsSinceEpoch(0);
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
      (a, b) => b.value.compareTo(
        a.value,
      ),
    );

    return recentItems
        .take(maxRecentItems)
        .map(
          (entry) => entry.key,
        )
        .toList();
  }

  Future<void> cleanupRecent() async {
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
          final aTimestamp =
              a.data()['updatedAt'];

          final bTimestamp =
              b.data()['updatedAt'];

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

      if (documents.length <= maxRecentItems) {
        return;
      }

      final batch = _firestore.batch();

      for (final doc
          in documents.skip(maxRecentItems)) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      debugPrint(
        'Cloud recent cleanup failed: $e',
      );
    }
  }

  Future<void> clearAll() async {
    await clearFavorites();
    await clearRecent();
  }

  Future<void> _deleteCollection(
    CollectionReference<Map<String, dynamic>>
        collection,
  ) async {
    final snapshot =
        await collection.get();

    if (snapshot.docs.isEmpty) {
      return;
    }

    final batch = _firestore.batch();

    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
}