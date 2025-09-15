// lib/models/notifications_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String title;
  final String body;
  final DateTime? createdAt;
  final String uID; // Firestore'daki kullanıcı id alanı

  // Constructor
  NotificationModel({required this.title, required this.body, this.createdAt, required this.uID});

  // Firestore'dan NotificationModel objesi oluşturma
  factory NotificationModel.fromFirestore(Map<String, dynamic> data) {
    return NotificationModel(
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(), // Timestamp'i DateTime'a çevir
      uID: data['uID'] ?? '',
    );
  }

  // NotificationModel objesini Map'e dönüştürme (Firestore'a kaydetme)
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!) // DateTime'ı Timestamp'e çevir
          : FieldValue.serverTimestamp(), // Eğer tarih yoksa server timestamp kullan
      'uID': uID,
    };
  }
}
