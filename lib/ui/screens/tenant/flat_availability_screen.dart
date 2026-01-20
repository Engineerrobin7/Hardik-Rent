import 'package:provider/provider.dart';
import '../../../providers/app_provider.dart';
import '../../theme/app_theme.dart';

class FlatAvailabilityScreen extends StatelessWidget {
  final String? apartmentId;

  const FlatAvailabilityScreen({super.key, this.apartmentId});

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppProvider>(context);
    final flats = app.flats.where((f) => f.apartmentId == apartmentId).toList();
    final apartment = app.apartments.firstWhere((a) => a.id == apartmentId, orElse: () => Apartment(id: '', name: 'Building', address: '', ownerId: ''));

    return Scaffold(
      appBar: AppBar(
        title: Text(apartment.name),
      ),
      body: Column(
        children: [
          if (app.isDataLoading) const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text('${flats.length} units listed in this building', style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          Expanded(
            child: flats.isEmpty 
              ? const Center(child: Text('No units found in this building.'))
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: flats.length,
                  itemBuilder: (context, index) {
                    final flat = flats[index];
                    return _AvailabilityCard(flat: flat);
                  },
                ),
          ),
        ],
      ),
    );
  }
}

class _AvailabilityCard extends StatelessWidget {
  final dynamic flat;
  const _AvailabilityCard({required this.flat});

  @override
  Widget build(BuildContext context) {
    bool isOccupied = flat.isOccupied;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isOccupied ? Colors.grey.shade200 : AppTheme.primaryColor.withAlpha(51)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isOccupied ? Icons.do_not_disturb_on_rounded : Icons.check_circle_rounded,
            color: isOccupied ? Colors.grey : Colors.green,
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            'Flat ${flat.flatNumber}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          Text(
            'Floor ${flat.floor}',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            isOccupied ? 'Occupied' : 'Available',
            style: TextStyle(
              color: isOccupied ? Colors.grey : Colors.green,
              fontWeight: FontWeight.w900,
              fontSize: 10,
              letterSpacing: 1,
            ),
          ),
          if (!isOccupied) ...[
            const SizedBox(height: 8),
            Text(
              '₹${flat.monthlyRent.toInt()}',
              style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.primaryColor),
            ),
          ]
        ],
      ),
    );
  }
}
