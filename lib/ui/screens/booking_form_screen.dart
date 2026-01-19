import 'package:flutter/material.dart';
import '../../data/models/visual_booking_models.dart'; // Assuming FlatUnit is here

class BookingFormScreen extends StatelessWidget {
  final FlatUnit selectedFlat;

  const BookingFormScreen({Key? key, required this.selectedFlat}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Your Flat'),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Booking Details for Flat No. ${selectedFlat.flatNumber}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text('BHK: ${selectedFlat.bhk}'),
            Text('Rent Amount: ₹${selectedFlat.rentAmount}/mo'),
            const SizedBox(height: 30),
            const Text(
              'Booking form elements would go here.',
              style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
            ),
            // TODO: Add actual booking form fields (e.g., tenant details, date pickers)
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Implement actual booking logic
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Booking functionality not yet implemented.')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Confirm Booking',
                  style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
