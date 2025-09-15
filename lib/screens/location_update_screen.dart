import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eczane_vs/providers/location_provider.dart';
import 'package:eczane_vs/services/location_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LocationUpdateScreen extends StatefulWidget {
  const LocationUpdateScreen({super.key});

  @override
  State<LocationUpdateScreen> createState() => _LocationUpdateScreenState();
}

class _LocationUpdateScreenState extends State<LocationUpdateScreen> {
  final LocationService _locationService = LocationService();
  bool _isLoading = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _provinces = [];
  String? _selectedCity;
  String? _selectedDistrict;
  bool _isLoadingProvinces = false;

  @override
  void initState() {
    super.initState();
    _fetchProvinces();
    final location = Provider.of<LocationProvider>(
      context,
      listen: false,
    ).location;
    _selectedCity = location?['city'];
    _selectedDistrict = location?['district'];
  }

  Future<void> _fetchProvinces() async {
    setState(() {
      _isLoadingProvinces = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse('https://turkiyeapi.dev/api/v1/provinces'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'OK' && jsonResponse['data'] != null) {
          setState(() {
            _provinces = (jsonResponse['data'] as List).map((item) {
              List<dynamic> rawDistricts = item['districts'] ?? [];
              List<String> districtNames = rawDistricts
                  .map((d) => d['name'] as String)
                  .toList();

              return {'name': item['name'], 'districts': districtNames};
            }).toList();
          });
        }
      }
    } catch (e) {
      setState(() => _errorMessage = 'İl ve ilçe bilgileri yüklenemedi: $e');
    } finally {
      setState(() => _isLoadingProvinces = false);
    }
  }

  Future<void> _updateLocationAuto() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final location = await LocationService.getCityAndDistrict();
      if (!mounted) return;

      if (location == null) {
        setState(() => _errorMessage = 'Konum bilgisi alınamadı. Lütfen konum servislerinin açık olduğundan emin olun.');
        return;
      }

      final locationProvider = Provider.of<LocationProvider>(
        context,
        listen: false,
      );
      await locationProvider.setLocation(location);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Konum başarıyla güncellendi'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateLocationManual() async {
    if (_selectedCity == null || _selectedDistrict == null) {
      setState(() => _errorMessage = 'Lütfen şehir ve ilçe seçin');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final locationProvider = Provider.of<LocationProvider>(
        context,
        listen: false,
      );
      await locationProvider.setLocation({
        'city': _selectedCity!,
        'district': _selectedDistrict!,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Konum başarıyla güncellendi'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationProvider = Provider.of<LocationProvider>(context);
    final location = locationProvider.location;

    Map<String, dynamic>? cityData;
    List<String> districts = [];

    if (_selectedCity != null) {
      try {
        cityData = _provinces.firstWhere((p) => p['name'] == _selectedCity);
        districts = List<String>.from(cityData['districts']);
      } catch (e) {
        // City not found
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Konum Bilgileri'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.location_on,
                            color: Theme.of(context).colorScheme.primary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mevcut Konum',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                location != null
                                    ? '${location['city']} / ${location['district']}'
                                    : 'Konum bilgisi bulunamadı',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: location != null
                                      ? Theme.of(context).colorScheme.onSurface
                                      : Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.gps_fixed,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Otomatik Konum',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'GPS ile otomatik olarak konumunuzu güncelleyebilirsiniz.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _updateLocationAuto,
                        icon: _isLoading
                            ? Container(
                                width: 24,
                                height: 24,
                                padding: const EdgeInsets.all(2.0),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Theme.of(context).colorScheme.onPrimary,
                                  ),
                                ),
                              )
                            : const Icon(Icons.my_location),
                        label: Text(_isLoading ? 'Güncelleniyor...' : 'Otomatik Güncelle'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.edit_location_alt,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Manuel Konum',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'İl ve ilçe seçerek manuel olarak konumunuzu güncelleyebilirsiniz.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_isLoadingProvinces)
                      const Center(child: CircularProgressIndicator())
                    else ...[
                      DropdownButtonFormField<String>(
                        value: _selectedCity,
                        decoration: InputDecoration(
                          labelText: 'İl Seçin',
                          prefixIcon: const Icon(Icons.location_city),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: _provinces
                            .map((p) => DropdownMenuItem(
                                  value: p['name'] as String,
                                  child: Text(p['name'] as String),
                                ))
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedCity = val;
                            _selectedDistrict = null;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedDistrict,
                        decoration: InputDecoration(
                          labelText: 'İlçe Seçin',
                          prefixIcon: const Icon(Icons.location_on),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: districts
                            .map((d) => DropdownMenuItem(
                                  value: d,
                                  child: Text(d),
                                ))
                            .toList(),
                        onChanged: _selectedCity == null
                            ? null
                            : (val) {
                                setState(() => _selectedDistrict = val);
                              },
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _updateLocationManual,
                          icon: _isLoading
                              ? Container(
                                  width: 24,
                                  height: 24,
                                  padding: const EdgeInsets.all(2.0),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Theme.of(context).colorScheme.onPrimary,
                                    ),
                                  ),
                                )
                              : const Icon(Icons.save),
                          label: Text(_isLoading ? 'Kaydediliyor...' : 'Kaydet'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.error.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() => _errorMessage = null);
                        },
                        icon: const Icon(Icons.close),
                        label: const Text('Kapat'),
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
