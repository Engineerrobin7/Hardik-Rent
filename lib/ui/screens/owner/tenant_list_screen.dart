import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../providers/app_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/models/models.dart';
import '../../theme/app_theme.dart';
import '../shared/chat_screen.dart';
import 'add_tenant_screen.dart';

class TenantListScreen extends StatelessWidget {
  const TenantListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppProvider>(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            expandedHeight: 180,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Tenant Directory'),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.secondaryColor.withAlpha(200), AppTheme.secondaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Opacity(
                  opacity: 0.1,
                  child: Icon(Icons.people_alt_rounded, size: 200, color: Colors.white),
                ),
              ),
            ),
          ),
          if (app.isDataLoading)
            const SliverToBoxAdapter(
              child: LinearProgressIndicator(minHeight: 2),
            ),
          app.tenants.isEmpty
              ? SliverFillRemaining(child: _buildEmptyState())
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final tenant = app.tenants[index];
                        final flat = app.flats.firstWhere(
                          (f) => f.currentTenantId == tenant.id,
                          orElse: () => Flat(id: '', apartmentId: '', flatNumber: 'N/A', floor: 0, monthlyRent: 0),
                        );
                        return _buildTenantCard(context, tenant, flat, app);
                      },
                      childCount: app.tenants.length,
                    ),
                  ),
                ),
           const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddTenantScreen()),
          );
        },
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add Tenant'),
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
            decoration: BoxDecoration(color: AppTheme.secondaryColor.withAlpha(12), shape: BoxShape.circle),
            child: Icon(Icons.group_off_rounded, size: 80, color: AppTheme.secondaryColor.withAlpha(76)),
          ),
          const SizedBox(height: 24),
          const Text('No Tenants Found', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Active member profiles will appear here', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildTenantCard(BuildContext context, User tenant, Flat flat, AppProvider app) {
    // Determine flag based on latest rent record
    final rents = app.rentRecords.where((r) => r.tenantId == tenant.id).toList();
    rents.sort((a, b) => b.dueDate.compareTo(a.dueDate));
    
    RentFlag flag = RentFlag.green;
    if (rents.isNotEmpty) {
      flag = rents.first.flag;
    }

    Color flagColor;
    String statusText;
    switch (flag) {
      case RentFlag.green: 
        flagColor = Colors.green; 
        statusText = 'ALL CLEARED';
        break;
      case RentFlag.yellow: 
        flagColor = Colors.orange; 
        statusText = 'DUE SOON';
        break;
      case RentFlag.red: 
        flagColor = Colors.red; 
        statusText = 'OVERDUE';
        break;
    }

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
      child: InkWell(
        onTap: () {}, // View Details
        borderRadius: BorderRadius.circular(30),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [flagColor.withAlpha(30), flagColor.withAlpha(51)],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: flagColor, width: 2),
                ),
                child: Center(
                  child: Text(
                    tenant.name[0].toUpperCase(),
                    style: TextStyle(color: flagColor, fontWeight: FontWeight.w900, fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tenant.name,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                    ),
                    const SizedBox(height: 4),
                     Text(
                      'Flat ${flat.flatNumber} • ${tenant.phoneNumber ?? 'No Contact'}',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: flagColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: flagColor, letterSpacing: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppTheme.secondaryColor),
                    onPressed: () {
                      final auth = Provider.of<AuthProvider>(context, listen: false);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            chatRoomId: 'chat_${auth.currentUser!.id}_${tenant.id}',
                            currentUserId: auth.currentUser!.id,
                            currentUserName: auth.currentUser!.name,
                            otherUserId: tenant.id,
                            otherUserName: tenant.name,
                            propertyAddress: flat.flatNumber != 'N/A' ? 'Flat ${flat.flatNumber}' : 'Property',
                          ),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.phone_outlined, color: Colors.green),
                    onPressed: () async {
                       final Uri telLaunchUri = Uri(
                        scheme: 'tel',
                        path: tenant.phoneNumber ?? '',
                      );
                      if (await canLaunchUrl(telLaunchUri)) {
                        await launchUrl(telLaunchUri);
                      }
                    },
                  ),
                ],
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade300),
            ],
          ),
        ),
      ),
    );
  }
}
