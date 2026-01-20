import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/app_provider.dart';
import '../../../data/models/models.dart';
import '../../../data/models/visual_booking_models.dart';
import '../../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../owner/flat_list_screen.dart';
import '../owner/tenant_list_screen.dart';
import 'payment_approval_screen.dart';
import 'rent_records_screen.dart';
import 'electricity_hub_screen.dart';
import '../shared/profile_screen.dart';

class OwnerDashboard extends StatefulWidget {
  const OwnerDashboard({super.key});

  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _analyticsData;


  @override
  void initState() {
    super.initState();
    _fetchStats();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  Future<void> _fetchStats() async {
    try {
      final stats = await _apiService.getOwnerAnalytics();
      setState(() {
        _analyticsData = stats;
      });
    } catch (e) {
      debugPrint('Error fetching analytics: $e');
    }
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

    final totalFlats = _analyticsData?['stats']?['totalUnits'] ?? app.flats.length;
    final occupiedFlats = _analyticsData?['stats']?['occupiedUnits'] ?? app.flats.where((f) => f.isOccupied).length;

    
    double totalCollection = (_analyticsData?['totalRevenue'] ?? 0).toDouble();
    double pendingRent = (_analyticsData?['pendingRent'] ?? 0).toDouble();
    String occupancyRate = _analyticsData?['occupancyRate']?.toString() ?? "0";

    final screenWidth = MediaQuery.of(context).size.width;
    final childAspectRatio = screenWidth > 400 ? 1.2 : 1.1;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await _fetchStats();
          await app.fetchFlats();
        },
        child: Stack(
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
                  color: AppTheme.primaryColor.withAlpha(25),
                ),
              ),
            ),
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    if (app.isDataLoading)
                      const SliverToBoxAdapter(
                        child: LinearProgressIndicator(minHeight: 2),
                      ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
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
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
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
                                  child: const CircleAvatar(
                                    radius: 24,
                                    backgroundColor: AppTheme.primaryColor,
                                    child: Icon(Icons.person, color: Colors.white),
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

                    // NEW: Real-time Visual Map for Owner
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Live Property Map',
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                                ),
                                TextButton.icon(
                                  onPressed: () => app.fetchFlats(),
                                  icon: const Icon(Icons.refresh_rounded, size: 16),
                                  label: const Text('SYNC'),
                                )
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (app.apartments.isEmpty)
                               Container(
                                 height: 100,
                                 decoration: GlassDecoration.decoration,
                                 child: const Center(child: Text('Add an apartment building to see live status')),
                               )
                            else
                               _OwnerVisualBuildingMap(apartmentId: app.apartments.first.id),
                          ],
                        ),
                      ),
                    ),

                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: screenWidth > 600 ? 3 : 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: childAspectRatio,
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
                            title: 'Occupancy',
                            value: '$occupancyRate%',
                            icon: Icons.pie_chart_rounded,
                            gradient: const [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                          ),
                          _StatMiniCard(
                            title: 'Pending Rent',
                            value: '₹${pendingRent.toInt()}',
                            icon: Icons.hourglass_empty_rounded,
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
                              title: 'Electricity Hub',
                              subtitle: 'Board-Level Bill Fetching & Controls',
                              icon: Icons.electric_bolt_rounded,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ElectricityHubScreen())),
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
            color: AppTheme.primaryColor.withAlpha(102),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Monthly Collection',
            style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600),
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
        ],
      ),
    );
  }
}

class _OwnerVisualBuildingMap extends StatelessWidget {
  final String apartmentId;
  const _OwnerVisualBuildingMap({required this.apartmentId});

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppProvider>(context);
    final structure = app.getBuildingStructure(apartmentId);

    if (structure == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: GlassDecoration.decoration.copyWith(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.blue.shade50.withAlpha(127)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(color: Colors.green, label: 'Vacant'),
              const SizedBox(width: 16),
              _LegendDot(color: Colors.red, label: 'Occupied'),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: structure.floors.length,
              itemBuilder: (context, floorIdx) {
                final floor = structure.floors[floorIdx];
                return Container(
                  margin: const EdgeInsets.only(right: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Column(
                    children: [
                      Text('FL ${floor.floorNumber}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const Spacer(),
                      // The 'Aeroplane' Grid (2 x N with aisle)
                      Row(
                        children: [
                           // Left Column
                           Column(
                             children: floor.flats.take((floor.flats.length / 2).ceil()).map((f) => _UnitSeat(flat: f)).toList(),
                           ),
                           // Aisle
                           Container(
                             width: 12,
                             margin: const EdgeInsets.symmetric(horizontal: 4),
                             height: 60,
                             decoration: BoxDecoration(
                               color: Colors.grey.shade50,
                               borderRadius: BorderRadius.circular(2),
                             ),
                           ),
                           // Right Column
                           Column(
                             children: floor.flats.skip((floor.flats.length / 2).ceil()).map((f) => _UnitSeat(flat: f)).toList(),
                           ),
                        ],
                      ),
                      const Spacer(),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
      ],
    );
  }
}

class _UnitSeat extends StatelessWidget {
  final FlatUnit flat;
  const _UnitSeat({required this.flat});

  @override
  Widget build(BuildContext context) {
    final isOccupied = flat.status == FlatStatus.occupied;
    return Container(
      width: 24,
      height: 24,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isOccupied ? Colors.red.withAlpha(51) : Colors.green.withAlpha(51),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: isOccupied ? Colors.red : Colors.green, width: 1),
      ),
      child: Center(
        child: Text(
          flat.flatNumber.length > 2 ? flat.flatNumber.substring(flat.flatNumber.length - 2) : flat.flatNumber,
          style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: isOccupied ? Colors.red : Colors.green),
        ),
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
            color: Colors.black.withAlpha(5),
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
          color: _isHovered ? AppTheme.primaryColor.withAlpha(12) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isHovered ? AppTheme.primaryColor.withAlpha(76) : Colors.grey.shade100,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withAlpha(25),
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
