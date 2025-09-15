// lib/models/pharmacy_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Pharmacy {
  final String id;
  final String name;
  final String district;
  final String city;
  final String address;
  final String phone;
  final double? latitude;
  final double? longitude;
  bool isFavorite;

  // Constructor
  Pharmacy({
    required this.id,
    required this.name,
    required this.district,
    required this.city,
    required this.address,
    required this.phone,
    this.latitude,
    this.longitude,
    this.isFavorite = false,
  });

  // JSON'dan Pharmacy objesi oluşturma (API'den gelen veri)
  factory Pharmacy.fromJson(Map<String, dynamic> json) {
    return Pharmacy(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      district: json['dist'] ?? json['district'] ?? '', // API'de 'dist'.
      city: json['city'] ?? '',
      address: json['address'] ?? '',
      phone: json['phone'] ?? '',
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
    );
  }

  // Firestore'dan Pharmacy objesi oluşturma
  factory Pharmacy.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Pharmacy(
      id: doc.id, // Firestore doküman ID'si
      name: data['name'] ?? '',
      district: data['district'] ?? '',
      city: data['city'] ?? '',
      address: data['address'] ?? '',
      phone: data['phone'] ?? '',
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
    );
  }

  // Pharmacy objesini JSON'a dönüştürme (API'ye gönderme)
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'district': district,
      'city': city,
      'address': address,
      'phone': phone,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  // Immutable obje güncelleme (sadece değişen alanları günceller)
  Pharmacy copyWith({
    String? id,
    String? name,
    String? district,
    String? city,
    String? address,
    String? phone,
    double? latitude,
    double? longitude,
    bool? isFavorite,
  }) {
    return Pharmacy(
      id: id ?? this.id,
      name: name ?? this.name,
      district: district ?? this.district,
      city: city ?? this.city,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}