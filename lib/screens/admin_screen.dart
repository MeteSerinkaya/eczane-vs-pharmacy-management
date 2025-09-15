import 'package:flutter/material.dart';
import '../services/pharmacy_migration_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final PharmacyMigrationService _migrationService = PharmacyMigrationService();
  bool _isMigrating = false;
  String? _errorMessage;
  String? _successMessage;
  Map<String, dynamic>? _migrationStatus;
  Set<String> _selectedCities = {};

  @override
  void initState() {
    super.initState();
    _loadMigrationStatus();
  }

  Future<void> _loadMigrationStatus() async {
    try {
      setState(() => _isMigrating = true);
      final status = await _migrationService.getMigrationStatus();
      setState(() {
        _migrationStatus = status;
        _isMigrating = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isMigrating = false;
      });
    }
  }

  Future<void> _startMigration() async {
    if (_isMigrating) return;

    try {
      setState(() {
        _isMigrating = true;
        _errorMessage = null;
        _successMessage = null;
      });

      if (_selectedCities.isNotEmpty) {
        await _migrationService.migrateCities(_selectedCities.toList());
      } else {
        await _migrationService.migrateAllPharmacies();
      }

      await _loadMigrationStatus();

      setState(() {
        _successMessage = 'Veri aktarımı başarıyla tamamlandı!';
        _selectedCities.clear();
      });
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isMigrating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final missingCities =
        _migrationStatus?['missingCities'] as List<String>? ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Yönetici Paneli'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Migrasyon Durumu',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    if (_migrationStatus != null) ...[
                      _buildStatusRow(
                        'Toplam Şehir',
                        _migrationStatus!['totalCities'].toString(),
                      ),
                      _buildStatusRow(
                        'Aktarılan Şehir',
                        _migrationStatus!['citiesInDb'].toString(),
                      ),
                      _buildStatusRow(
                        'Toplam Eczane',
                        _migrationStatus!['totalPharmacies'].toString(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (missingCities.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Eksik Şehirler',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Henüz aktarılmamış şehirleri seçip aktarabilirsiniz.',
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: missingCities.map((city) {
                          final isSelected = _selectedCities.contains(city);
                          return FilterChip(
                            label: Text(city),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedCities.add(city);
                                } else {
                                  _selectedCities.remove(city);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () {
                              setState(() {
                                if (_selectedCities.length ==
                                    missingCities.length) {
                                  _selectedCities.clear();
                                } else {
                                  _selectedCities = Set.from(missingCities);
                                }
                              });
                            },
                            child: Text(
                              _selectedCities.length == missingCities.length
                                  ? 'Seçimi Temizle'
                                  : 'Tümünü Seç',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _selectedCities.isEmpty || _isMigrating
                                  ? null
                                  : _startMigration,
                              icon: _isMigrating
                                  ? Container(
                                      width: 24,
                                      height: 24,
                                      padding: const EdgeInsets.all(2.0),
                                      child: const CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.cloud_download),
                              label: Text(
                                _isMigrating
                                    ? 'Aktarılıyor...'
                                    : 'Seçili Şehirleri Aktar',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tüm Verileri Aktar',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tüm şehirlerdeki eczaneleri API\'den alıp veritabanına aktarır.',
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isMigrating ? null : _startMigration,
                      icon: _isMigrating
                          ? Container(
                              width: 24,
                              height: 24,
                              padding: const EdgeInsets.all(2.0),
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.cloud_download),
                      label: Text(
                        _isMigrating ? 'Aktarılıyor...' : 'Tümünü Aktar',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.error.withOpacity(0.3),
                  ),
                ),
                child: Row(
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
              ),
            ],
            if (_successMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _successMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
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

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
