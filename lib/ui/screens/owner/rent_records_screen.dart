import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/app_provider.dart';
import '../../../data/models/models.dart';

class RentRecordsScreen extends StatelessWidget {
  const RentRecordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppProvider>(context);
    final records = app.rentRecords;

    return Scaffold(
      appBar: AppBar(title: const Text('Rent Records')),
      body: records.isEmpty
          ? const Center(child: Text('No rent records yet'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: records.length,
              itemBuilder: (context, index) {
                final record = records[index];
                final flat = app.flats.firstWhere((f) => f.id == record.flatId, orElse: () => Flat(id: '', apartmentId: '', flatNumber: '?', floor: 0, monthlyRent: 0));
                
                Color statusColor;
                switch (record.status) {
                  case RentStatus.paid:
                    statusColor = Colors.green;
                    break;
                  case RentStatus.overdue:
                    statusColor = Colors.red;
                    break;
                  default:
                    statusColor = Colors.orange;
                }

                return Card(
                  child: ListTile(
                    title: Text('${flat.flatNumber} - ${record.month}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Due: ${DateFormat('dd MMM yyyy').format(record.dueDate)}'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('₹${record.amount.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                          record.status.toString().split('.').last.toUpperCase(),
                          style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
