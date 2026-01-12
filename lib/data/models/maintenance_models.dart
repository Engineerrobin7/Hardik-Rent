// Sprint 3: Maintenance Models
// File: lib/data/models/maintenance_models.dart

import 'package:cloud_firestore/cloud_firestore.dart';

enum TicketStatus { open, inProgress, resolved, closed }
enum TicketPriority { low, medium, high, urgent }

/// Maintenance ticket for property issues
class MaintenanceTicket {
  final String id;
  final String propertyId;
  final String propertyAddress;
  final String tenantId;
  final String tenantName;
  final String ownerId;
  final String title;
  final String description;
  final TicketPriority priority;
  final TicketStatus status;
  final List<String> photoUrls;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? resolutionNotes;
  final double? estimatedCost;
  final double? actualCost;

  MaintenanceTicket({
    required this.id,
    required this.propertyId,
    required this.propertyAddress,
    required this.tenantId,
    required this.tenantName,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    this.photoUrls = const [],
    required this.createdAt,
    this.resolvedAt,
    this.resolutionNotes,
    this.estimatedCost,
    this.actualCost,
  });

  String get priorityText {
    switch (priority) {
      case TicketPriority.low:
        return 'Low';
      case TicketPriority.medium:
        return 'Medium';
      case TicketPriority.high:
        return 'High';
      case TicketPriority.urgent:
        return 'Urgent';
    }
  }

  String get statusText {
    switch (status) {
      case TicketStatus.open:
        return 'Open';
      case TicketStatus.inProgress:
        return 'In Progress';
      case TicketStatus.resolved:
        return 'Resolved';
      case TicketStatus.closed:
        return 'Closed';
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'propertyId': propertyId,
        'propertyAddress': propertyAddress,
        'tenantId': tenantId,
        'tenantName': tenantName,
        'ownerId': ownerId,
        'title': title,
        'description': description,
        'priority': priority.name,
        'status': status.name,
        'photoUrls': photoUrls,
        'createdAt': Timestamp.fromDate(createdAt),
        'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
        'resolutionNotes': resolutionNotes,
        'estimatedCost': estimatedCost,
        'actualCost': actualCost,
      };

  factory MaintenanceTicket.fromJson(Map<String, dynamic> json) =>
      MaintenanceTicket(
        id: json['id'] as String,
        propertyId: json['propertyId'] as String,
        propertyAddress: json['propertyAddress'] as String? ?? 'Unknown',
        tenantId: json['tenantId'] as String,
        tenantName: json['tenantName'] as String? ?? 'Unknown',
        ownerId: json['ownerId'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        priority: TicketPriority.values.firstWhere(
          (e) => e.name == json['priority'],
          orElse: () => TicketPriority.medium,
        ),
        status: TicketStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => TicketStatus.open,
        ),
        photoUrls: (json['photoUrls'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        createdAt: (json['createdAt'] as Timestamp).toDate(),
        resolvedAt: json['resolvedAt'] != null
            ? (json['resolvedAt'] as Timestamp).toDate()
            : null,
        resolutionNotes: json['resolutionNotes'] as String?,
        estimatedCost: (json['estimatedCost'] as num?)?.toDouble(),
        actualCost: (json['actualCost'] as num?)?.toDouble(),
      );

  factory MaintenanceTicket.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MaintenanceTicket.fromJson({...data, 'id': doc.id});
  }
}

/// Property expense tracking
class PropertyExpense {
  final String id;
  final String propertyId;
  final String propertyAddress;
  final String ownerId;
  final String category; // 'repair', 'utility', 'tax', 'maintenance', 'other'
  final double amount;
  final String description;
  final DateTime date;
  final String? receiptUrl;
  final String? maintenanceTicketId;

  PropertyExpense({
    required this.id,
    required this.propertyId,
    required this.propertyAddress,
    required this.ownerId,
    required this.category,
    required this.amount,
    required this.description,
    required this.date,
    this.receiptUrl,
    this.maintenanceTicketId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'propertyId': propertyId,
        'propertyAddress': propertyAddress,
        'ownerId': ownerId,
        'category': category,
        'amount': amount,
        'description': description,
        'date': Timestamp.fromDate(date),
        'receiptUrl': receiptUrl,
        'maintenanceTicketId': maintenanceTicketId,
      };

  factory PropertyExpense.fromJson(Map<String, dynamic> json) =>
      PropertyExpense(
        id: json['id'] as String,
        propertyId: json['propertyId'] as String,
        propertyAddress: json['propertyAddress'] as String? ?? 'Unknown',
        ownerId: json['ownerId'] as String,
        category: json['category'] as String,
        amount: (json['amount'] as num).toDouble(),
        description: json['description'] as String,
        date: (json['date'] as Timestamp).toDate(),
        receiptUrl: json['receiptUrl'] as String?,
        maintenanceTicketId: json['maintenanceTicketId'] as String?,
      );

  factory PropertyExpense.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PropertyExpense.fromJson({...data, 'id': doc.id});
  }
}

/// Document stored in vault
class PropertyDocument {
  final String id;
  final String propertyId;
  final String ownerId;
  final String? tenantId;
  final String documentType; // 'lease', 'id_proof', 'property_deed', 'receipt', 'other'
  final String fileName;
  final String fileUrl;
  final DateTime uploadedAt;
  final String uploadedBy;
  final int fileSizeBytes;

  PropertyDocument({
    required this.id,
    required this.propertyId,
    required this.ownerId,
    this.tenantId,
    required this.documentType,
    required this.fileName,
    required this.fileUrl,
    required this.uploadedAt,
    required this.uploadedBy,
    required this.fileSizeBytes,
  });

  String get fileSizeFormatted {
    if (fileSizeBytes < 1024) {
      return '$fileSizeBytes B';
    } else if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'propertyId': propertyId,
        'ownerId': ownerId,
        'tenantId': tenantId,
        'documentType': documentType,
        'fileName': fileName,
        'fileUrl': fileUrl,
        'uploadedAt': Timestamp.fromDate(uploadedAt),
        'uploadedBy': uploadedBy,
        'fileSizeBytes': fileSizeBytes,
      };

  factory PropertyDocument.fromJson(Map<String, dynamic> json) =>
      PropertyDocument(
        id: json['id'] as String,
        propertyId: json['propertyId'] as String,
        ownerId: json['ownerId'] as String,
        tenantId: json['tenantId'] as String?,
        documentType: json['documentType'] as String,
        fileName: json['fileName'] as String,
        fileUrl: json['fileUrl'] as String,
        uploadedAt: (json['uploadedAt'] as Timestamp).toDate(),
        uploadedBy: json['uploadedBy'] as String,
        fileSizeBytes: json['fileSizeBytes'] as int,
      );

  factory PropertyDocument.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PropertyDocument.fromJson({...data, 'id': doc.id});
  }
}
