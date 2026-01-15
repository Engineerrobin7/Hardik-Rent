// Sprint 1: Insights Screen with Analytics
// File: lib/ui/screens/owner/insights_screen.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../data/services/analytics_service.dart';
import '../../../data/models/analytics_models.dart';


class InsightsScreen extends StatefulWidget {
  final String ownerId;

  const InsightsScreen({Key? key, required this.ownerId}) : super(key: key);

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
  
  bool _isLoading = true;
  List<RevenueData> _revenueData = [];
  PaymentAnalytics? _paymentAnalytics;
  List<TenantBehavior> _tenantBehaviors = [];
  DashboardSummary? _dashboardSummary;

  int _selectedMonths = 6;
  String _selectedPeriod = '6 Months';

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);

    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month - _selectedMonths, 1);
    final endDate = DateTime(now.year, now.month + 1, 0);

    final results = await Future.wait([
      _analyticsService.getMonthlyRevenue(widget.ownerId, _selectedMonths),
      _analyticsService.getPaymentAnalytics(widget.ownerId, startDate, endDate),
      _analyticsService.getTenantBehaviors(widget.ownerId),
      _analyticsService.getDashboardSummary(widget.ownerId),
    ]);

    setState(() {
      _revenueData = results[0] as List<RevenueData>;
      _paymentAnalytics = results[1] as PaymentAnalytics;
      _tenantBehaviors = results[2] as List<TenantBehavior>;
      _dashboardSummary = results[3] as DashboardSummary;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Analytics & Insights'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.calendar_month),
            onSelected: (months) {
              setState(() {
                _selectedMonths = months;
                _selectedPeriod = months == 3
                    ? '3 Months'
                    : months == 6
                        ? '6 Months'
                        : '12 Months';
              });
              _loadAnalytics();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 3, child: Text('Last 3 Months')),
              const PopupMenuItem(value: 6, child: Text('Last 6 Months')),
              const PopupMenuItem(value: 12, child: Text('Last 12 Months')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dashboard Summary Cards
                    if (_dashboardSummary != null) _buildSummaryCards(),

                    const SizedBox(height: 24),

                    // Revenue Chart
                    _buildSectionHeader('Revenue Trends', Icons.trending_up),
                    const SizedBox(height: 12),
                    _buildRevenueChart(),

                    const SizedBox(height: 24),

                    // Payment Analytics
                    if (_paymentAnalytics != null) ...[
                      _buildSectionHeader('Payment Analytics', Icons.analytics),
                      const SizedBox(height: 12),
                      _buildPaymentAnalytics(),
                      const SizedBox(height: 24),
                    ],

                    // Tenant Behavior
                    _buildSectionHeader('Tenant Performance', Icons.people),
                    const SizedBox(height: 12),
                    _buildTenantBehaviors(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryCards() {
    final summary = _dashboardSummary!;
    
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildSummaryCard(
          'Total Properties',
          summary.totalProperties.toString(),
          Icons.home,
          Colors.blue,
        ),
        _buildSummaryCard(
          'Occupancy Rate',
          '${summary.occupancyRate.toStringAsFixed(1)}%',
          Icons.people,
          Colors.green,
        ),
        _buildSummaryCard(
          'Monthly Revenue',
          '₹${_formatAmount(summary.monthlyRevenue)}',
          Icons.currency_rupee,
          Colors.orange,
        ),
        _buildSummaryCard(
          'Pending Amount',
          '₹${_formatAmount(summary.pendingAmount)}',
          Icons.pending,
          Colors.red,
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue[700], size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueChart() {
    if (_revenueData.isEmpty) {
      return _buildEmptyState('No revenue data available');
    }

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedPeriod,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Total: ₹${_formatAmount(_revenueData.fold(0.0, (sum, item) => sum + item.amount))}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _revenueData.map((e) => e.amount).reduce((a, b) => a > b ? a : b) * 1.2,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '₹${rod.toY.toStringAsFixed(0)}',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < _revenueData.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              _revenueData[value.toInt()].month,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '₹${_formatAmount(value)}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 10000,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey[300],
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: _revenueData.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.amount,
                        color: Colors.blue[700],
                        width: 20,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentAnalytics() {
    final analytics = _paymentAnalytics!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Pie Chart
          SizedBox(
            height: 200,
            child: Row(
              children: [
                Expanded(
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 50,
                      sections: [
                        PieChartSectionData(
                          value: analytics.onTimePayments.toDouble(),
                          title: '${analytics.onTimePercentage.toStringAsFixed(0)}%',
                          color: Colors.green,
                          radius: 60,
                          titleStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        PieChartSectionData(
                          value: analytics.latePayments.toDouble(),
                          title: '${analytics.latePercentage.toStringAsFixed(0)}%',
                          color: Colors.orange,
                          radius: 60,
                          titleStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLegendItem('On Time', Colors.green, analytics.onTimePayments),
                    const SizedBox(height: 12),
                    _buildLegendItem('Late', Colors.orange, analytics.latePayments),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Stats
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Collection Rate',
                  '${analytics.collectionRate.toStringAsFixed(1)}%',
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Avg. Delay',
                  '${analytics.averageCollectionTime.toStringAsFixed(0)} days',
                  Icons.schedule,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, int count) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Text(
              count.toString(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTenantBehaviors() {
    if (_tenantBehaviors.isEmpty) {
      return _buildEmptyState('No tenant data available');
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _tenantBehaviors.length,
        separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[200]),
        itemBuilder: (context, index) {
          final tenant = _tenantBehaviors[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _getStatusColor(tenant.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Center(
                child: Text(
                  tenant.statusEmoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            title: Text(
              tenant.tenantName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  tenant.propertyAddress,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'On-time: ${tenant.onTimeRate.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${tenant.totalPayments} payments',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(tenant.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tenant.status.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${_formatAmount(tenant.totalPaid)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.analytics_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'excellent':
        return Colors.green;
      case 'good':
        return Colors.blue;
      case 'average':
        return Colors.orange;
      case 'poor':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatAmount(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }
}
