import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/app_provider.dart';
import '../../../data/models/models.dart';
import '../../theme/app_theme.dart';
import 'flat_availability_screen.dart';
import 'payment_submission_screen.dart';
import '../shared/profile_screen.dart';
import 'visual_booking_screen.dart';

class TenantDashboard extends StatefulWidget {
  const TenantDashboard({super.key});

  @override
  State<TenantDashboard> createState() => _TenantDashboardState();
}

class _TenantDashboardState extends State<TenantDashboard> with TickerProviderStateMixin {
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final app = Provider.of<AppProvider>(context);
    final user = auth.currentUser;

    final tenantRentRecords = app.rentRecords.where((r) => r.tenantId == user?.id).toList();
    tenantRentRecords.sort((a, b) => b.dueDate.compareTo(a.dueDate));

    final pendingRent = tenantRentRecords.firstWhere(
      (r) => r.status == RentStatus.pending || r.status == RentStatus.overdue,
      orElse: () => RentRecord(
        id: '', 
        flatId: '', 
        tenantId: '', 
        month: '', 
        baseRent: 0, 
        dueDate: DateTime.now(),
        generatedDate: DateTime.now(),
        status: RentStatus.pending,
        flag: RentFlag.green,
      ),
    );

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.secondaryColor.withAlpha(12),
              ),
            ),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeController,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Welcome back,', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                            Text(user?.name ?? "Tenant", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                          ],
                        ),
                        Hero(
                          tag: 'profile_pic',
                          child: InkWell(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen())),
                            child: CircleAvatar(
                              radius: 26,
                              backgroundColor: AppTheme.secondaryColor,
                              child: const Icon(Icons.person, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    _buildPremiumRentCard(context, pendingRent),
                    const SizedBox(height: 24),
                    _buildFlatAvailabilityCard(context),
                    const SizedBox(height: 40),
                    const Text('Rent History', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 16),
                    if (tenantRentRecords.isEmpty)
                      const Center(child: Text('You have no rent history yet.'))
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: tenantRentRecords.length,
                        itemBuilder: (context, index) {
                          return _HistoryTile(record: tenantRentRecords[index]);
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumRentCard(BuildContext context, RentRecord rent) {
    if (rent.id.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 20)],
        ),
        child: Column(
          children: [
            const Icon(Icons.verified_user_rounded, color: Colors.green, size: 60),
            const SizedBox(height: 16),
            const Text('Everything Paid!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            Text('You are all set for this month.', style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    final isOverdue = rent.status == RentStatus.overdue;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isOverdue 
            ? [const Color(0xFFEF4444), const Color(0xFFB91C1C)] 
            : [AppTheme.primaryColor, const Color(0xFF4338CA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: (isOverdue ? Colors.red : AppTheme.primaryColor).withAlpha(89),
            blurRadius: 25,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                rent.month.toUpperCase(),
                style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w800, letterSpacing: 1.5),
              ),
              const Icon(Icons.wifi, color: Colors.white54),
            ],
          ),
          const SizedBox(height: 24),
          const Text('CURRENT DUE', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
          Text(
            '₹${rent.totalDue.toInt()}',
            style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.w900, letterSpacing: -1),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('DUE DATE', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                  Text(
                    DateFormat('dd MMM yyyy').format(rent.dueDate),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PaymentSubmissionScreen(rent: rent))),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: isOverdue ? Colors.red : AppTheme.primaryColor,
                  minimumSize: const Size(100, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('PAY NOW'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFlatAvailabilityCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(7), blurRadius: 20, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Check Flat Availability', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('Explore available flats in different buildings.', style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 20),
          const SizedBox(height: 20),
          _buildBuildingTile(context, 'Sunrise Apartments', '1'),
          const Divider(height: 10),
          _buildBuildingTile(context, 'Greenwood Complex', '2'),
          const SizedBox(height: 24),
          
          // New Visual Booking Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.grid_view_rounded),
              label: const Text("Book Flat (Visual View)"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[800],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const VisualBookingScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuildingTile(BuildContext context, String buildingName, String apartmentId) {
    return ListTile(
      leading: const Icon(Icons.apartment_rounded, color: AppTheme.primaryColor),
      title: Text(buildingName, style: const TextStyle(fontWeight: FontWeight.bold)),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FlatAvailabilityScreen(apartmentId: apartmentId),
          ),
        );
      },
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final RentRecord record;
  const _HistoryTile({required this.record});

  @override
  Widget build(BuildContext context) {
    bool isPaid = record.status == RentStatus.paid;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isPaid ? Colors.green : Colors.orange).withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPaid ? Icons.check_circle_rounded : Icons.pending_rounded,
              color: isPaid ? Colors.green : Colors.orange,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record.month, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                Text(
                  isPaid ? 'Paid on ${DateFormat('dd MMM').format(record.dueDate)}' : 'Payment Pending',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
              ],
            ),
          ),
          Text(
            '₹${record.totalDue.toInt()}',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
