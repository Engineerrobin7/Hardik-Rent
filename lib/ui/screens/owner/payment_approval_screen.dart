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
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            expandedHeight: 180,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Payment Approvals'),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF6366F1).withAlpha(200), const Color(0xFF6366F1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Opacity(
                  opacity: 0.1,
                  child: Icon(Icons.verified_rounded, size: 200, color: Colors.white),
                ),
              ),
            ),
          ),
          if (app.isDataLoading)
            const SliverToBoxAdapter(
              child: LinearProgressIndicator(minHeight: 2),
            ),
          pendingPayments.isEmpty
              ? SliverFillRemaining(child: _buildEmptyState())
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final payment = pendingPayments[index];
                        final tenant = app.tenants.firstWhere(
                          (t) => t.id == payment.tenantId,
                          orElse: () => User(id: '', name: 'Unknown Tenant', email: '', role: UserRole.tenant),
                        );
                        final rent = app.rentRecords.firstWhere(
                          (r) => r.id == payment.rentId,
                          orElse: () => RentRecord(id: '', flatId: '', tenantId: '', month: 'Unknown', baseRent: 0, generatedDate: DateTime.now(), dueDate: DateTime.now(), status: RentStatus.pending, flag: RentFlag.yellow),
                        );
                        return _buildApprovalCard(context, payment, tenant, rent, app);
                      },
                      childCount: pendingPayments.length,
                    ),
                  ),
                ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
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
            decoration: BoxDecoration(color: Colors.indigo.withAlpha(12), shape: BoxShape.circle),
            child: Icon(Icons.check_circle_outline_rounded, size: 80, color: Colors.indigo.withAlpha(76)),
          ),
          const SizedBox(height: 24),
          const Text('All Caught Up!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('No pending payments to verify', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildApprovalCard(BuildContext context, PaymentRecord payment, User tenant, RentRecord rent, AppProvider app) {
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
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tenant.name,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: -0.5),
                    ),
                    Text(
                      'Rent for ${rent.month}',
                      style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ],
                ),
                Text(
                  '₹${payment.amount.toInt()}',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: AppTheme.primaryColor),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  _txnDetail(Icons.confirmation_number_rounded, 'Txn ID', payment.transactionId),
                  const SizedBox(height: 12),
                  _txnDetail(Icons.calendar_today_rounded, 'Date', DateFormat('dd MMM yyyy').format(payment.paymentDate)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => app.rejectPayment(payment.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.withAlpha(25),
                      foregroundColor: Colors.red,
                      elevation: 0,
                    ),
                    child: const Text('REJECT'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => app.approvePayment(payment.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('APPROVE'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _txnDetail(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 12),
        Text('$label: ', style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w600)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
