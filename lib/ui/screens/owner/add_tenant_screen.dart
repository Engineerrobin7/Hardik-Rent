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

  void _saveTenant() {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _selectedFlatId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields')));
      return;
    }

    final app = Provider.of<AppProvider>(context, listen: false);
    
    final newTenant = User(
      id: 'tenant_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text,
      email: _emailController.text,
      role: UserRole.tenant,
      phoneNumber: _phoneController.text,
    );

    app.addTenant(newTenant, _selectedFlatId!);
    Navigator.pop(context);
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
            ElevatedButton(
              onPressed: _saveTenant,
              child: const Text('Add Tenant'),
            ),
          ],
        ),
      ),
    );
  }
}
