import 'package:flutter/material.dart';
import '../data/models/models.dart';

class AppProvider with ChangeNotifier {
  List<Apartment> _apartments = [];
  List<Flat> _flats = [];
  List<User> _tenants = [];
  List<RentRecord> _rentRecords = [];
  List<PaymentRecord> _payments = [];

  List<Apartment> get apartments => _apartments;
  List<Flat> get flats => _flats;
  List<User> get tenants => _tenants;
  List<RentRecord> get rentRecords => _rentRecords;
  List<PaymentRecord> get payments => _payments;

  AppProvider() {
    _loadMockData();
  }

  void _loadMockData() {
    // Mock Apartments
    _apartments = [
      Apartment(id: 'apt_1', ownerId: 'owner_1', name: 'Shanti Niwas', address: '123 Sky Lane, Mumbai'),
    ];

    // Mock Flats
    _flats = [
      Flat(id: 'flat_1', apartmentId: 'apt_1', flatNumber: '101', floor: 1, monthlyRent: 15000, isOccupied: true, currentTenantId: 'tenant_1'),
      Flat(id: 'flat_2', apartmentId: 'apt_1', flatNumber: '102', floor: 1, monthlyRent: 12000, isOccupied: false),
      Flat(id: 'flat_3', apartmentId: 'apt_1', flatNumber: '201', floor: 2, monthlyRent: 18000, isOccupied: false),
    ];

    // Mock Tenants
    _tenants = [
      User(id: 'tenant_1', name: 'Rahul Sharma', email: 'tenant@hardik.com', role: UserRole.tenant, phoneNumber: '9876543210'),
    ];

    // Mock Rent Records
    _rentRecords = [
      RentRecord(
        id: 'rent_1',
        flatId: 'flat_1',
        tenantId: 'tenant_1',
        month: 'December 2025',
        amount: 15000,
        dueDate: DateTime(2025, 12, 10),
        status: RentStatus.pending,
      ),
      RentRecord(
        id: 'rent_0',
        flatId: 'flat_1',
        tenantId: 'tenant_1',
        month: 'November 2025',
        amount: 15000,
        dueDate: DateTime(2025, 11, 10),
        status: RentStatus.paid,
      ),
    ];
  }

  // Apartment Methods
  void addApartment(Apartment apt) {
    _apartments.add(apt);
    notifyListeners();
  }

  // Flat Methods
  void addFlat(Flat flat) {
    _flats.add(flat);
    notifyListeners();
  }

  void updateFlat(Flat flat) {
    final index = _flats.indexWhere((f) => f.id == flat.id);
    if (index != -1) {
      _flats[index] = flat;
      notifyListeners();
    }
  }

  // Tenant Methods
  void addTenant(User tenant, String flatId) {
    _tenants.add(tenant);
    final index = _flats.indexWhere((f) => f.id == flatId);
    if (index != -1) {
      _flats[index] = Flat(
        id: _flats[index].id,
        apartmentId: _flats[index].apartmentId,
        flatNumber: _flats[index].flatNumber,
        floor: _flats[index].floor,
        monthlyRent: _flats[index].monthlyRent,
        isOccupied: true,
        currentTenantId: tenant.id,
      );
    }
    notifyListeners();
  }

  // Rent Methods
  void generateMonthlyRent(String flatId, String month, double amount, DateTime dueDate) {
    final flat = _flats.firstWhere((f) => f.id == flatId);
    if (!flat.isOccupied || flat.currentTenantId == null) return;

    // Check for duplicates
    final exists = _rentRecords.any((r) => r.flatId == flatId && r.month == month);
    if (exists) return;

    final newRent = RentRecord(
      id: 'rent_${DateTime.now().millisecondsSinceEpoch}',
      flatId: flatId,
      tenantId: flat.currentTenantId!,
      month: month,
      amount: amount,
      dueDate: dueDate,
    );
    _rentRecords.add(newRent);
    notifyListeners();
  }

  // Payment Methods
  void submitPayment(PaymentRecord payment) {
    _payments.add(payment);
    notifyListeners();
  }

  void approvePayment(String paymentId) {
    final paymentIndex = _payments.indexWhere((p) => p.id == paymentId);
    if (paymentIndex != -1) {
      final payment = _payments[paymentIndex];
      _payments[paymentIndex] = PaymentRecord(
        id: payment.id,
        rentId: payment.rentId,
        tenantId: payment.tenantId,
        amount: payment.amount,
        transactionId: payment.transactionId,
        paymentDate: payment.paymentDate,
        screenshotUrl: payment.screenshotUrl,
        status: PaymentStatus.approved,
      );

      // Update Rent status
      final rentIndex = _rentRecords.indexWhere((r) => r.id == payment.rentId);
      if (rentIndex != -1) {
        final rent = _rentRecords[rentIndex];
        _rentRecords[rentIndex] = RentRecord(
          id: rent.id,
          flatId: rent.flatId,
          tenantId: rent.tenantId,
          month: rent.month,
          amount: rent.amount,
          dueDate: rent.dueDate,
          status: RentStatus.paid,
        );
      }
      notifyListeners();
    }
  }

  void rejectPayment(String paymentId) {
    final index = _payments.indexWhere((p) => p.id == paymentId);
    if (index != -1) {
      final p = _payments[index];
       _payments[index] = PaymentRecord(
        id: p.id,
        rentId: p.rentId,
        tenantId: p.tenantId,
        amount: p.amount,
        transactionId: p.transactionId,
        paymentDate: p.paymentDate,
        screenshotUrl: p.screenshotUrl,
        status: PaymentStatus.rejected,
      );
      notifyListeners();
    }
  }
}
