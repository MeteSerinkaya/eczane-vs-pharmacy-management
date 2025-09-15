import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eczane_vs/providers/theme_provider.dart';
import 'package:eczane_vs/providers/location_provider.dart';
import 'package:eczane_vs/widgets/app_drawer.dart';
import 'package:eczane_vs/services/auth_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  HomePage({super.key});
  final AuthService _authService = AuthService();

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _searchQuery = '';
  String _selectedNeighborhood = 'Tümü';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSavedFilters();
    _checkLocationPermission();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedFilters() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _searchQuery = prefs.getString('searchQuery') ?? '';
      _searchController.text = _searchQuery;
      _selectedNeighborhood = prefs.getString('selectedNeighborhood') ?? 'Tümü';
    });
  }

  Future<void> _checkLocationPermission() async {
    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );
    if (!locationProvider.isLocationEnabled) {
      await locationProvider.ensureLocationEnabled(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationProvider = Provider.of<LocationProvider>(context);
    final pharmacies = locationProvider.pharmacies;
    final location = locationProvider.location;
    final themeProvider = Provider.of<ThemeProvider>(context);

    final neighborhoods = <String>{
      'Tümü',
      ...pharmacies
          .map((ph) => _extractNeighborhood(ph.address))
          .where((n) => n.isNotEmpty),
    }.toList();

    final filteredPharmacies = pharmacies.where((ph) {
      final nameMatch = ph.name.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      final neighborhood = _extractNeighborhood(ph.address);
      final neighborhoodMatch =
          _selectedNeighborhood == 'Tümü' ||
          neighborhood == _selectedNeighborhood;
      return nameMatch && neighborhoodMatch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nöbetçi Eczaneler'),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 14,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    '${location?['city'] ?? 'Şehir'} / ${location?['district'] ?? 'İlçe'}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.themeMode == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: () => themeProvider.toggleTheme(),
            tooltip: 'Tema değiştir',
          ),
        ],
      ),
      drawer: AppDrawer(),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Eczane adı ile ara...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                                _searchController.clear();
                              });
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) async {
                    setState(() => _searchQuery = value);
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('searchQuery', value);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedNeighborhood,
                  decoration: InputDecoration(
                    labelText: 'Mahalle Filtresi',
                    prefixIcon: const Icon(Icons.location_city),
                  ),
                  items: neighborhoods
                      .map((n) => DropdownMenuItem(value: n, child: Text(n)))
                      .toList(),
                  onChanged: (val) async {
                    setState(() => _selectedNeighborhood = val!);
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('selectedNeighborhood', val!);
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: filteredPharmacies.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.local_pharmacy_outlined,
                          size: 64,
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Eczane bulunamadı.",
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.5),
                              ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredPharmacies.length,
                    itemBuilder: (context, index) {
                      final pharmacy = filteredPharmacies[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.local_pharmacy,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      pharmacy.name,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleLarge,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 20,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.secondary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      pharmacy.address,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyLarge,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () =>
                                          _callPharmacy(pharmacy.phone),
                                      icon: const Icon(Icons.phone),
                                      label: Text(pharmacy.phone),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    onPressed: () =>
                                        _openInMaps(context, pharmacy.address),
                                    icon: const Icon(Icons.map),
                                    label: const Text('Yol Tarifi'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(
                                        context,
                                      ).colorScheme.secondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _extractNeighborhood(String address) {
    final mahMatch = RegExp(
      r'([A-ZÇĞİÖŞÜa-zçğıöşü]+)\s*Mah\.?',
    ).firstMatch(address);
    return mahMatch != null ? mahMatch.group(1)! : '';
  }

  void _callPharmacy(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Arama yapılamıyor'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Future<void> _openInMaps(BuildContext context, String address) async {
    try {
      // First try to launch with coordinates if available
      final locationProvider = Provider.of<LocationProvider>(
        context,
        listen: false,
      );
      final pharmacies = locationProvider.pharmacies;
      // Find pharmacy by address
      final pharmacy = pharmacies
          .where((p) => p.address == address)
          .firstOrNull;

      String mapsUrl;
      if (pharmacy != null &&
          pharmacy.latitude != null &&
          pharmacy.longitude != null) {
        // Use coordinates for more accurate location
        mapsUrl =
            'https://www.google.com/maps/dir/?api=1'
            '&destination=${pharmacy.latitude},${pharmacy.longitude}'
            '&travelmode=driving';
      } else {
        // Fallback to address search
        final fullAddress = pharmacy != null
            ? '${pharmacy.address}, ${pharmacy.district}, ${pharmacy.city}'
            : address;
        mapsUrl =
            'https://www.google.com/maps/search/?api=1'
            '&query=${Uri.encodeComponent(fullAddress)}';
      }

      final uri = Uri.parse(mapsUrl);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch maps';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Harita açılamıyor'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
