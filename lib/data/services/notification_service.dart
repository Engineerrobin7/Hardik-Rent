// Sprint 2: Notification Service
// File: lib/data/services/notification_service.dart

import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Initialize notifications
  Future<void> initialize() async {
    // Request permission
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get FCM token
    String? token = await _firebaseMessaging.getToken();
    print("FCM Token: $token");

    // Initialize local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS settings
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap
      },
    );

    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });
  }

  // Save FCM token to user profile in Firestore
  Future<void> saveTokenToDatabase(String userId) async {
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token,
      });
    }
  }

  // Show local notification when app is in foreground
  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'hardik_rent_channel', // id
      'Hardik Rent Notifications', // title
      channelDescription: 'Notifications for Hardik Rent App',
      importance: Importance.max,
      priority: Priority.high,
    );
    
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _flutterLocalNotificationsPlugin.show(
      0,
      message.notification?.title,
      message.notification?.body,
      platformChannelSpecifics,
      payload: json.encode(message.data),
    );
  }

  // Send push notification (Requires Cloud Functions or running from backend)
  // This is a client-side simulation. ideally this should be done via Cloud Functions
  Future<void> sendNotification({
    required String receiverId,
    required String title,
    required String body,
    required String type, // 'chat', 'rent', 'maintenance'
  }) async {
    try {
      // 1. Get receiver's token
      DocumentSnapshot userDoc = 
          await _firestore.collection('users').doc(receiverId).get();
      
      if (!userDoc.exists) return;
      
      String? token = userDoc.get('fcmToken');
      if (token == null) return;

      // 2. Call Firebase Cloud Function (Recommended)
      // await FirebaseFunctions.instance.httpsCallable('sendNotification').call(...)
      
      // For now, we log it (Actual sending requires Server Key which shouldn't be in app)
      print("Would send notification to $token: $title - $body");
      
      // 3. Save to database for in-app notification center
      await _firestore.collection('notifications').add({
        'userId': receiverId,
        'title': title,
        'body': body,
        'type': type,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });
      
    } catch (e) {
      print("Error sending notification: $e");
    }
  }
}
