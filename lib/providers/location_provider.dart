import 'package:flutter/material.dart';              // Flutter UI framework
import 'package:eczane_vs/services/api_service.dart'; // API çağrıları için
import 'package:eczane_vs/models/pharmacy_model.dart'; // Eczane veri modeli
import 'package:eczane_vs/services/location_service.dart'; // Konum servisleri
import 'package:shared_preferences/shared_preferences.dart'; // Kalıcı depolama

class LocationProvider extends ChangeNotifier {
  Map<String, String>? _location;
  List<Pharmacy> _pharmacies = [];
  bool _isLocationEnabled = false;

  Map<String, String>? get location => _location;
  List<Pharmacy> get pharmacies => _pharmacies;
  bool get isLocationEnabled => _isLocationEnabled;
  final ApiService _apiService = ApiService();

  LocationProvider() {
    _loadLocation();
  }

  // Check and request location permissions
  Future<bool> ensureLocationEnabled(BuildContext context) async {
    _isLocationEnabled = await LocationService.ensureLocationEnabled(context);
    if (_isLocationEnabled) {
      // Try to get current location
      final locationData = await LocationService.getCityAndDistrict();
      if (locationData != null) {
        await setLocation(locationData);
      }
    }
    notifyListeners();
    return _isLocationEnabled;
  }

  // SharedPreferences'dan konumu yükle
  Future<void> _loadLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final city = prefs.getString('city');
    final district = prefs.getString('district');
    if (city != null && district != null) {
      _location = {'city': city, 'district': district};
      notifyListeners();

      // Konum yüklendiğinde nöbetçi eczaneleri çek
      await fetchPharmacies();
    }
  }

  // Konumu güncelle ve SharedPreferences'a kaydet
  Future<void> setLocation(Map<String, String> newLocation) async {
    _location = newLocation;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('city', newLocation['city']!);
    await prefs.setString('district', newLocation['district']!);

    // Konum güncellenince nöbetçi eczaneleri çek
    await fetchPharmacies();
  }

  Future<void> fetchPharmacies() async {
    if (_location == null) return;

    final apiPharmacies = await _apiService.getDutyPharmacies(
      city: _location!['city'] ?? '',
      district: _location!['district'] ?? '',
    );

    // Convert API Pharmacy to our Pharmacy model
    _pharmacies = apiPharmacies
        .map(
          (p) => Pharmacy(
            id: DateTime.now().millisecondsSinceEpoch
                .toString(), // Generate a temporary ID
            name: p.name,
            district: p.district,
            city: _location!['city'] ?? '',
            address: p.address,
            phone: p.phone,
          ),
        )
        .toList();

    notifyListeners();
  }
}
