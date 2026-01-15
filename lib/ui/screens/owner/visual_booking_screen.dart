import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../../theme/app_theme.dart';

class VisualBookingScreen extends StatefulWidget {
  final String propertyId;
  final String propertyName;

  const VisualBookingScreen({
    super.key, 
    required this.propertyId, 
    required this.propertyName
  });

  @override
  State<VisualBookingScreen> createState() => _VisualBookingScreenState();
}

class _VisualBookingScreenState extends State<VisualBookingScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _units = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUnits();
  }

  Future<void> _loadUnits() async {
    setState(() => _isLoading = true);
    try {
      final properties = await _apiService.getProperties();
      final currentProp = properties.firstWhere((p) => p['id'] == widget.propertyId);
      setState(() {
        _units = currentProp['units'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() => _isLoading = false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'vacant': return Colors.green.shade400;
      case 'occupied': return Colors.red.shade400;
      case 'maintenance': return Colors.orange.shade400;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.propertyName),
        actions: [
          IconButton(onPressed: _loadUnits, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Visual Floor Plan',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _legendItem('Vacant', Colors.green.shade400),
                    const SizedBox(width: 16),
                    _legendItem('Occupied', Colors.red.shade400),
                    const SizedBox(width: 16),
                    _legendItem('Maint.', Colors.orange.shade400),
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 1,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _units.length,
                    itemBuilder: (context, index) {
                      final unit = _units[index];
                      return GestureDetector(
                        onTap: () => _showUnitDetails(unit),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            color: _getStatusColor(unit['status']),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: _getStatusColor(unit['status']).withAlpha(76),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.door_front_door, color: Colors.white, size: 32),
                              const SizedBox(height: 4),
                              Text(
                                unit['unit_number'],
                                style: const TextStyle(
                                  color: Colors.white, 
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  void _showUnitDetails(dynamic unit) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Unit ${unit['unit_number']}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text('Status: ${unit['status'].toUpperCase()}', style: TextStyle(color: _getStatusColor(unit['status']), fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              if (unit['status'] == 'vacant') 
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Open booking dialog
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, minimumSize: const Size(double.infinity, 50)),
                  child: const Text('Mark as Booked'),
                ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
    );
  }
}
