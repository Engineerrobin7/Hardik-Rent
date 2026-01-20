import 'dart:async';
import 'package:flutter/material.dart';
import '../data/models/models.dart';
import '../data/models/visual_booking_models.dart';
import '../services/api_service.dart';
import '../services/firebase_service.dart';

class AppProvider extends ChangeNotifier {
  final FirebaseService _service = FirebaseService();
  final ApiService _apiService = ApiService();

  List<Flat> _flats = [];
  List<User> _tenants = [];
  List<RentRecord> _rentRecords = [];
  List<PaymentRecord> _payments = [];
  List<Apartment> _apartments = [];

  StreamSubscription? _flatsSub;
  StreamSubscription? _tenantsSub;
  StreamSubscription? _rentSub;
  StreamSubscription? _paymentSub;
  StreamSubscription? _apartmentsSub;

  List<Flat> get flats => _flats;
  List<User> get tenants => _tenants;
  List<RentRecord> get rentRecords => _rentRecords;
  List<PaymentRecord> get payments => _payments;
  List<Apartment> get apartments => _apartments;

  bool _isDataLoading = false;
  bool get isDataLoading => _isDataLoading;

  AppProvider() {
    _initializeData();
  }

  Future<void> _initializeData() async {
    _isDataLoading = true;
    notifyListeners();

    try {
      await fetchFlats();
      
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
    } catch (e) {
      debugPrint('Initialization Error: $e');
    } finally {
      _isDataLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchFlats() async {
    try {
      final List<dynamic> propertiesData = await _apiService.getProperties();
      
      List<Apartment> apartments = [];
      List<Flat> allFlats = [];

      for (var prop in propertiesData) {
        final apt = Apartment.fromJson(prop);
        apartments.add(apt);
        
        // Fetch units for each property if the backend provides them in the same call or requires another
        // Assuming the backend returns units within the property data for performance
        if (prop['units'] != null) {
          for (var unitData in prop['units']) {
            allFlats.add(Flat.fromJson({
              ...unitData,
              'apartmentId': apt.id,
            }));
          }
        }
      }

      _apartments = apartments;
      _flats = allFlats;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching flats: $e');
    }
  }

  Future<void> toggleElectricity(String propertyId, String flatId, bool enabled) async {
    try {
      await _apiService.toggleElectricity(propertyId, flatId, enabled);
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
          isElectricityActive: enabled,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error toggling electricity: $e');
      rethrow; // Important: rethrow for UI handling (e.g. Snackbars with specific error messages)
    }
  }

  Future<Map<String, dynamic>> checkElectricityStatus(String propertyId, String unitId) async {
    return await _apiService.getElectricityStatus(propertyId, unitId);
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
  Future<void> addProperty(String name, String address, String type) async {
    try {
      await _apiService.createProperty({
        'name': name,
        'address': address,
        'type': type,
      });
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
         'propertyId': flat.apartmentId,
         'unitNumber': flat.flatNumber,
         'floor': flat.floor,
         'rent': flat.monthlyRent,
         'type': 'Standard', // Default type
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
  Future<void> addTenant({
    required User tenant,
    required String propertyId,
    required String unitId,
  }) async {
    try {
      // 1. Create and Assign Tenant in one Go via Backend
      await _apiService.createTenantUser(
        name: tenant.name,
        email: tenant.email,
        phone: tenant.phoneNumber ?? '',
        propertyId: propertyId,
        unitId: unitId,
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
  BuildingStructure? getBuildingStructure(String apartmentId) {
    if (_apartments.isEmpty) return null;
    final aptIndex = _apartments.indexWhere((a) => a.id == apartmentId);
    if (aptIndex == -1) return null;
    final apt = _apartments[aptIndex];

    final aptFlats = _flats.where((f) => f.apartmentId == apartmentId).toList();
    
    // Group by floor
    final Map<int, List<FlatUnit>> floorMap = {};
    for (var flat in aptFlats) {
      final flatUnit = FlatUnit(
        id: flat.id,
        flatNumber: flat.flatNumber,
        bhk: 2, // Default or parse from some field if available
        rentAmount: flat.monthlyRent,
        status: flat.isOccupied ? FlatStatus.occupied : FlatStatus.available,
      );
      floorMap.putIfAbsent(flat.floor, () => []).add(flatUnit);
    }

    final floors = floorMap.entries.map((e) {
       final sortedFlats = e.value;
       sortedFlats.sort((a, b) => a.flatNumber.compareTo(b.flatNumber));
       return Floor(floorNumber: e.key, flats: sortedFlats);
    }).toList();
    
    floors.sort((a, b) => a.floorNumber.compareTo(b.floorNumber));

    return BuildingStructure(name: apt.name, floors: floors);
  }
}
