import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/app_provider.dart';
import '../../../data/models/models.dart';
import '../../theme/app_theme.dart';
import 'add_edit_flat_screen.dart';

class FlatListScreen extends StatelessWidget {
  const FlatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Global Flat Inventory'),
      ),
      body: app.flats.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              itemCount: app.flats.length,
              itemBuilder: (context, index) {
                final flat = app.flats[index];
                final apartment = app.apartments.firstWhere((a) => a.id == flat.apartmentId, orElse: () => Apartment(id: '', name: 'Unknown', address: '', ownerId: ''));

                return _FlatCard(flat: flat, apartmentName: apartment.name);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditFlatScreen())),
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Flat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(color: AppTheme.primaryColor.withAlpha(12), shape: BoxShape.circle),
            child: Icon(Icons.domain_disabled_rounded, size: 80, color: AppTheme.primaryColor.withAlpha(76)),
          ),
          const SizedBox(height: 24),
          const Text('No Flats Found', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Start by adding your first property', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class _FlatCard extends StatelessWidget {
  final Flat flat;
  final String apartmentName;

  const _FlatCard({required this.flat, required this.apartmentName});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditFlatScreen(flat: flat))),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('FLAT ${flat.flatNumber}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: -0.5)),
                      Text(apartmentName, style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: (flat.isOccupied ? Colors.indigo : Colors.orange).withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      flat.isOccupied ? 'OCCUPIED' : 'VACANT',
                      style: TextStyle(
                        color: flat.isOccupied ? Colors.indigo : Colors.orange,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(height: 1),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _infoItem(Icons.layers_rounded, 'Floor ${flat.floor}'),
                  _infoItem(Icons.payments_rounded, '₹${flat.monthlyRent.toInt()}'),
                  const Icon(Icons.arrow_forward_rounded, size: 20, color: AppTheme.primaryColor),
                ],
              ),
              const SizedBox(height: 16),
              if (flat.isOccupied) ...[
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          flat.isElectricityActive ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                          color: flat.isElectricityActive ? Colors.amber : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          flat.isElectricityActive ? 'Power ON' : 'Power CUT',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: flat.isElectricityActive ? Colors.black87 : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: flat.isElectricityActive,
                      activeThumbColor: Colors.amber,
                      onChanged: (val) {
                         Provider.of<AppProvider>(context, listen: false).toggleElectricity(flat.id, val);
                      },
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade400),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.blueGrey)),
      ],
    );
  }
}
