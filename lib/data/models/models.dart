// Core Data Models for HardikRent

enum UserRole { owner, tenant, admin }
enum RentStatus { pending, paid, partial, overdue }
enum RentFlag { 
  green, // Paid
  yellow, // Due soon (Grace period)
  red // Overdue
}

class Property {
  final String id;
  final String name;
  final String address;
  final int totalFlats;
  final int rentDueDay; // e.g., 5th of every month
  final int gracePeriodDays; // e.g., 5 days
  final double penaltyPerDay; // e.g., 100 per day
  final bool isMeteredElectricity;

  Property({
    required this.id,
    required this.name,
    required this.address,
    required this.totalFlats,
    this.rentDueDay = 5,
    this.gracePeriodDays = 3,
    this.penaltyPerDay = 100.0,
    this.isMeteredElectricity = true,
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      totalFlats: json['totalFlats'] ?? 0,
      rentDueDay: json['rentDueDay'] ?? 5,
      gracePeriodDays: json['gracePeriodDays'] ?? 3,
      penaltyPerDay: (json['penaltyPerDay'] ?? 100.0).toDouble(),
      isMeteredElectricity: json['isMeteredElectricity'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'totalFlats': totalFlats,
      'rentDueDay': rentDueDay,
      'gracePeriodDays': gracePeriodDays,
      'penaltyPerDay': penaltyPerDay,
      'isMeteredElectricity': isMeteredElectricity,
    };
  }
}

class Apartment {
  final String id;
  final String ownerId;
  final String name;
  final String address;

  Apartment({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.address,
  });

  factory Apartment.fromJson(Map<String, dynamic> json) {
    return Apartment(
      id: json['id'] ?? '',
      ownerId: json['ownerId'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerId': ownerId,
      'name': name,
      'address': address,
    };
  }
}

class Flat {
  final String id;
  final String apartmentId;
  final String flatNumber;
  final int floor;
  final double monthlyRent;
  final bool isOccupied;
  final String? currentTenantId;
  final bool isElectricityActive;

  Flat({
    required this.id,
    required this.apartmentId,
    required this.flatNumber,
    required this.floor,
    required this.monthlyRent,
    this.isOccupied = false,
    this.currentTenantId,
    this.isElectricityActive = true,
  });

  factory Flat.fromJson(Map<String, dynamic> json) {
    return Flat(
      id: json['id'] ?? '',
      apartmentId: json['apartmentId'] ?? json['propertyId'] ?? '',
      flatNumber: json['flatNumber'] ?? json['unitNumber'] ?? json['unit_number'] ?? '',
      floor: json['floor'] ?? json['floorNumber'] ?? json['floor_number'] ?? 0,
      monthlyRent: (json['monthlyRent'] ?? json['rent'] ?? json['rent_amount'] ?? 0.0) is String 
          ? double.tryParse(json['monthlyRent'] ?? json['rent'] ?? json['rent_amount'] ?? '0.0') ?? 0.0 
          : (json['monthlyRent'] ?? json['rent'] ?? json['rent_amount'] ?? 0.0).toDouble(),
      isOccupied: json['isOccupied'] ?? (json['status'] == 'occupied'),
      currentTenantId: json['currentTenantId'] ?? json['tenant_id'],
      isElectricityActive: json['isElectricityActive'] ?? (json['electricity']?['enabled'] ?? true),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'apartmentId': apartmentId,
      'flatNumber': flatNumber,
      'floor': floor,
      'monthlyRent': monthlyRent,
      'isOccupied': isOccupied,
      'currentTenantId': currentTenantId,
      'isElectricityActive': isElectricityActive,
    };
  }
}

class User {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? phoneNumber;
  final String? emergencyContact;
  final double? securityDeposit;
  final String? idProofUrl;
  final String? agreementUrl;
  final String? aadhaarNumber;
  final String? photoUrl;
  final DateTime? joinedDate;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phoneNumber,
    this.emergencyContact,
    this.securityDeposit,
    this.idProofUrl,
    this.agreementUrl,
    this.aadhaarNumber,
    this.photoUrl,
    this.joinedDate,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: UserRole.values.firstWhere((e) => e.toString() == 'UserRole.${json['role']}', orElse: () => UserRole.tenant),
      phoneNumber: json['phoneNumber'],
      emergencyContact: json['emergencyContact'],
      securityDeposit: (json['securityDeposit'] ?? 0.0).toDouble(),
      idProofUrl: json['idProofUrl'],
      agreementUrl: json['agreementUrl'],
      aadhaarNumber: json['aadhaarNumber'],
      photoUrl: json['photoUrl'],
      joinedDate: json['joinedDate'] != null ? DateTime.parse(json['joinedDate']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.toString().split('.').last,
      'phoneNumber': phoneNumber,
      'emergencyContact': emergencyContact,
      'securityDeposit': securityDeposit,
      'idProofUrl': idProofUrl,
      'agreementUrl': agreementUrl,
      'aadhaarNumber': aadhaarNumber,
      'photoUrl': photoUrl,
      'joinedDate': joinedDate?.toIso8601String(),
    };
  }
}

class RentRecord {
  final String id;
  final String flatId;
  final String tenantId;
  final String month; // e.g., "December 2025"
  final DateTime generatedDate;
  final DateTime dueDate;
  
  // Financials
  final double baseRent;
  final double electricityCharges;
  final double penaltyApplied;
  final double amountPaid;
  
  final RentStatus status;
  final RentFlag flag;

  RentRecord({
    required this.id,
    required this.flatId,
    required this.tenantId,
    required this.month,
    required this.generatedDate,
    required this.dueDate,
    required this.baseRent,
    this.electricityCharges = 0.0,
    this.penaltyApplied = 0.0,
    this.amountPaid = 0.0,
    required this.status,
    required this.flag,
  });

  factory RentRecord.fromJson(Map<String, dynamic> json) {
    return RentRecord(
      id: json['id'] ?? '',
      flatId: json['flatId'] ?? '',
      tenantId: json['tenantId'] ?? '',
      month: json['month'] ?? '',
      generatedDate: DateTime.parse(json['generatedDate']),
      dueDate: DateTime.parse(json['dueDate']),
      baseRent: (json['baseRent'] ?? 0.0).toDouble(),
      electricityCharges: (json['electricityCharges'] ?? 0.0).toDouble(),
      penaltyApplied: (json['penaltyApplied'] ?? 0.0).toDouble(),
      amountPaid: (json['amountPaid'] ?? 0.0).toDouble(),
      status: RentStatus.values.firstWhere((e) => e.toString() == 'RentStatus.${json['status']}', orElse: () => RentStatus.pending),
      flag: RentFlag.values.firstWhere((e) => e.toString() == 'RentFlag.${json['flag']}', orElse: () => RentFlag.yellow),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'flatId': flatId,
      'tenantId': tenantId,
      'month': month,
      'generatedDate': generatedDate.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'baseRent': baseRent,
      'electricityCharges': electricityCharges,
      'penaltyApplied': penaltyApplied,
      'amountPaid': amountPaid,
      'status': status.toString().split('.').last,
      'flag': flag.toString().split('.').last,
    };
  }

  double get totalDue => baseRent + electricityCharges + penaltyApplied;
  double get pendingAmount => totalDue - amountPaid;
}

enum PaymentStatus { pending, approved, rejected }

class PaymentRecord {
  final String id;
  final String rentId;
  final String tenantId;
  final double amount;
  final String transactionId;
  final DateTime paymentDate;
  final String? screenshotUrl;
  final PaymentStatus status;

  PaymentRecord({
    required this.id,
    required this.rentId,
    required this.tenantId,
    required this.amount,
    required this.transactionId,
    required this.paymentDate,
    this.screenshotUrl,
    this.status = PaymentStatus.pending,
  });

  factory PaymentRecord.fromJson(Map<String, dynamic> json) {
    return PaymentRecord(
      id: json['id'] ?? '',
      rentId: json['rentId'] ?? '',
      tenantId: json['tenantId'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      transactionId: json['transactionId'] ?? '',
      paymentDate: DateTime.parse(json['paymentDate']),
      screenshotUrl: json['screenshotUrl'],
      status: PaymentStatus.values.firstWhere((e) => e.toString() == 'PaymentStatus.${json['status']}', orElse: () => PaymentStatus.pending),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rentId': rentId,
      'tenantId': tenantId,
      'amount': amount,
      'transactionId': transactionId,
      'paymentDate': paymentDate.toIso8601String(),
      'screenshotUrl': screenshotUrl,
      'status': status.toString().split('.').last,
    };
  }
}


