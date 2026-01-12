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
    this.joinedDate,
  });
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
}
