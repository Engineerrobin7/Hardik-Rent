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
            if (apartments.isEmpty)
              GestureDetector(
                onTap: () {
                   // Quick placeholder to add a property
                   // In a real app we'd show a dialog. For now, let's auto-create one for testing.
                   _showAddPropertyDialog(context);
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
                  child: const Row(children: [Icon(Icons.add), SizedBox(width: 8), Text("Create New Property")])),
              )
            else
              DropdownButtonFormField<String>(
                initialValue: _selectedApartmentId,
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
  Future<void> _showAddPropertyDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final addressController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Property'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Property Name')),
            TextField(controller: addressController, decoration: const InputDecoration(labelText: 'Address')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty && addressController.text.isNotEmpty) {
                final navigator = Navigator.of(context);
                await Provider.of<AppProvider>(context, listen: false).addProperty(
                  nameController.text,
                  addressController.text,
                );
                navigator.pop();
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
