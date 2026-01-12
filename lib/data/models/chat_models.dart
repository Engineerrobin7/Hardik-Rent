// Sprint 2: Chat Models
// File: lib/data/models/chat_models.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// Individual chat message
class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String receiverId;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String? attachmentUrl;
  final String? attachmentType; // 'image', 'document', 'receipt'

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.receiverId,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.attachmentUrl,
    this.attachmentType,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'senderId': senderId,
        'senderName': senderName,
        'receiverId': receiverId,
        'message': message,
        'timestamp': Timestamp.fromDate(timestamp),
        'isRead': isRead,
        'attachmentUrl': attachmentUrl,
        'attachmentType': attachmentType,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String,
        senderId: json['senderId'] as String,
        senderName: json['senderName'] as String? ?? 'Unknown',
        receiverId: json['receiverId'] as String,
        message: json['message'] as String,
        timestamp: (json['timestamp'] as Timestamp).toDate(),
        isRead: json['isRead'] as bool? ?? false,
        attachmentUrl: json['attachmentUrl'] as String?,
        attachmentType: json['attachmentType'] as String?,
      );

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessage.fromJson({...data, 'id': doc.id});
  }
}

/// Chat room between owner and tenant
class ChatRoom {
  final String id;
  final String ownerId;
  final String ownerName;
  final String tenantId;
  final String tenantName;
  final String propertyId;
  final String propertyAddress;
  final ChatMessage? lastMessage;
  final int unreadCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatRoom({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.tenantId,
    required this.tenantName,
    required this.propertyId,
    required this.propertyAddress,
    this.lastMessage,
    this.unreadCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'ownerId': ownerId,
        'ownerName': ownerName,
        'tenantId': tenantId,
        'tenantName': tenantName,
        'propertyId': propertyId,
        'propertyAddress': propertyAddress,
        'lastMessage': lastMessage?.toJson(),
        'unreadCount': unreadCount,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  factory ChatRoom.fromJson(Map<String, dynamic> json) => ChatRoom(
        id: json['id'] as String,
        ownerId: json['ownerId'] as String,
        ownerName: json['ownerName'] as String? ?? 'Owner',
        tenantId: json['tenantId'] as String,
        tenantName: json['tenantName'] as String? ?? 'Tenant',
        propertyId: json['propertyId'] as String,
        propertyAddress: json['propertyAddress'] as String? ?? 'Property',
        lastMessage: json['lastMessage'] != null
            ? ChatMessage.fromJson(json['lastMessage'] as Map<String, dynamic>)
            : null,
        unreadCount: json['unreadCount'] as int? ?? 0,
        createdAt: (json['createdAt'] as Timestamp).toDate(),
        updatedAt: (json['updatedAt'] as Timestamp).toDate(),
      );

  factory ChatRoom.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatRoom.fromJson({...data, 'id': doc.id});
  }
}

/// Notification model
class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type; // 'rent_reminder', 'payment_received', 'chat', 'maintenance'
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? data;

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.data,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'title': title,
        'body': body,
        'type': type,
        'timestamp': Timestamp.fromDate(timestamp),
        'isRead': isRead,
        'data': data,
      };

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'] as String,
        userId: json['userId'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        type: json['type'] as String,
        timestamp: (json['timestamp'] as Timestamp).toDate(),
        isRead: json['isRead'] as bool? ?? false,
        data: json['data'] as Map<String, dynamic>?,
      );

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppNotification.fromJson({...data, 'id': doc.id});
  }
}
