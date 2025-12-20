import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/app_provider.dart';
import '../../../data/models/models.dart';

class PaymentApprovalScreen extends StatelessWidget {
  const PaymentApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppProvider>(context);
    final pendingPayments = app.payments.where((p) => p.status == PaymentStatus.pending).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Payment Approvals')),
      body: pendingPayments.isEmpty
          ? const Center(child: Text('No pending approvals'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: pendingPayments.length,
              itemBuilder: (context, index) {
                final payment = pendingPayments[index];
                final tenant = app.tenants.firstWhere((t) => t.id == payment.tenantId);
                final rent = app.rentRecords.firstWhere((r) => r.id == payment.rentId);

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              tenant.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            Text(
                              '₹${payment.amount.toInt()}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.indigo),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Rent for: ${rent.month}'),
                        Text('Txn ID: ${payment.transactionId}'),
                        Text('Date: ${DateFormat('dd MMM yyyy').format(payment.paymentDate)}'),
                        const Divider(height: 32),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => app.rejectPayment(payment.id),
                                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                                child: const Text('Reject'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => app.approvePayment(payment.id),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                child: const Text('Approve'),
                              ),
                            ),
                          ],
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
