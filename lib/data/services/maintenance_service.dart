// Sprint 3: Maintenance Service
// File: lib/data/services/maintenance_service.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../models/maintenance_models.dart';

class MaintenanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  // Create a new maintenance ticket
  Future<void> createTicket(MaintenanceTicket ticket, List<File> photos) async {
    try {
      List<String> photoUrls = [];

      // 1. Upload photos if any
      for (File photo in photos) {
        String fileName = '${_uuid.v4()}.jpg';
        Reference ref = _storage.ref().child('maintenance_photos/$fileName');
        UploadTask uploadTask = ref.putFile(photo);
        TaskSnapshot snapshot = await uploadTask;
        String url = await snapshot.ref.getDownloadURL();
        photoUrls.add(url);
      }

      // 2. Create ticket with photo URLs (Updating the list from the passed object)
      final newTicket = MaintenanceTicket(
        id: ticket.id,
        propertyId: ticket.propertyId,
        propertyAddress: ticket.propertyAddress,
        tenantId: ticket.tenantId,
        tenantName: ticket.tenantName,
        ownerId: ticket.ownerId,
        title: ticket.title,
        description: ticket.description,
        priority: ticket.priority,
        status: ticket.status,
        photoUrls: photoUrls, // Use uploaded URLs
        createdAt: ticket.createdAt,
      );

      await _firestore
          .collection('maintenanceTickets')
          .doc(ticket.id)
          .set(newTicket.toJson());

    } catch (e) {
      print('Error creating maintenance ticket: $e');
      rethrow;
    }
  }

  // Update ticket status
  Future<void> updateTicketStatus(
    String ticketId, 
    TicketStatus newStatus, 
    {String? notes, double? cost}
  ) async {
    try {
      Map<String, dynamic> updates = {
        'status': newStatus.name,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (notes != null) updates['resolutionNotes'] = notes;
      if (cost != null) updates['actualCost'] = cost;
      if (newStatus == TicketStatus.resolved) {
        updates['resolvedAt'] = FieldValue.serverTimestamp();
      }

      await _firestore
          .collection('maintenanceTickets')
          .doc(ticketId)
          .update(updates);
          
    } catch (e) {
      print('Error updating ticket: $e');
      rethrow;
    }
  }

  // Get tickets for a user (Owner or Tenant)
  Stream<List<MaintenanceTicket>> getTicketsStream(String userId, String role) {
    String field = role == 'owner' ? 'ownerId' : 'tenantId';
    
    return _firestore
        .collection('maintenanceTickets')
        .where(field, isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MaintenanceTicket.fromFirestore(doc))
            .toList());
  }

  // Cost Tracking: Get total maintenance cost for a property
  Future<double> getDetailedMaintenanceCost(String propertyId) async {
    QuerySnapshot snapshot = await _firestore
        .collection('maintenanceTickets')
        .where('propertyId', isEqualTo: propertyId)
        .where('status', isEqualTo: 'resolved')
        .get();

    double total = 0;
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      total += (data['actualCost'] as num?)?.toDouble() ?? 0.0;
    }
    return total;
  }
}
