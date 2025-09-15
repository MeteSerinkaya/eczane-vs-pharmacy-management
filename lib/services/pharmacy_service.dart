import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/pharmacy_model.dart';

class PharmacyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get all pharmacies for a city and district
  Future<List<Pharmacy>> getPharmacies({
    required String city,
    String? district,
  }) async {
    try {
      Query query = _firestore
          .collection('pharmacies')
          .where('city', isEqualTo: city);

      if (district != null && district.isNotEmpty) {
        query = query.where('district', isEqualTo: district);
      }

      final snapshot = await query.get();
      final userFavorites = await getUserFavorites();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Pharmacy(
          id: doc.id,
          name: data['name'] ?? '',
          district: data['district'] ?? '',
          city: data['city'] ?? '',
          address: data['address'] ?? '',
          phone: data['phone'] ?? '',
          isFavorite: userFavorites.contains(doc.id),
        );
      }).toList();
    } catch (e) {
      throw Exception('Eczaneler alınırken bir hata oluştu: $e');
    }
  }

  // Get all cities
  Future<List<String>> getCities() async {
    try {
      final snapshot = await _firestore.collection('pharmacies').get();

      return snapshot.docs
          .map((doc) => (doc.data())['city'] as String)
          .toSet() // Remove duplicates
          .toList()
        ..sort(); // Sort alphabetically
    } catch (e) {
      throw Exception('Şehirler alınırken bir hata oluştu: $e');
    }
  }

  // Get districts for a city
  Future<List<String>> getDistricts(String city) async {
    try {
      final snapshot = await _firestore
          .collection('pharmacies')
          .where('city', isEqualTo: city)
          .get();

      return snapshot.docs
          .map((doc) => (doc.data())['district'] as String)
          .toSet() // Remove duplicates
          .toList()
        ..sort(); // Sort alphabetically
    } catch (e) {
      throw Exception('İlçeler alınırken bir hata oluştu: $e');
    }
  }

  // Get user's favorite pharmacies
  Future<Set<String>> getUserFavorites() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {};

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .get();

      return snapshot.docs.map((doc) => doc.id).toSet();
    } catch (e) {
      print('Error getting user favorites: $e');
      return {};
    }
  }

  // Toggle favorite status
  Future<void> toggleFavorite(Pharmacy pharmacy) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Kullanıcı girişi yapılmamış');

      final favoriteRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc(pharmacy.id);

      final favoriteDoc = await favoriteRef.get();

      if (favoriteDoc.exists) {
        await favoriteRef.delete();
      } else {
        await favoriteRef.set({'addedAt': FieldValue.serverTimestamp()});
      }
    } catch (e) {
      throw Exception('Favori durumu güncellenirken bir hata oluştu: $e');
    }
  }

  // Get favorite pharmacies
  Future<List<Pharmacy>> getFavoritePharmacies() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final favoriteIds = await getUserFavorites();
      if (favoriteIds.isEmpty) return [];

      final snapshot = await _firestore
          .collection('pharmacies')
          .where(FieldPath.documentId, whereIn: favoriteIds.toList())
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Pharmacy(
          id: doc.id,
          name: data['name'] ?? '',
          district: data['district'] ?? '',
          city: data['city'] ?? '',
          address: data['address'] ?? '',
          phone: data['phone'] ?? '',
          isFavorite: true,
        );
      }).toList();
    } catch (e) {
      throw Exception('Favori eczaneler alınırken bir hata oluştu: $e');
    }
  }
}
