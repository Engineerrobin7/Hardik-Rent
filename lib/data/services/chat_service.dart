// Sprint 2: Chat Service
// File: lib/data/services/chat_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_models.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  /// Get or create a chat room between owner and tenant
  Future<ChatRoom> getOrCreateChatRoom({
    required String ownerId,
    required String ownerName,
    required String tenantId,
    required String tenantName,
    required String propertyId,
    required String propertyAddress,
  }) async {
    try {
      // Check if chat room already exists
      final existingRoom = await _firestore
          .collection('chatRooms')
          .where('ownerId', isEqualTo: ownerId)
          .where('tenantId', isEqualTo: tenantId)
          .where('propertyId', isEqualTo: propertyId)
          .limit(1)
          .get();

      if (existingRoom.docs.isNotEmpty) {
        return ChatRoom.fromFirestore(existingRoom.docs.first);
      }

      // Create new chat room
      final roomId = _uuid.v4();
      final now = DateTime.now();

      final chatRoom = ChatRoom(
        id: roomId,
        ownerId: ownerId,
        ownerName: ownerName,
        tenantId: tenantId,
        tenantName: tenantName,
        propertyId: propertyId,
        propertyAddress: propertyAddress,
        createdAt: now,
        updatedAt: now,
      );

      await _firestore.collection('chatRooms').doc(roomId).set(chatRoom.toJson());

      return chatRoom;
    } catch (e) {
      print('Error creating chat room: $e');
      rethrow;
    }
  }

  /// Send a message
  Future<void> sendMessage({
    required String chatRoomId,
    required String senderId,
    required String senderName,
    required String receiverId,
    required String message,
    String? attachmentUrl,
    String? attachmentType,
  }) async {
    try {
      final messageId = _uuid.v4();
      final now = DateTime.now();

      final chatMessage = ChatMessage(
        id: messageId,
        senderId: senderId,
        senderName: senderName,
        receiverId: receiverId,
        message: message,
        timestamp: now,
        attachmentUrl: attachmentUrl,
        attachmentType: attachmentType,
      );

      // Add message to subcollection
      await _firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .collection('messages')
          .doc(messageId)
          .set(chatMessage.toJson());

      // Update chat room with last message
      await _firestore.collection('chatRooms').doc(chatRoomId).update({
        'lastMessage': chatMessage.toJson(),
        'updatedAt': Timestamp.fromDate(now),
      });

      // Increment unread count for receiver
      await _incrementUnreadCount(chatRoomId, receiverId);
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  /// Get messages stream for a chat room
  Stream<List<ChatMessage>> getMessagesStream(String chatRoomId) {
    return _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ChatMessage.fromFirestore(doc)).toList());
  }

  /// Get chat rooms for a user
  Stream<List<ChatRoom>> getChatRoomsStream(String userId, String userRole) {
    final field = userRole == 'owner' ? 'ownerId' : 'tenantId';
    
    return _firestore
        .collection('chatRooms')
        .where(field, isEqualTo: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ChatRoom.fromFirestore(doc)).toList());
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead(String chatRoomId, String userId) async {
    try {
      final unreadMessages = await _firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .collection('messages')
          .where('receiverId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();

      for (var doc in unreadMessages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();

      // Reset unread count
      await _firestore.collection('chatRooms').doc(chatRoomId).update({
        'unreadCount': 0,
      });
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  /// Get unread message count for a user
  Future<int> getUnreadCount(String userId, String userRole) async {
    try {
      final field = userRole == 'owner' ? 'ownerId' : 'tenantId';
      
      final chatRooms = await _firestore
          .collection('chatRooms')
          .where(field, isEqualTo: userId)
          .get();

      int totalUnread = 0;
      for (var room in chatRooms.docs) {
        final data = room.data();
        totalUnread += (data['unreadCount'] as int?) ?? 0;
      }

      return totalUnread;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }

  Future<void> _incrementUnreadCount(String chatRoomId, String receiverId) async {
    try {
      await _firestore.collection('chatRooms').doc(chatRoomId).update({
        'unreadCount': FieldValue.increment(1),
      });
    } catch (e) {
      print('Error incrementing unread count: $e');
    }
  }

  /// Delete a chat room
  Future<void> deleteChatRoom(String chatRoomId) async {
    try {
      // Delete all messages first
      final messages = await _firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .collection('messages')
          .get();

      final batch = _firestore.batch();
      for (var doc in messages.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Delete chat room
      await _firestore.collection('chatRooms').doc(chatRoomId).delete();
    } catch (e) {
      print('Error deleting chat room: $e');
      rethrow;
    }
  }
}
