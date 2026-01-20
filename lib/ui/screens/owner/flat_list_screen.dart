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
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            expandedHeight: 180,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Flat Inventory'),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryColor.withAlpha(200), AppTheme.primaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Opacity(
                  opacity: 0.1,
                  child: Icon(Icons.apartment_rounded, size: 200, color: Colors.white),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () => app.fetchFlats(),
              ),
            ],
          ),
          if (app.isDataLoading)
            const SliverToBoxAdapter(
              child: LinearProgressIndicator(minHeight: 2),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Row(
                children: [
                  Icon(Icons.flash_on_rounded, color: Colors.amber, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Electricity Board Hub Active',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600, letterSpacing: 0.5),
                  ),
                ],
              ),
            ),
          ),
          app.flats.isEmpty
              ? SliverFillRemaining(child: _buildEmptyState())
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final flat = app.flats[index];
                        final apartment = app.apartments.firstWhere(
                          (a) => a.id == flat.apartmentId,
                          orElse: () => Apartment(id: '', name: 'Standard Property', address: '', ownerId: ''),
                        );
                        return _FlatCard(flat: flat, apartmentName: apartment.name);
                      },
                      childCount: app.flats.length,
                    ),
                  ),
                ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditFlatScreen())),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Flat'),
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
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditFlatScreen(flat: flat))),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Room ${flat.flatNumber}',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: -0.8),
                            ),
                            Text(
                              apartmentName,
                              style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      _StatusChip(status: flat.isOccupied ? 'Occupied' : 'Vacant'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _infoItem(Icons.grid_view_rounded, 'Floor ${flat.floor}'),
                      _infoItem(Icons.currency_rupee_rounded, '${flat.monthlyRent.toInt()}/mo'),
                    ],
                  ),
                  if (flat.isOccupied) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Divider(height: 1),
                    ),
                    _buildElectricityPanel(context),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildElectricityPanel(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: flat.isElectricityActive ? Colors.amber.withAlpha(30) : Colors.grey.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: Icon(
              flat.isElectricityActive ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              color: flat.isElectricityActive ? Colors.amber : Colors.grey,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  flat.isElectricityActive ? 'Power Active' : 'Disconnected',
                  style: TextStyle(fontWeight: FontWeight.w800, color: flat.isElectricityActive ? Colors.black87 : Colors.red),
                ),
                GestureDetector(
                  onTap: () async {
                    try {
                       final status = await Provider.of<AppProvider>(context, listen: false)
                        .checkElectricityStatus(flat.apartmentId, flat.id);
                       if (!context.mounted) return;
                       
                       _showBoardDetail(context, status['billDetails']);
                    } catch (e) {
                      debugPrint('Board Fetch Error: $e');
                    }
                  },
                  child: Text(
                    'Fetch Board Details >',
                    style: TextStyle(fontSize: 11, color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: flat.isElectricityActive,
            activeColor: Colors.amber,
            onChanged: (val) async {
              try {
                await Provider.of<AppProvider>(context, listen: false)
                    .toggleElectricity(flat.apartmentId, flat.id, val);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString().replaceAll('Exception: ', '')),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _showBoardDetail(BuildContext context, dynamic bill) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 24),
            Row(
              children: [
                const Icon(Icons.account_balance_rounded, color: AppTheme.primaryColor),
                const SizedBox(width: 12),
                const Text('State Electricity Board', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              ],
            ),
            const SizedBox(height: 32),
            _billRow('Consumer Number', bill['consumerNumber']),
            _billRow('Current Bill', '₹${bill['billAmount']}'),
            _billRow('Status', bill['status'], color: bill['status'] == 'PAID' ? Colors.green : Colors.red),
            _billRow('Due Date', bill['dueDate'].toString().substring(0, 10)),
            const SizedBox(height: 32),
            if (bill['status'] != 'PAID')
               const Text('⚠️ Important: Tenant has unpaid dues with the board. Owner can cut off power to enforce policy.', 
                 style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('GOT IT')),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _billRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
          Text(value, style: TextStyle(fontWeight: FontWeight.w900, color: color ?? Colors.black87)),
        ],
      ),
    );
  }

  Widget _infoItem(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: AppTheme.primaryColor.withAlpha(15), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 14, color: AppTheme.primaryColor),
        ),
        const SizedBox(width: 10),
        Text(text, style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.blueGrey, fontSize: 13)),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final isOccupied = status == 'Occupied';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isOccupied ? Colors.indigo.withAlpha(25) : Colors.orange.withAlpha(25),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: isOccupied ? Colors.indigo : Colors.orange,
          fontWeight: FontWeight.w900,
          fontSize: 11,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
