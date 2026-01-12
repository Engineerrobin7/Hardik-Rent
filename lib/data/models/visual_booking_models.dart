// Sprint 5: Visual Booking Models
// File: lib/data/models/visual_booking_models.dart

import 'package:flutter/material.dart';

enum FlatStatus { available, occupied, reserved, maintenance }

class FlatUnit {
  final String id;
  final String flatNumber; // e.g., "101", "102"
  final int bhk; // 1, 2, 3
  final double rentAmount;
  final FlatStatus status;
  final String? tenantId;
  final List<String> features; // ["Balcony", "Corner", "Garden View"]

  FlatUnit({
    required this.id,
    required this.flatNumber,
    required this.bhk,
    required this.rentAmount,
    required this.status,
    this.tenantId,
    this.features = const [],
  });

  // Helper properties for UI
  Color get statusColor {
    switch (status) {
      case FlatStatus.available:
        return Colors.green; // 🟩 Available
      case FlatStatus.occupied:
        return Colors.red; // 🟥 Occupied
      case FlatStatus.reserved:
        return Colors.orange; // 🟧 Reserved
      case FlatStatus.maintenance:
        return Colors.grey; // ⬜ Maintenance
    }
  }

  String get statusText {
    switch (status) {
      case FlatStatus.available: return 'Available';
      case FlatStatus.occupied: return 'Occupied';
      case FlatStatus.reserved: return 'Reserved';
      case FlatStatus.maintenance: return 'Maintenance';
    }
  }
}

class Floor {
  final int floorNumber;
  final List<FlatUnit> flats;

  Floor({
    required this.floorNumber,
    required this.flats,
  });
}

class BuildingStructure {
  final String buildingId;
  final String name; // e.g., "Wing A"
  final int totalFloors;
  final int flatsPerFloor;
  final List<Floor> floors;

  BuildingStructure({
    required this.buildingId,
    required this.name,
    required this.totalFloors,
    required this.flatsPerFloor,
    required this.floors,
  });
  
  // Demo Data Generator
  static BuildingStructure generateDummyData() {
    return BuildingStructure(
      buildingId: 'b1',
      name: 'Sunrise Apartments - Wing A',
      totalFloors: 5,
      flatsPerFloor: 4,
      floors: List.generate(5, (floorIndex) {
        int floorNum = floorIndex + 1;
        return Floor(
          floorNumber: floorNum,
          flats: List.generate(4, (flatIndex) {
            // Logic to simulate random statuses
            int flatNum = (floorNum * 100) + (flatIndex + 1);
            FlatStatus status = FlatStatus.available;
            
            if (flatNum % 3 == 0) status = FlatStatus.occupied;
            else if (flatNum % 7 == 0) status = FlatStatus.reserved;
            
            return FlatUnit(
              id: 'f_$flatNum',
              flatNumber: flatNum.toString(),
              bhk: (flatIndex % 2) + 2, // Alternating 2BHK and 3BHK
              rentAmount: 15000 + (floorIndex * 500) + (flatIndex * 200),
              status: status,
              features: ['Balcony', 'Modular Kitchen'],
            );
          }),
        );
      }),
    );
  }
}
