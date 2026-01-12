import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/app_provider.dart';
import '../../../data/models/models.dart';
import 'add_tenant_screen.dart';

class TenantListScreen extends StatelessWidget {
  const TenantListScreen({super.key});

  @override
  Widget _buildTenantItem(BuildContext context, User tenant, Flat flat, AppProvider app) {
    // Determine flag based on latest rent record
    final rents = app.rentRecords.where((r) => r.tenantId == tenant.id).toList();
    rents.sort((a, b) => b.dueDate.compareTo(a.dueDate));
    
    RentFlag flag = RentFlag.green; // Default to green if no history
    if (rents.isNotEmpty) {
      flag = rents.first.flag;
    }

    Color flagColor;
    switch (flag) {
      case RentFlag.green: flagColor = Colors.green; break;
      case RentFlag.yellow: flagColor = Colors.orange; break;
      case RentFlag.red: flagColor = Colors.red; break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: flagColor.withOpacity(0.3), width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: flagColor, width: 2),
          ),
          child: CircleAvatar(
            backgroundColor: flagColor.withOpacity(0.1),
            child: Text(
              tenant.name[0], 
              style: TextStyle(color: flagColor, fontWeight: FontWeight.bold)
            ),
          ),
        ),
        title: Text(tenant.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Flat: ${flat.flatNumber} | ${tenant.phoneNumber ?? "No phone"}'),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: flagColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                flag == RentFlag.green ? 'ALL CLEARED' : (flag == RentFlag.yellow ? 'DUE SOON' : 'OVERDUE'),
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: flagColor),
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () {
          // View tenant details
        },
      ),
    );
  }

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
                return _buildTenantItem(context, tenant, flat, app);
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
