import 'package:flutter/material.dart';

class FlatAvailabilityScreen extends StatelessWidget {
  final String? apartmentId;

  const FlatAvailabilityScreen({super.key, this.apartmentId});

  @override
  Widget build(BuildContext context) {
    // This is a placeholder for the flat availability UI.
    // We will build a grid view that shows buildings and flats within them.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flat Availability'),
      ),
      body: Center(
        child: Text('Viewing Availability for Building: $apartmentId\n\nComing Soon: A grid to show available flats!'),
      ),
    );
  }
}
