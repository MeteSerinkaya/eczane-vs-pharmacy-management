import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // CREATE OPERATIONS
  Future<void> createUser({
    required String uid,
    required String email,
    required String city,
    required String district,
  }) async {
    final userRef = _firestore.collection('users').doc(uid);

    await userRef.set({
      'uid': uid,
      'email': email,
      'city': city,
      'district': district,
      'createdAt': FieldValue.serverTimestamp(),
      'lastLogin': FieldValue.serverTimestamp(),
    });
  }

  // UPDATE OPERATIONS
  Future<void> updateLastLogin(String uid) async {
    final userRef = _firestore.collection('users').doc(uid);
    await userRef.update({'lastLogin': FieldValue.serverTimestamp()});
  }

  // READ OPERATIONS
  Future<Map<String, dynamic>?> getUser(String uid) async {
    try {
      final userRef = _firestore.collection('users').doc(uid);
      final doc = await userRef.get();

      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      print('Error getting all users: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    try {
      final snapshot = await _firestore.collection('users').where('email', isEqualTo: email).limit(1).get();

      if (snapshot.docs.isNotEmpty) {
        return {'id': snapshot.docs.first.id, ...snapshot.docs.first.data()};
      }
      return null;
    } catch (e) {
      print('Error getting user by email: $e');
      return null;
    }
  }

  // DELETE OPERATIONS
  Future<void> deleteUser(String uid) async {
    try {
      final userRef = _firestore.collection('users').doc(uid);
      await userRef.delete();
    } catch (e) {
      print('Error deleting user: $e');
      rethrow;
    }
  }

  Future<void> deleteUserData(String uid) async {
    try {
      final batch = _firestore.batch();

      // Delete user document
      final userRef = _firestore.collection('users').doc(uid);
      batch.delete(userRef);

      // Delete user's favorites subcollection
      final favoritesSnapshot = await _firestore.collection('users').doc(uid).collection('favorites').get();

      for (var doc in favoritesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      print('Error deleting user data: $e');
      rethrow;
    }
  }
}
