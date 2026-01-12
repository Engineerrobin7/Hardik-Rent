import 'dart:math';

import '../data/models/models.dart';

class FlatProvider {
  // Mock data - replace with actual API call
  final Map<String, List<Flat>> _flatsByApartment = {
    '1': List.generate(20, (index) => Flat(
      id: '1-${index + 1}',
      apartmentId: '1',
      flatNumber: 'A${index + 1}',
      floor: (index / 4).floor() + 1,
      monthlyRent: 10000 + Random().nextInt(5000).toDouble(),
      isOccupied: index % 3 != 0,
    )),
    '2': List.generate(12, (index) => Flat(
      id: '2-${index + 1}',
      apartmentId: '2',
      flatNumber: 'B${index + 1}',
      floor: (index / 4).floor() + 1,
      monthlyRent: 12000 + Random().nextInt(6000).toDouble(),
      isOccupied: index % 4 != 0,
    )),
  };

  Future<List<Flat>> fetchFlatsForApartment(String apartmentId) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    if (_flatsByApartment.containsKey(apartmentId)) {
      return _flatsByApartment[apartmentId]!;
    } else {
      throw Exception('Apartment not found');
    }
  }

  // In a real app, you would also have a method to fetch apartments
  Future<List<Apartment>> fetchApartments() async {
    await Future.delayed(const Duration(seconds: 1));
    return [
      Apartment(id: '1', ownerId: 'owner1', name: 'Sunrise Apartments', address: '123 Main St'),
      Apartment(id: '2', ownerId: 'owner2', name: 'Greenwood Complex', address: '456 Oak Ave'),
    ];
  }
}
