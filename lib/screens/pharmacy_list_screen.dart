import 'package:flutter/material.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/pharmacy_model.dart';
import '../services/pharmacy_service.dart';

class PharmacyListScreen extends StatefulWidget {
  static const routeName = '/pharmacy-list';

  const PharmacyListScreen({super.key});

  @override
  State<PharmacyListScreen> createState() => _PharmacyListScreenState();
}

class _PharmacyListScreenState extends State<PharmacyListScreen> {
  final PharmacyService _pharmacyService = PharmacyService();
  List<Pharmacy> _pharmacies = [];
  List<String> _cities = [];
  List<String> _districts = [];
  String? _selectedCity;
  String? _selectedDistrict;
  bool _isLoading = false;
  String _searchQuery = '';
  bool _showOnlyFavorites = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCities();
  }

  Future<void> _loadCities() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final cities = await _pharmacyService.getCities();
      setState(() {
        _cities = cities;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Şehirler yüklenirken bir hata oluştu: ${e.toString()}';
      });
    }
  }

  Future<void> _loadDistricts(String city) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final districts = await _pharmacyService.getDistricts(city);
      setState(() {
        _districts = districts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'İlçeler yüklenirken bir hata oluştu: ${e.toString()}';
      });
    }
  }

  Future<void> _loadPharmacies() async {
    if (_selectedCity == null) return;

    try {
      setState(() => _isLoading = true);
      final pharmacies = await _pharmacyService.getPharmacies(
        city: _selectedCity!,
        district: _selectedDistrict,
      );

      setState(() {
        _pharmacies = pharmacies;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _error = 'Eczaneler yüklenirken bir hata oluştu';
    }
  }

  Future<void> _toggleFavorite(Pharmacy pharmacy) async {
    try {
      await _pharmacyService.toggleFavorite(pharmacy);
      await _loadPharmacies(); // Reload to update favorite status
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<void> _refreshPharmacies() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // TODO: Implement pharmacy refresh logic
      await Future.delayed(const Duration(seconds: 2)); // Simulated delay
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Eczaneler yüklenirken bir hata oluştu: ${e.toString()}';
      });
    }
  }

  Future<void> _makePhoneCall(String? phoneNumber) async {
    if (phoneNumber == null) return;

    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      await launchUrl(phoneUri);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Telefon araması yapılamıyor: ${e.toString()}';
        });
      }
    }
  }

  List<Pharmacy> get _filteredPharmacies {
    return _pharmacies.where((pharmacy) {
      if (_showOnlyFavorites && !pharmacy.isFavorite) return false;

      if (_selectedCity != null && pharmacy.city != _selectedCity) return false;

      if (_selectedDistrict != null && pharmacy.district != _selectedDistrict) {
        return false;
      }

      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return pharmacy.name.toLowerCase().contains(query) ||
            pharmacy.address.toLowerCase().contains(query) ||
            pharmacy.district.toLowerCase().contains(query) ||
            pharmacy.city.toLowerCase().contains(query);
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Eczane Ara'), centerTitle: true),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // City Dropdown
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Şehir',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.location_city),
                  ),
                  value: _selectedCity,
                  items: _cities.map((city) {
                    return DropdownMenuItem(value: city, child: Text(city));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCity = value;
                      _selectedDistrict = null;
                      _districts.clear();
                    });
                    if (value != null) {
                      _loadDistricts(value);
                      _loadPharmacies();
                    }
                  },
                ),
                const SizedBox(height: 16),

                // District Dropdown
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'İlçe (Opsiyonel)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.location_on),
                    hintText: 'Tüm İlçeler',
                  ),
                  value: _selectedDistrict,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Tüm İlçeler'),
                    ),
                    ..._districts.map((district) {
                      return DropdownMenuItem(
                        value: district,
                        child: Text(district),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedDistrict = value);
                    _loadPharmacies();
                  },
                ),
                const SizedBox(height: 16),

                // Search TextField
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Ara',
                    hintText: 'Eczane adı, adres veya ilçe',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
                const SizedBox(height: 16),

                // Favorites filter
                FilterChip(
                  label: const Text('Favorilerim'),
                  selected: _showOnlyFavorites,
                  onSelected: (value) {
                    setState(() => _showOnlyFavorites = value);
                  },
                ),
              ],
            ),
          ),

          // Results
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Yükleniyor...'),
                      ],
                    ),
                  )
                : _error != null
                ? Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Bir Hata Oluştu',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.7),
                                ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _loadPharmacies,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Tekrar Dene'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : _selectedCity == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_city_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Lütfen Bir Şehir Seçin',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ],
                    ),
                  )
                : _filteredPharmacies.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.local_pharmacy_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Eczane Bulunamadı',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Arama kriterlerinize uygun eczane bulunamadı.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.7),
                              ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredPharmacies.length,
                    itemBuilder: (context, index) {
                      final pharmacy = _filteredPharmacies[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: ListTile(
                          title: Text(
                            pharmacy.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(pharmacy.address),
                              Text(
                                pharmacy.phone ?? '',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  pharmacy.isFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: pharmacy.isFavorite
                                      ? Theme.of(context).colorScheme.primary
                                      : null,
                                ),
                                onPressed: () => _toggleFavorite(pharmacy),
                              ),
                              IconButton(
                                icon: const Icon(Icons.phone),
                                onPressed: () => _makePhoneCall(pharmacy.phone),
                              ),
                              IconButton(
                                icon: const Icon(Icons.map),
                                onPressed: () => _openInMaps(pharmacy),
                              ),
                            ],
                          ),
                          onTap: () => _showPharmacyDetails(pharmacy),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showPharmacyDetails(Pharmacy pharmacy) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.local_pharmacy,
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
                          pharmacy.name,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${pharmacy.district}, ${pharmacy.city}',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.7),
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ...[
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.location_on_outlined,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  title: const Text('Adres'),
                  subtitle: Text(pharmacy.address),
                  trailing: IconButton(
                    icon: const Icon(Icons.map_outlined),
                    onPressed: () => _openInMaps(pharmacy),
                    tooltip: 'Haritada Göster',
                  ),
                ),
              ],
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.phone_outlined,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                title: const Text('Telefon'),
                subtitle: Text(pharmacy.phone),
                trailing: IconButton(
                  icon: const Icon(Icons.phone),
                  onPressed: () => _makePhoneCall(pharmacy.phone),
                  tooltip: 'Ara',
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _openInMaps(pharmacy),
                  icon: const Icon(Icons.directions),
                  label: const Text('Yol Tarifi Al'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _makePhoneCall(pharmacy.phone),
                  icon: const Icon(Icons.phone),
                  label: const Text('Eczaneyi Ara'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openInMaps(Pharmacy pharmacy) async {
    try {
      if (pharmacy.latitude != null && pharmacy.longitude != null) {
        await MapsLauncher.launchCoordinates(
          pharmacy.latitude!,
          pharmacy.longitude!,
          pharmacy.name,
        );
      } else {
        await MapsLauncher.launchQuery(
          '${pharmacy.name}, ${pharmacy.address}, ${pharmacy.district}, ${pharmacy.city}',
        );
      }
    } catch (e) {
      setState(() {
        _error = 'Harita açılırken bir hata oluştu: ${e.toString()}';
      });
    }
  }
}
