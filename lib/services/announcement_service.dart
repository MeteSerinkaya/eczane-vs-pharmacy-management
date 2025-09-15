import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eczane_vs/models/announcement_model.dart';

class AnnouncementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collectionPath = 'announcements'; // Firestore koleksiyon adı

  // Tüm duyuruları getirir (stream ile dinamik güncelleme için)
  Stream<List<Announcement>> getAnnouncementsStream() {
    return _firestore
        .collection(collectionPath)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Announcement.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // Yeni duyuru ekleme
  Future<void> addAnnouncement(Announcement announcement) async {
    await _firestore.collection(collectionPath).add(announcement.toMap());
  }

  // Duyuru güncelleme (id'ye göre)
  Future<void> updateAnnouncement(Announcement announcement) async {
    await _firestore
        .collection(collectionPath)
        .doc(announcement.id)
        .update(announcement.toMap());
  }

  // Duyuru silme
  Future<void> deleteAnnouncement(String id) async {
    await _firestore.collection(collectionPath).doc(id).delete();
  }
}
