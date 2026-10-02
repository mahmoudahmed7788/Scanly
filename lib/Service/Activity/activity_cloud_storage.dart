import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:scanly/Core/Scanly_Items.dart';
import 'package:scanly/Service/Activity/activity_local_storage.dart';

class ActivityCloudStorage {
  static FirebaseFirestore get _firestore {
    return FirebaseFirestore.instance;
  }

  static User? get _user {
    return FirebaseAuth.instance.currentUser;
  }

  static CollectionReference<Map<String, dynamic>>? get _favoritesCollection {
    final user = _user;

    if (user == null) {
      return null;
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('favorites');
  }

  static CollectionReference<Map<String, dynamic>>? get _recentCollection {
    final user = _user;

    if (user == null) {
      return null;
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('recent');
  }

  static CollectionReference<Map<String, dynamic>>? get _trashCollection {
    final user = _user;

    if (user == null) {
      return null;
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('trash');
  }

  static Future<void> saveFavorite(ScanlyItem item) async {
    final collection = _favoritesCollection;

    if (collection == null) {
      return;
    }

    await collection.doc(item.id).set(item.toJson());
  }

  static Future<void> deleteFavorite(String id) async {
    final collection = _favoritesCollection;

    if (collection == null) {
      return;
    }

    await collection.doc(id).delete();
  }

  static Future<List<ScanlyItem>> loadFavorites() async {
    final collection = _favoritesCollection;

    if (collection == null) {
      return [];
    }

    final snapshot = await collection.get();

    return snapshot.docs
        .map(
          (doc) => ScanlyItem.fromJson(doc.data()),
        )
        .toList();
  }

  static Future<void> clearFavorites() async {
    final collection = _favoritesCollection;

    if (collection == null) {
      return;
    }

    final snapshot = await collection.get();

    if (snapshot.docs.isEmpty) {
      return;
    }

    final batch = _firestore.batch();

    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  static Future<void> saveRecent(ScanlyItem item) async {
    final collection = _recentCollection;

    if (collection == null) {
      return;
    }

    await collection.doc(item.id).set(item.toJson());
  }

  static Future<void> deleteRecent(String id) async {
    final collection = _recentCollection;

    if (collection == null) {
      return;
    }

    await collection.doc(id).delete();
  }

  static Future<List<ScanlyItem>> loadRecent() async {
    final collection = _recentCollection;

    if (collection == null) {
      return [];
    }

    final snapshot = await collection.get();

    return snapshot.docs
        .map(
          (doc) => ScanlyItem.fromJson(doc.data()),
        )
        .toList();
  }

  static Future<void> clearRecent() async {
    final collection = _recentCollection;

    if (collection == null) {
      return;
    }

    final snapshot = await collection.get();

    if (snapshot.docs.isEmpty) {
      return;
    }

    final batch = _firestore.batch();

    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  static Future<void> saveTrash(TrashItem trashItem) async {
    final collection = _trashCollection;

    if (collection == null) {
      return;
    }

    await collection.doc(trashItem.item.id).set(
      trashItem.toJson(),
    );
  }

  static Future<void> deleteTrash(String id) async {
    final collection = _trashCollection;

    if (collection == null) {
      return;
    }

    await collection.doc(id).delete();
  }

  static Future<List<TrashItem>> loadTrash() async {
    final collection = _trashCollection;

    if (collection == null) {
      return [];
    }

    final snapshot = await collection.get();

    return snapshot.docs
        .map(
          (doc) => TrashItem.fromJson(doc.data()),
        )
        .toList();
  }

  static Future<void> clearTrash() async {
    final collection = _trashCollection;

    if (collection == null) {
      return;
    }

    final snapshot = await collection.get();

    if (snapshot.docs.isEmpty) {
      return;
    }

    final batch = _firestore.batch();

    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  static Future<void> clearAll() async {
    await clearFavorites();
    await clearRecent();
    await clearTrash();
  }
}