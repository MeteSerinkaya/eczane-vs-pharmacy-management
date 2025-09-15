import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'api_service.dart';

class PharmacyMigrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ApiService _apiService = ApiService();

  // Turkish cities list
  final List<String> cities = [
    'ADANA',
    'ADIYAMAN',
    'AFYONKARAHİSAR',
    'AĞRI',
    'AMASYA',
    'ANKARA',
    'ANTALYA',
    'ARTVİN',
    'AYDIN',
    'BALIKESİR',
    'BİLECİK',
    'BİNGÖL',
    'BİTLİS',
    'BOLU',
    'BURDUR',
    'BURSA',
    'ÇANAKKALE',
    'ÇANKIRI',
    'ÇORUM',
    'DENİZLİ',
    'DİYARBAKIR',
    'EDİRNE',
    'ELAZIĞ',
    'ERZİNCAN',
    'ERZURUM',
    'ESKİŞEHİR',
    'GAZİANTEP',
    'GİRESUN',
    'GÜMÜŞHANE',
    'HAKKARİ',
    'HATAY',
    'ISPARTA',
    'MERSİN',
    'İSTANBUL',
    'İZMİR',
    'KARS',
    'KASTAMONU',
    'KAYSERİ',
    'KIRKLARELİ',
    'KIRŞEHİR',
    'KOCAELİ',
    'KONYA',
    'KÜTAHYA',
    'MALATYA',
    'MANİSA',
    'KAHRAMANMARAŞ',
    'MARDİN',
    'MUĞLA',
    'MUŞ',
    'NEVŞEHİR',
    'NİĞDE',
    'ORDU',
    'RİZE',
    'SAKARYA',
    'SAMSUN',
    'SİİRT',
    'SİNOP',
    'SİVAS',
    'TEKİRDAĞ',
    'TOKAT',
    'TRABZON',
    'TUNCELİ',
    'ŞANLIURFA',
    'UŞAK',
    'VAN',
    'YOZGAT',
    'ZONGULDAK',
    'AKSARAY',
    'BAYBURT',
    'KARAMAN',
    'KIRIKKALE',
    'BATMAN',
    'ŞIRNAK',
    'BARTIN',
    'ARDAHAN',
    'IĞDIR',
    'YALOVA',
    'KARABÜK',
    'KİLİS',
    'OSMANİYE',
    'DÜZCE',
  ];

  // Check if user is admin
  Future<bool> _isAdmin() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final doc = await _firestore.collection('admins').doc(user.uid).get();
      return doc.exists;
    } catch (e) {
      print('Admin check error: $e');
      return false;
    }
  }

  // Start migration for all cities
  Future<void> migrateAllPharmacies() async {
    if (!await _isAdmin()) {
      throw Exception('Bu işlem için yönetici yetkisi gerekiyor');
    }

    final batch = _firestore.batch();
    int totalPharmacies = 0;
    int processedCities = 0;
    int batchCount = 0;

    try {
      // Create a collection reference
      final collectionRef = _firestore.collection('pharmacies');

      // Process each city
      for (String city in cities) {
        print('Processing city: $city');

        try {
          // Get pharmacies from API
          final pharmacies = await _apiService.getDutyPharmacies(city: city);

          // Process each pharmacy
          for (var pharmacy in pharmacies) {
            final docRef = collectionRef.doc();
            batch.set(docRef, {
              'id': docRef.id,
              'name': pharmacy.name,
              'district': pharmacy.district,
              'city': city,
              'address': pharmacy.address,
              'phone': pharmacy.phone,
              'lastUpdated': FieldValue.serverTimestamp(),
            });

            totalPharmacies++;
            batchCount++;

            // Commit batch every 400 operations to avoid memory issues
            if (batchCount >= 400) {
              await batch.commit();
              print('Committed batch of $batchCount pharmacies');
              batchCount = 0;
            }
          }

          processedCities++;
          print(
            'Processed $processedCities cities, total pharmacies: $totalPharmacies',
          );

          // Add delay to avoid API rate limits
          await Future.delayed(const Duration(seconds: 2));
        } catch (e) {
          print('Error processing city $city: $e');
          // Continue with next city even if one fails
        }
      }

      // Commit any remaining operations
      if (batchCount > 0) {
        await batch.commit();
        print('Committed final batch of $batchCount pharmacies');
      }

      print('Migration completed successfully!');
      print('Total cities processed: $processedCities');
      print('Total pharmacies added: $totalPharmacies');
    } catch (e) {
      print('Migration failed: $e');
      throw Exception('Veri aktarımı sırasında bir hata oluştu: $e');
    }
  }

  // Get migration status
  Future<Map<String, dynamic>> getMigrationStatus() async {
    if (!await _isAdmin()) {
      throw Exception('Bu işlem için yönetici yetkisi gerekiyor');
    }

    try {
      final snapshot = await _firestore.collection('pharmacies').get();
      final citiesInDb = snapshot.docs
          .map((doc) => doc.data()['city'] as String)
          .toSet();

      return {
        'totalCities': cities.length,
        'citiesInDb': citiesInDb.length,
        'missingCities': cities
            .where((city) => !citiesInDb.contains(city))
            .toList(),
        'totalPharmacies': snapshot.docs.length,
      };
    } catch (e) {
      throw Exception('Migrasyon durumu alınırken bir hata oluştu: $e');
    }
  }

  // Migrate specific cities
  Future<void> migrateCities(List<String> citiesToMigrate) async {
    if (!await _isAdmin()) {
      throw Exception('Bu işlem için yönetici yetkisi gerekiyor');
    }

    if (citiesToMigrate.isEmpty) {
      throw Exception('Migrasyon için en az bir şehir seçilmelidir');
    }

    final batch = _firestore.batch();
    int totalPharmacies = 0;
    int processedCities = 0;
    int batchCount = 0;

    try {
      final collectionRef = _firestore.collection('pharmacies');

      for (String city in citiesToMigrate) {
        if (!cities.contains(city)) {
          print('Invalid city: $city - skipping');
          continue;
        }

        print('Processing city: $city');

        try {
          final pharmacies = await _apiService.getDutyPharmacies(city: city);

          for (var pharmacy in pharmacies) {
            final docRef = collectionRef.doc();
            batch.set(docRef, {
              'id': docRef.id,
              'name': pharmacy.name,
              'district': pharmacy.district,
              'city': city,
              'address': pharmacy.address,
              'phone': pharmacy.phone,
              'lastUpdated': FieldValue.serverTimestamp(),
            });

            totalPharmacies++;
            batchCount++;

            if (batchCount >= 400) {
              await batch.commit();
              print('Committed batch of $batchCount pharmacies');
              batchCount = 0;
            }
          }

          processedCities++;
          print(
            'Processed $processedCities cities, total pharmacies: $totalPharmacies',
          );

          await Future.delayed(const Duration(seconds: 2));
        } catch (e) {
          print('Error processing city $city: $e');
        }
      }

      if (batchCount > 0) {
        await batch.commit();
        print('Committed final batch of $batchCount pharmacies');
      }

      print('Migration completed successfully!');
      print('Total cities processed: $processedCities');
      print('Total pharmacies added: $totalPharmacies');
    } catch (e) {
      print('Migration failed: $e');
      throw Exception('Veri aktarımı sırasında bir hata oluştu: $e');
    }
  }

  // Update duty status for pharmacies
  Future<void> updateDutyStatus(String city, {String? district}) async {
    if (!await _isAdmin()) {
      throw Exception('Bu işlem için yönetici yetkisi gerekiyor');
    }

    try {
      // Get duty pharmacies from API
      final dutyPharmacies = await _apiService.getDutyPharmacies(
        city: city,
        district: district,
      );

      // Reset all pharmacies in the city/district to not on duty
      final query = district != null
          ? _firestore
                .collection('pharmacies')
                .where('city', isEqualTo: city)
                .where('district', isEqualTo: district)
          : _firestore.collection('pharmacies').where('city', isEqualTo: city);

      final snapshot = await query.get();
      final batch = _firestore.batch();

      // First, set all to not on duty
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isOnDuty': false});
      }

      // Then, set duty pharmacies
      for (var pharmacy in dutyPharmacies) {
        // Find matching pharmacy in Firestore
        final matchQuery = await _firestore
            .collection('pharmacies')
            .where('city', isEqualTo: city)
            .where('name', isEqualTo: pharmacy.name)
            .where('district', isEqualTo: pharmacy.district)
            .get();

        if (matchQuery.docs.isNotEmpty) {
          batch.update(matchQuery.docs.first.reference, {
            'isOnDuty': true,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }
      }

      await batch.commit();
      print(
        'Duty status updated successfully for $city${district != null ? '/$district' : ''}',
      );
    } catch (e) {
      print('Error updating duty status: $e');
      throw Exception(
        'Nöbetçi eczane durumu güncellenirken bir hata oluştu: $e',
      );
    }
  }
}
