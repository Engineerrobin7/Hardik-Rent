import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/app_provider.dart';
import '../../../data/models/models.dart';

class AddEditFlatScreen extends StatefulWidget {
  final Flat? flat;

  const AddEditFlatScreen({super.key, this.flat});

  @override
  State<AddEditFlatScreen> createState() => _AddEditFlatScreenState();
}

class _AddEditFlatScreenState extends State<AddEditFlatScreen> {
  late TextEditingController _numberController;
  late TextEditingController _floorController;
  late TextEditingController _rentController;
  String? _selectedApartmentId;

  @override
  void initState() {
    super.initState();
    _numberController = TextEditingController(text: widget.flat?.flatNumber ?? '');
    _floorController = TextEditingController(text: widget.flat?.floor.toString() ?? '');
    _rentController = TextEditingController(text: widget.flat?.monthlyRent.toInt().toString() ?? '');
    _selectedApartmentId = widget.flat?.apartmentId;
  }

  void _saveFlat() {
    if (_numberController.text.isEmpty || _floorController.text.isEmpty || _rentController.text.isEmpty || _selectedApartmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    final app = Provider.of<AppProvider>(context, listen: false);
    
    if (widget.flat == null) {
      final newFlat = Flat(
        id: 'flat_${DateTime.now().millisecondsSinceEpoch}',
        apartmentId: _selectedApartmentId!,
        flatNumber: _numberController.text,
        floor: int.parse(_floorController.text),
        monthlyRent: double.parse(_rentController.text),
      );
      app.addFlat(newFlat);
    } else {
      final updatedFlat = Flat(
        id: widget.flat!.id,
        apartmentId: _selectedApartmentId!,
        flatNumber: _numberController.text,
        floor: int.parse(_floorController.text),
        monthlyRent: double.parse(_rentController.text),
        isOccupied: widget.flat!.isOccupied,
        currentTenantId: widget.flat!.currentTenantId,
      );
      app.updateFlat(updatedFlat);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final apartments = Provider.of<AppProvider>(context).apartments;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.flat == null ? 'Add Flat' : 'Edit Flat'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedApartmentId,
              decoration: const InputDecoration(labelText: 'Select Apartment'),
              items: apartments.map((apt) {
                return DropdownMenuItem(
                  value: apt.id,
                  child: Text(apt.name),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedApartmentId = val),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _numberController,
              decoration: const InputDecoration(labelText: 'Flat Number'),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _floorController,
              decoration: const InputDecoration(labelText: 'Floor'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _rentController,
              decoration: const InputDecoration(
                labelText: 'Monthly Rent (₹)',
                prefixText: '₹ ',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _saveFlat,
              child: Text(widget.flat == null ? 'Add Flat' : 'Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
