import 'package:flutter/material.dart';

enum FlatStatus { available, occupied, reserved, maintenance }

class FlatUnit {
  final String id;
  final String flatNumber;
  final int bhk;
  final double rentAmount;
  final FlatStatus status;

  FlatUnit({
    required this.id,
    required this.flatNumber,
    required this.bhk,
    required this.rentAmount,
    required this.status,
  });

  Color get statusColor {
    switch (status) {
      case FlatStatus.available: return Colors.green;
      case FlatStatus.occupied: return Colors.red;
      case FlatStatus.reserved: return Colors.orange;
      case FlatStatus.maintenance: return Colors.grey;
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

  Floor({required this.floorNumber, required this.flats});
}

class BuildingStructure {
  final String name;
  final List<Floor> floors;

  BuildingStructure({required this.name, required this.floors});

  static BuildingStructure generateDummyData() {
    return BuildingStructure(
      name: 'Sunrise Apartments',
      floors: List.generate(5, (floorIndex) => Floor(
        floorNumber: floorIndex + 1,
        flats: List.generate(4, (flatIndex) => FlatUnit(
          id: 'FL${floorIndex + 1}0${flatIndex + 1}',
          flatNumber: '${floorIndex + 1}0${flatIndex + 1}',
          bhk: (flatIndex % 2 == 0) ? 2 : 3,
          rentAmount: (flatIndex % 2 == 0) ? 15000 : 22000,
          status: (floorIndex == 2 && flatIndex == 1) ? FlatStatus.occupied : FlatStatus.available,
        )),
      )),
    );
  }
}
