enum UserRole { superAdmin, owner, tenant }

class User {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? phoneNumber;
  final String? profileImageUrl;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phoneNumber,
    this.profileImageUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: UserRole.values.firstWhere((e) => e.toString().split('.').last == json['role']),
      phoneNumber: json['phoneNumber'],
      profileImageUrl: json['profileImageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.toString().split('.').last,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
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
      id: json['id'],
      ownerId: json['ownerId'],
      name: json['name'],
      address: json['address'],
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

  Flat({
    required this.id,
    required this.apartmentId,
    required this.flatNumber,
    required this.floor,
    required this.monthlyRent,
    this.isOccupied = false,
    this.currentTenantId,
  });

  factory Flat.fromJson(Map<String, dynamic> json) {
    return Flat(
      id: json['id'],
      apartmentId: json['apartmentId'],
      flatNumber: json['flatNumber'],
      floor: json['floor'],
      monthlyRent: json['monthlyRent'].toDouble(),
      isOccupied: json['isOccupied'] ?? false,
      currentTenantId: json['currentTenantId'],
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
    };
  }
}

class TenantProfile {
  final String userId;
  final String flatId;
  final DateTime joinedDate;

  TenantProfile({
    required this.userId,
    required this.flatId,
    required this.joinedDate,
  });

  factory TenantProfile.fromJson(Map<String, dynamic> json) {
    return TenantProfile(
      userId: json['userId'],
      flatId: json['flatId'],
      joinedDate: DateTime.parse(json['joinedDate']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'flatId': flatId,
      'joinedDate': joinedDate.toIso8601String(),
    };
  }
}

enum RentStatus { pending, paid, overdue }

class RentRecord {
  final String id;
  final String flatId;
  final String tenantId;
  final String month; // e.g., "October 2023"
  final double amount;
  final DateTime dueDate;
  final RentStatus status;

  RentRecord({
    required this.id,
    required this.flatId,
    required this.tenantId,
    required this.month,
    required this.amount,
    required this.dueDate,
    this.status = RentStatus.pending,
  });

  factory RentRecord.fromJson(Map<String, dynamic> json) {
    return RentRecord(
      id: json['id'],
      flatId: json['flatId'],
      tenantId: json['tenantId'],
      month: json['month'],
      amount: json['amount'].toDouble(),
      dueDate: DateTime.parse(json['dueDate']),
      status: RentStatus.values.firstWhere((e) => e.toString().split('.').last == json['status']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'flatId': flatId,
      'tenantId': tenantId,
      'month': month,
      'amount': amount,
      'dueDate': dueDate.toIso8601String(),
      'status': status.toString().split('.').last,
    };
  }
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
      id: json['id'],
      rentId: json['rentId'],
      tenantId: json['tenantId'],
      amount: json['amount'].toDouble(),
      transactionId: json['transactionId'],
      paymentDate: DateTime.parse(json['paymentDate']),
      screenshotUrl: json['screenshotUrl'],
      status: PaymentStatus.values.firstWhere((e) => e.toString().split('.').last == json['status']),
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
