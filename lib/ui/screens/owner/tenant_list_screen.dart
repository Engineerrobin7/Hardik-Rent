import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/app_provider.dart';
import '../../../data/models/models.dart';
import 'add_tenant_screen.dart';

class TenantListScreen extends StatelessWidget {
  const TenantListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tenants'),
      ),
      body: app.tenants.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text('No tenants added yet', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: app.tenants.length,
              itemBuilder: (context, index) {
                final tenant = app.tenants[index];
                final flat = app.flats.firstWhere((f) => f.currentTenantId == tenant.id, orElse: () => Flat(id: '', apartmentId: '', flatNumber: 'N/A', floor: 0, monthlyRent: 0));

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.indigo.withOpacity(0.1),
                      child: Text(tenant.name[0], style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
                    ),
                    title: Text(tenant.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Flat: ${flat.flatNumber} | ${tenant.phoneNumber ?? "No phone"}'),
                    trailing: const Icon(Icons.info_outline),
                    onTap: () {
                      // View tenant details
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddTenantScreen()),
          );
        },
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
