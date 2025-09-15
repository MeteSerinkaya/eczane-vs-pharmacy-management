import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const String channelId = 'high_importance_channel';
  static const String channelName = 'High Importance Notifications';

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> init(BuildContext context) async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('Notification permission status: ${settings.authorizationStatus}');

    await _initializeLocalNotifications();

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
      _saveNotificationToFirestore(message);
      if (message.notification != null) {
        final snackBar = SnackBar(
          content: Text(message.notification!.title ?? "Bildirim geldi"),
          duration: const Duration(seconds: 3),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleMessageNavigation(context, message);
    });

    RemoteMessage? initialMessage = await _firebaseMessaging
        .getInitialMessage();
    if (initialMessage != null) {
      _handleMessageNavigation(context, initialMessage);
    }
  }

  static Future<void> _firebaseMessagingBackgroundHandler(
    RemoteMessage message,
  ) async {
    print("Background message received: ${message.messageId}");
    // Background işlemler için FirebaseAuth ve Firestore setup'u gerekebilir.
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initializationSettings = InitializationSettings(
      android: androidSettings,
    );
    await _localNotificationsPlugin.initialize(initializationSettings);
  }

  void _showLocalNotification(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      const androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        importance: Importance.max,
        priority: Priority.high,
      );
      const notificationDetails = NotificationDetails(android: androidDetails);

      _localNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        notificationDetails,
      );
    }
  }

  void _handleMessageNavigation(BuildContext context, RemoteMessage message) {
    print('Notification clicked: ${message.messageId}');
    if (message.data.containsKey('screen')) {
      String screen = message.data['screen'];
      if (screen == "notifications") {
        Navigator.pushNamed(context, '/notifications');
      } else {
        Navigator.pushNamed(context, '/$screen');
      }
    } else {
      Navigator.pushNamed(context, '/');
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
    print('Subscribed to topic: $topic');
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
    print('Unsubscribed from topic: $topic');
  }

  // Bildirimi Firestore'a kullanıcı UID ile kaydet
  Future<void> _saveNotificationToFirestore(RemoteMessage message) async {
    final notification = message.notification;
    final user = _auth.currentUser;

    if (notification != null && user != null) {
      await _firestore.collection('notifications').add({
        'title': notification.title ?? '',
        'body': notification.body ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'userId': user.uid, // Burada userId ile kaydediyoruz
      });
      print('Notification saved to Firestore with userId: ${user.uid}');
    } else {
      print('Notification veya kullanıcı bulunamadı, kaydedilmedi.');
    }
  }
}
