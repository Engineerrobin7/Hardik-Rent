import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/app_provider.dart';
import '../../../data/models/models.dart';

class AddTenantScreen extends StatefulWidget {
  const AddTenantScreen({super.key});

  @override
  State<AddTenantScreen> createState() => _AddTenantScreenState();
}

class _AddTenantScreenState extends State<AddTenantScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _selectedFlatId;

  bool _isSaving = false;

  Future<void> _saveTenant() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _selectedFlatId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields')));
      return;
    }

    setState(() => _isSaving = true);
    final app = Provider.of<AppProvider>(context, listen: false);
    
    try {
      final newTenant = User(
        id: 'tenant_${DateTime.now().millisecondsSinceEpoch}',
        name: _nameController.text,
        email: _emailController.text,
        role: UserRole.tenant,
        phoneNumber: _phoneController.text,
      );

      final selectedFlat = app.flats.firstWhere((f) => f.id == _selectedFlatId);
      
      await app.addTenant(
        tenant: newTenant,
        propertyId: selectedFlat.apartmentId,
        unitId: _selectedFlatId!,
      );
      
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableFlats = Provider.of<AppProvider>(context).flats.where((f) => !f.isOccupied).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Tenant'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Tenant Full Name *'),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email Address *'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone Number'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              initialValue: _selectedFlatId,
              decoration: const InputDecoration(labelText: 'Assign to Flat *'),
              items: availableFlats.map((f) {
                return DropdownMenuItem(
                  value: f.id,
                  child: Text('Flat ${f.flatNumber} (Floor ${f.floor})'),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedFlatId = val),
              hint: const Text('Select an empty flat'),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveTenant,
                child: _isSaving 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                  : const Text('Add Tenant'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
