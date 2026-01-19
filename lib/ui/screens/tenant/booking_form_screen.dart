import 'package:flutter/material.dart';
import '../../../data/models/visual_booking_models.dart';

class BookingFormScreen extends StatefulWidget {
  final FlatUnit flat;

  const BookingFormScreen({Key? key, required this.flat}) : super(key: key);

  @override
  _BookingFormScreenState createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Book Flat ${widget.flat.flatNumber}'),
      ),
      body: Center(
        child: Text('Booking form for Flat ${widget.flat.flatNumber}'),
      ),
    );
  }
}
