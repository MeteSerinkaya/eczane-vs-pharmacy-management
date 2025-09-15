import 'package:cloud_firestore/cloud_firestore.dart';

class Announcement {
  final String id; // Doküman ID'si
  final String title; // Duyuru başlığı
  final String description; // Duyuru içeriği
  final DateTime date; // Duyuru tarihi

  Announcement({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
  });

  // Firestore'dan veri okuma (Map -> Announcement)
  factory Announcement.fromMap(Map<String, dynamic> data, String documentId) {
    return Announcement(
      id: documentId,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
    );
  }

  // Veri kaydetmek için (Announcement -> Map)
  Map<String, dynamic> toMap() {
    return {'title': title, 'description': description, 'date': date};
  }
}
