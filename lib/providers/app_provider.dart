import 'dart:async';
import 'package:flutter/material.dart';
import '../data/models/models.dart';
import '../services/api_service.dart';
import '../services/firebase_service.dart';

class AppProvider with ChangeNotifier {
  final FirebaseService _service = FirebaseService();
  final ApiService _apiService = ApiService();
  List<Apartment> _apartments = [];
  List<Flat> _flats = [];
  List<User> _tenants = [];
  List<RentRecord> _rentRecords = [];
  List<PaymentRecord> _payments = [];

  StreamSubscription? _flatsSub;
  StreamSubscription? _tenantsSub;
  StreamSubscription? _rentSub;
  StreamSubscription? _paymentSub;
  StreamSubscription? _apartmentsSub;

  List<Apartment> get apartments => _apartments;
  List<Flat> get flats => _flats;
  List<User> get tenants => _tenants;
  List<RentRecord> get rentRecords => _rentRecords;
  List<PaymentRecord> get payments => _payments;

    AppProvider() {

      fetchFlats();

      _flatsSub = _service.getFlats().listen((flats) {

        _flats = flats;

        notifyListeners();

      });

      _tenantsSub = _service.getTenants().listen((tenants) {

        _tenants = tenants;

        notifyListeners();

      });

      _rentSub = _service.getRentRecords().listen((rentRecords) {

        _rentRecords = rentRecords;

        notifyListeners();

      });

          _paymentSub = _service.getPayments().listen((payments) {

            _payments = payments;

            notifyListeners();

          });

          _apartmentsSub = _service.getApartments().listen((apartments) {

            _apartments = apartments;

            notifyListeners();

          });

        }

  Future<void> fetchFlats() async {
    try {
      final properties = await _apiService.getProperties();
      // Assuming getProperties returns a list of maps, and you have a way to convert them to Apartment and Flat objects
      // This part is complex and depends on your data structure.
      // For now, let's just print them.
      print(properties);
    } catch (e) {
      debugPrint('Error fetching flats: $e');
    }
  }

  Future<void> toggleElectricity(String flatId, bool isActive) async {
    try {
      await _apiService.toggleElectricity(flatId, isActive);
      // Optimistic Update
      final index = _flats.indexWhere((f) => f.id == flatId);
      if (index != -1) {
        final old = _flats[index];
        _flats[index] = Flat(
          id: old.id,
          apartmentId: old.apartmentId,
          flatNumber: old.flatNumber,
          floor: old.floor,
          monthlyRent: old.monthlyRent,
          isOccupied: old.isOccupied,
          currentTenantId: old.currentTenantId,
          isElectricityActive: isActive,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error toggling electricity: $e');
      rethrow;
    }
  }



  @override
  void dispose() {
    _flatsSub?.cancel();
    _tenantsSub?.cancel();
    _rentSub?.cancel();
    _paymentSub?.cancel();
    _apartmentsSub?.cancel();
    super.dispose();
  }

  // Apartment Methods
  Future<void> addProperty(String name, String address) async {
    try {
      await _apiService.createProperty({'name': name, 'address': address});
      await fetchFlats(); // Refresh data
    } catch (e) {
      debugPrint('Error creating property: $e');
    }
  }

  void addApartment(Apartment apt) {
    _apartments.add(apt);
    notifyListeners();
  }

  // Flat Methods
  Future<void> addFlat(Flat flat) async {
     try {
       await _apiService.createUnit({
         'propertyId': flat.apartmentId, // Using apartmentId as propertyId
         'unitNumber': flat.flatNumber,
         'floorNumber': flat.floor,
         'rentAmount': flat.monthlyRent
       });
       await fetchFlats();
     } catch (e) {
       debugPrint('Error adding flat: $e');
     }
  }

  Future<void> updateFlat(Flat flat) async {
     await _service.updateFlat(flat);
  }

  // Tenant Methods
  Future<void> addTenant(User tenant, String flatId) async {
    try {
      // 1. Create Tenant User in Backend
      // We'll use a new method for this
      final createdTenantId = await _apiService.createTenantUser(tenant);

      // 2. Assign to Unit
      await _apiService.updateUnitStatus(
        flatId, 
        'occupied',
        tenantId: createdTenantId
      );
      
      // Refresh local data
      await fetchFlats();
      
    } catch (e) {
      debugPrint('Error adding tenant: $e');
      rethrow;
    }
  }



  // Rent Methods
  Future<void> generateMonthlyRent(String flatId, String month, double amount, DateTime dueDate) async {
    final flat = _flats.firstWhere((f) => f.id == flatId, orElse: () => Flat(id: '', apartmentId: '', flatNumber: '', floor: 0, monthlyRent: 0));
    if (flat.id.isEmpty || !flat.isOccupied || flat.currentTenantId == null) return;

    // Check for duplicates in local list (optimistic check)
    final exists = _rentRecords.any((r) => r.flatId == flatId && r.month == month);
    if (exists) return;

    final now = DateTime.now();
    final newRent = RentRecord(
      id: '', // Auto-generated by Firebase
      flatId: flatId,
      tenantId: flat.currentTenantId!,
      month: month,
      baseRent: amount,
      generatedDate: now,
      dueDate: dueDate,
      status: RentStatus.pending,
      flag: RentFlag.yellow,
    );
    
    await _service.addRentRecord(newRent);
  }

  // Payment Methods
  Future<void> submitPayment(PaymentRecord payment) async {
    await _service.submitPayment(payment);
  }

  Future<void> approvePayment(String paymentId) async {
    // 1. Update Payment Status
    await _service.updatePaymentStatus(paymentId, PaymentStatus.approved);

    // 2. Update Rent Record (Client-side calculation logic migrated to server typically, but handling here for immediate sync)
    final payment = _payments.firstWhere((p) => p.id == paymentId);
    final rentIndex = _rentRecords.indexWhere((r) => r.id == payment.rentId);
    
    if (rentIndex != -1) {
      final rent = _rentRecords[rentIndex];
      final newAmountPaid = rent.amountPaid + payment.amount;
      final isFullyPaid = newAmountPaid >= rent.totalDue;
      
      final updatedRent = RentRecord(
        id: rent.id,
        flatId: rent.flatId,
        tenantId: rent.tenantId,
        month: rent.month,
        baseRent: rent.baseRent,
        electricityCharges: rent.electricityCharges,
        penaltyApplied: rent.penaltyApplied,
        amountPaid: newAmountPaid,
        generatedDate: rent.generatedDate,
        dueDate: rent.dueDate,
        status: isFullyPaid ? RentStatus.paid : (newAmountPaid > 0 ? RentStatus.partial : rent.status),
        flag: isFullyPaid ? RentFlag.green : rent.flag,
      );
      
      await _service.updateRentRecord(updatedRent);
    }
  }

  Future<void> rejectPayment(String paymentId) async {
    await _service.updatePaymentStatus(paymentId, PaymentStatus.rejected);
  }
}
