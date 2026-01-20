import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/app_provider.dart';
import '../../../data/models/models.dart';
import '../../theme/app_theme.dart';

class ElectricityHubScreen extends StatefulWidget {
  const ElectricityHubScreen({super.key});

  @override
  State<ElectricityHubScreen> createState() => _ElectricityHubScreenState();
}

class _ElectricityHubScreenState extends State<ElectricityHubScreen> {
  bool _isBulkFetching = false;
  Map<String, dynamic> _bulkStatus = {};

  Future<void> _fetchAllBills() async {
    setState(() => _isBulkFetching = true);
    final app = Provider.of<AppProvider>(context, listen: false);
    
    Map<String, dynamic> results = {};
    for (var flat in app.flats.where((f) => f.isOccupied)) {
       try {
         final status = await app.checkElectricityStatus(flat.apartmentId, flat.id);
         results[flat.id] = status;
       } catch (e) {
         results[flat.id] = {'error': e.toString()};
       }
    }

    setState(() {
      _bulkStatus = results;
      _isBulkFetching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppProvider>(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            expandedHeight: 200,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Electricity Hub'),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Opacity(
                  opacity: 0.1,
                  child: Icon(Icons.bolt_rounded, size: 240, color: Colors.white),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   const Text(
                    'State Board Integration',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Fetch real-time bill data from the board and manage power access for all occupied units.',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isBulkFetching ? null : _fetchAllBills,
                      icon: _isBulkFetching 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.sync_rounded),
                      label: Text(_isBulkFetching ? 'FETCHING BOARD DATA...' : 'SYNC ALL UTILITY BILLS'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber[800],
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final flat = app.flats.where((f) => f.isOccupied).toList()[index];
                  final status = _bulkStatus[flat.id];
                  return _UtilityCard(flat: flat, status: status);
                },
                childCount: app.flats.where((f) => f.isOccupied).length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class _UtilityCard extends StatelessWidget {
  final Flat flat;
  final dynamic status;
  const _UtilityCard({required this.flat, this.status});

  @override
  Widget build(BuildContext context) {
    bool isUnpaid = status != null && status['billDetails'] != null && status['billDetails']['status'] != 'PAID';
    bool hasPower = flat.isElectricityActive;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isUnpaid ? Colors.red.shade100 : Colors.grey.shade100, width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Flat ${flat.flatNumber}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                  Text(isUnpaid ? '⚠️ UNPAID BOARD BILL' : 'Board Status: OK', 
                    style: TextStyle(color: isUnpaid ? Colors.red : Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
              Switch.adaptive(
                value: hasPower,
                activeColor: Colors.amber,
                onChanged: (val) {
                   Provider.of<AppProvider>(context, listen: false).toggleElectricity(flat.apartmentId, flat.id, val);
                },
              ),
            ],
          ),
          if (status != null && status['billDetails'] != null) ...[
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _miniDetail('Bill', '₹${status['billDetails']['billAmount']}'),
                _miniDetail('Consumer', status['billDetails']['consumerNumber']),
                status['billDetails']['status'] == 'PAID' 
                  ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
                  : const Icon(Icons.warning_rounded, color: Colors.red, size: 20),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _miniDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 10, fontWeight: FontWeight.bold)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
      ],
    );
  }
}
