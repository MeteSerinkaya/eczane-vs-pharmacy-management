import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  // Check if location services are enabled
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Check location permission status
  static Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  // Request location permission
  static Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  // Get current position
  static Future<Position?> getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      debugPrint('Error getting position: $e');
      return null;
    }
  }

  // Get city and district from coordinates
  static Future<Map<String, String>?> getCityAndDistrict() async {
    try {
      final position = await getCurrentPosition();
      if (position == null) return null;

      final List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        return {
          'city': placemark.administrativeArea ?? '',
          'district': placemark.subAdministrativeArea ?? '',
        };
      }
      return null;
    } catch (e) {
      debugPrint('Error getting city and district: $e');
      return null;
    }
  }

  // Ensure location service is enabled and permission is granted
  static Future<bool> ensureLocationEnabled(BuildContext context) async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Show dialog to enable location services
      if (context.mounted) {
        final bool shouldContinue =
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Konum Servisi Kapalı'),
                  content: const Text(
                    'Eczaneleri görüntüleyebilmek için konum servisini açmanız gerekmektedir. '
                    'Konum servisini açmak için ayarlara gidin.',
                  ),
                  actions: <Widget>[
                    TextButton(
                      child: const Text('İptal'),
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                    TextButton(
                      child: const Text('Ayarlara Git'),
                      onPressed: () async {
                        await Geolocator.openLocationSettings();
                        if (context.mounted) {
                          Navigator.of(context).pop(true);
                        }
                      },
                    ),
                  ],
                );
              },
            ) ??
            false;

        if (!shouldContinue) return false;

        // Check again after user returns from settings
        serviceEnabled = await isLocationServiceEnabled();
        if (!serviceEnabled) {
          return await ensureLocationEnabled(
            context,
          ); // Recursive call if still not enabled
        }
      }
    }

    // Check location permission
    permission = await checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await requestPermission();
      if (permission == LocationPermission.denied) {
        // Show dialog explaining why we need location permission
        if (context.mounted) {
          final bool shouldContinue =
              await showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Konum İzni Gerekli'),
                    content: const Text(
                      'Size en yakın eczaneleri gösterebilmek için konum izni gerekiyor. '
                      'Lütfen konum iznini verin.',
                    ),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('İptal'),
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                      TextButton(
                        child: const Text('İzin Ver'),
                        onPressed: () async {
                          Navigator.of(context).pop(true);
                        },
                      ),
                    ],
                  );
                },
              ) ??
              false;

          if (!shouldContinue) return false;
          return await ensureLocationEnabled(context); // Try again
        }
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Show dialog to open app settings
      if (context.mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Konum İzni Gerekli'),
              content: const Text(
                'Konum izni kalıcı olarak reddedildi. '
                'Lütfen uygulama ayarlarından konum iznini etkinleştirin.',
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('İptal'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: const Text('Ayarlara Git'),
                  onPressed: () async {
                    await Geolocator.openAppSettings();
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            );
          },
        );
        return await ensureLocationEnabled(context); // Try again after settings
      }
      return false;
    }

    // Try to get current position to verify everything works
    final position = await getCurrentPosition();
    return position != null;
  }
}
