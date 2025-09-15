import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:eczane_vs/models/pharmacy_model.dart';
import 'package:geocoding/geocoding.dart';

class ApiService {
  final String baseUrl = 'https://api.collectapi.com/health/dutyPharmacy';

  final Map<String, String> headers = {
    'authorization': 'apikey 5lx59iyBcpjTgMUWEl1q2g:3TINHoXe5Ou2D4BTFe1J1i',
    'content-type': 'application/json',
  };

  Future<List<Pharmacy>> getDutyPharmacies({required String city, String? district}) async {
    final uri = Uri.parse('$baseUrl?il=$city${district != null && district.isNotEmpty ? '&ilce=$district' : ''}');

    print('🔵 API İsteği: $uri');

    final response = await http.get(uri, headers: headers);

    print('🟢 Status Code: ${response.statusCode}');
    print('🟢 Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      if (jsonData['success'] == true) {
        final List<dynamic> data = jsonData['result'];
        final List<Pharmacy> pharmacies = [];

        for (var e in data) {
          final pharmacy = Pharmacy(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: e['name'] ?? '',
            district: e['dist'] ?? '',
            city: city,
            address: e['address'] ?? '',
            phone: e['phone'] ?? '',
          );

          try {
            // Get coordinates from address
            final fullAddress = '${pharmacy.address}, ${pharmacy.district}, ${pharmacy.city}, Türkiye';
            final locations = await locationFromAddress(fullAddress);

            if (locations.isNotEmpty) {
              pharmacies.add(
                pharmacy.copyWith(latitude: locations.first.latitude, longitude: locations.first.longitude),
              );
            } else {
              pharmacies.add(pharmacy);
            }
          } catch (e) {
            print('Geocoding error for ${pharmacy.name}: $e');
            pharmacies.add(pharmacy);
          }
        }

        return pharmacies;
      } else {
        throw Exception('API başarısız döndü: ${jsonData['message']}');
      }
    } else {
      throw Exception('Eczane verileri yüklenemedi: ${response.statusCode}');
    }
  }
}
