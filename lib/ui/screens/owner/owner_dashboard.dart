import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/app_provider.dart';
import '../../../data/models/models.dart';
import '../../theme/app_theme.dart';
import '../owner/flat_list_screen.dart';
import '../owner/tenant_list_screen.dart';
import 'payment_approval_screen.dart';
import 'rent_records_screen.dart';
import '../shared/profile_screen.dart';

class OwnerDashboard extends StatefulWidget {
  const OwnerDashboard({super.key});

  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final app = Provider.of<AppProvider>(context);

    final totalFlats = app.flats.length;
    final occupiedFlats = app.flats.where((f) => f.isOccupied).length;
    final vacantFlats = totalFlats - occupiedFlats;
    
    double totalCollection = 0;
    for (var r in app.rentRecords) {
      if (r.status == RentStatus.paid) {
        totalCollection += r.amount;
      }
    }

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient Decor
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryColor.withOpacity(0.1),
              ),
            ),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Good Morning,',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                              ),
                              Text(
                                auth.currentUser?.name ?? "Landlord",
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen())),
                            child: Hero(
                              tag: 'profile_pic',
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppTheme.primaryColor, width: 2),
                                ),
                                child: CircleAvatar(
                                  radius: 24,
                                  backgroundColor: AppTheme.primaryColor,
                                  child: const Icon(Icons.person, color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _buildMainStatCard(totalCollection),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.1,
                      ),
                      delegate: SliverChildListDelegate([
                        _StatMiniCard(
                          title: 'Total Flats',
                          value: totalFlats.toString(),
                          icon: Icons.apartment_rounded,
                          gradient: const [Color(0xFF6366F1), Color(0xFF818CF8)],
                        ),
                        _StatMiniCard(
                          title: 'Occupied',
                          value: occupiedFlats.toString(),
                          icon: Icons.person_pin_rounded,
                          gradient: const [Color(0xFF10B981), Color(0xFF34D399)],
                        ),
                        _StatMiniCard(
                          title: 'Vacant',
                          value: vacantFlats.toString(),
                          icon: Icons.night_shelter_rounded,
                          gradient: const [Color(0xFFF59E0B), Color(0xFFFBBF24)],
                        ),
                        _StatMiniCard(
                          title: 'Overdue',
                          value: app.rentRecords.where((r) => r.status == RentStatus.overdue).length.toString(),
                          icon: Icons.warning_amber_rounded,
                          gradient: const [Color(0xFFEF4444), Color(0xFFF87171)],
                        ),
                      ]),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Quick Actions',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 16),
                          _InteractiveActionTile(
                            title: 'Manage Flats',
                            subtitle: 'Add or modify properties',
                            icon: Icons.domain_add_rounded,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FlatListScreen())),
                          ),
                          _InteractiveActionTile(
                            title: 'Tenant Directory',
                            subtitle: 'Active member profiles',
                            icon: Icons.badge_rounded,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TenantListScreen())),
                          ),
                          _InteractiveActionTile(
                            title: 'Payment Approvals',
                            subtitle: 'Verify transactions',
                            icon: Icons.verified_rounded,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PaymentApprovalScreen())),
                          ),
                          _InteractiveActionTile(
                            title: 'Collection History',
                            subtitle: 'Detailed revenue logs',
                            icon: Icons.history_edu_rounded,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RentRecordsScreen())),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainStatCard(double collection) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Monthly Collection',
                style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'USD',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '₹${collection.toInt()}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Icon(Icons.trending_up, color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              Text(
                '+12% from last month',
                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatMiniCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final List<Color> gradient;

  const _StatMiniCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -1),
          ),
          Text(
            title,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _InteractiveActionTile extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _InteractiveActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_InteractiveActionTile> createState() => _InteractiveActionTileState();
}

class _InteractiveActionTileState extends State<_InteractiveActionTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isHovered = true),
      onTapUp: (_) => setState(() => _isHovered = false),
      onTapCancel: () => setState(() => _isHovered = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _isHovered ? AppTheme.primaryColor.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isHovered ? AppTheme.primaryColor.withOpacity(0.3) : Colors.grey.shade100,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(widget.icon, color: AppTheme.primaryColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  Text(
                    widget.subtitle,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
