// Sprint 5: Visual Booking Screen
// File: lib/ui/screens/tenant/visual_booking_screen.dart

import 'package:flutter/material.dart';
import '../../../data/models/visual_booking_models.dart';
import 'booking_form_screen.dart';

class VisualBookingScreen extends StatefulWidget {
  const VisualBookingScreen({Key? key}) : super(key: key);

  @override
  State<VisualBookingScreen> createState() => _VisualBookingScreenState();
}

class _VisualBookingScreenState extends State<VisualBookingScreen> {
  // Using dummy data for layout demonstration
  final BuildingStructure _building = BuildingStructure.generateDummyData();
  FlatUnit? _selectedFlat;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(_building.name),
        backgroundColor: Colors.blue[900], // Premium color
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 1. Legend (Status Indicators)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLegendItem(FlatStatus.available),
                _buildLegendItem(FlatStatus.occupied),
                _buildLegendItem(FlatStatus.reserved),
              ],
            ),
          ),
          
          const Divider(height: 1),

          // 2. The Visual Grid (Flight Style)
          Expanded(
            child: InteractiveViewer( // Allows zooming and panning
              minScale: 0.5,
              maxScale: 2.0,
              child: ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: _building.floors.length,
                itemBuilder: (context, index) {
                  // Floors are usually listed bottom-up in real life, 
                  // but for booking apps top-down (Floor 5 -> 1) is often clearer.
                  // Let's do Top-Down (Floor 5 at top).
                  final floor = _building.floors[_building.floors.length - 1 - index];
                  
                  return _buildFloorRow(floor);
                },
              ),
            ),
          ),
        ],
      ),
      
      // 3. Selected Flat Details (Bottom Sheet style)
      bottomNavigationBar: _selectedFlat != null ? _buildSelectionBar() : null,
    );
  }

  // --- Widgets ---

  Widget _buildLegendItem(FlatStatus status) {
    FlatUnit dummyMap = FlatUnit(id: '', flatNumber: '', bhk: 0, rentAmount: 0, status: status); 
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: dummyMap.statusColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          dummyMap.statusText,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildFloorRow(Floor floor) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Floor Label (Left side)
            Container(
              width: 40,
              alignment: Alignment.center,
              child: Text(
                'FL ${floor.floorNumber}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            
            const SizedBox(width: 16),

            // Flats Container (The "Fuselage")
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    offset: const Offset(0, 4),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Left Wing
                  _buildFlatItem(floor.flats[0]),
                  const SizedBox(width: 12),
                  _buildFlatItem(floor.flats[1]),

                  // Corridor Space
                  Container(
                    width: 40, 
                    height: 50,
                    alignment: Alignment.center,
                    child: Icon(Icons.elevator, size: 16, color: Colors.grey[300]),
                  ),

                  // Right Wing
                  _buildFlatItem(floor.flats[2]),
                  const SizedBox(width: 12),
                  _buildFlatItem(floor.flats[3]),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16), // Spacing between floors
      ],
    );
  }

  Widget _buildFlatItem(FlatUnit flat) {
    bool isSelected = _selectedFlat?.id == flat.id;
    
    return GestureDetector(
      onTap: () {
        if (flat.status == FlatStatus.occupied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This flat is already occupied')),
          );
          return;
        }
        setState(() {
          _selectedFlat = flat;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: isSelected ? flat.statusColor : flat.statusColor.withAlpha(51),
          border: Border.all(
            color: flat.statusColor,
            width: isSelected ? 3 : 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.home_filled, // Or Icons.chair for flight style
              size: 20,
              color: isSelected ? Colors.white : flat.statusColor,
            ),
            const SizedBox(height: 2),
            Text(
              flat.flatNumber,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : flat.statusColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Flat No. ${_selectedFlat!.flatNumber}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    '${_selectedFlat!.bhk} BHK Apartment',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${_selectedFlat!.rentAmount}/mo',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                  const Text(
                    '+ Maintenance',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                if (_selectedFlat != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookingFormScreen(flat: _selectedFlat!),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[800],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Book This Flat',
                style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
