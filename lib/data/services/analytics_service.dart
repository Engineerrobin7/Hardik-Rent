// Sprint 1: Analytics Service
// File: lib/data/services/analytics_service.dart

import 'package:flutter/foundation.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/analytics_models.dart';

class AnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get revenue data for the last N months
  Future<List<RevenueData>> getMonthlyRevenue(String ownerId, int months) async {
    try {
      final now = DateTime.now();
      final List<RevenueData> revenueList = [];

      for (int i = months - 1; i >= 0; i--) {
        final month = DateTime(now.year, now.month - i, 1);
        final monthStr = '${month.year}-${month.month.toString().padLeft(2, '0')}';

        // Get all payments for this month
        final paymentsSnapshot = await _firestore
            .collection('payments')
            .where('ownerId', isEqualTo: ownerId)
            .where('month', isEqualTo: monthStr)
            .get();

        double totalAmount = 0;
        int paidCount = 0;
        int pendingCount = 0;
        Set<String> properties = {};

        for (var doc in paymentsSnapshot.docs) {
          final data = doc.data();
          final status = data['status'] as String?;
          
          properties.add(data['propertyId'] as String);
          
          if (status == 'paid') {
            totalAmount += (data['amount'] as num).toDouble();
            paidCount++;
          } else {
            pendingCount++;
          }
        }

        revenueList.add(RevenueData(
          month: _getMonthName(month.month),
          amount: totalAmount,
          propertyCount: properties.length,
          paidCount: paidCount,
          pendingCount: pendingCount,
        ));
      }

      return revenueList;
    } catch (e) {
      debugPrint('Error getting monthly revenue: $e');
      return [];
    }
  }

  /// Get payment analytics for a specific period
  Future<PaymentAnalytics> getPaymentAnalytics(
    String ownerId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final paymentsSnapshot = await _firestore
          .collection('payments')
          .where('ownerId', isEqualTo: ownerId)
          .where('dueDate', isGreaterThanOrEqualTo: startDate)
          .where('dueDate', isLessThanOrEqualTo: endDate)
          .get();

      int totalPayments = 0;
      int onTimePayments = 0;
      int latePayments = 0;
      double totalRevenue = 0;
      double expectedRevenue = 0;
      double totalDelay = 0;

      for (var doc in paymentsSnapshot.docs) {
        final data = doc.data();
        final status = data['status'] as String?;
        final amount = (data['amount'] as num).toDouble();
        final dueDate = (data['dueDate'] as Timestamp).toDate();
        final paidDate = data['paidDate'] != null
            ? (data['paidDate'] as Timestamp).toDate()
            : null;

        totalPayments++;
        expectedRevenue += amount;

        if (status == 'paid') {
          totalRevenue += amount;
          
          if (paidDate != null) {
            final delay = paidDate.difference(dueDate).inDays;
            if (delay <= 0) {
              onTimePayments++;
            } else {
              latePayments++;
              totalDelay += delay;
            }
          }
        }
      }

      final averageCollectionTime = latePayments > 0 ? totalDelay / latePayments : 0.0;

      return PaymentAnalytics(
        totalPayments: totalPayments,
        onTimePayments: onTimePayments,
        latePayments: latePayments,
        averageCollectionTime: averageCollectionTime,
        totalRevenue: totalRevenue,
        expectedRevenue: expectedRevenue,
        periodStart: startDate,
        periodEnd: endDate,
      );
    } catch (e) {
      debugPrint('Error getting payment analytics: $e');
      return PaymentAnalytics(
        totalPayments: 0,
        onTimePayments: 0,
        latePayments: 0,
        averageCollectionTime: 0,
        totalRevenue: 0,
        expectedRevenue: 0,
        periodStart: startDate,
        periodEnd: endDate,
      );
    }
  }

  /// Get tenant behavior insights
  Future<List<TenantBehavior>> getTenantBehaviors(String ownerId) async {
    try {
      final tenantsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'tenant')
          .where('ownerId', isEqualTo: ownerId)
          .get();

      List<TenantBehavior> behaviors = [];

      for (var tenantDoc in tenantsSnapshot.docs) {
        final tenantData = tenantDoc.data();
        final tenantId = tenantDoc.id;
        final tenantName = tenantData['name'] as String? ?? 'Unknown';

        // Get all payments for this tenant
        final paymentsSnapshot = await _firestore
            .collection('payments')
            .where('tenantId', isEqualTo: tenantId)
            .get();

        int totalPayments = 0;
        int onTimePayments = 0;
        int latePayments = 0;
        double totalDelay = 0;
        double totalPaid = 0;
        DateTime? lastPaymentDate;
        String propertyAddress = '';

        for (var paymentDoc in paymentsSnapshot.docs) {
          final paymentData = paymentDoc.data();
          final status = paymentData['status'] as String?;
          final dueDate = (paymentData['dueDate'] as Timestamp).toDate();
          final paidDate = paymentData['paidDate'] != null
              ? (paymentData['paidDate'] as Timestamp).toDate()
              : null;

          totalPayments++;

          if (status == 'paid' && paidDate != null) {
            totalPaid += (paymentData['amount'] as num).toDouble();
            
            if (lastPaymentDate == null || paidDate.isAfter(lastPaymentDate)) {
              lastPaymentDate = paidDate;
            }

            final delay = paidDate.difference(dueDate).inDays;
            if (delay <= 0) {
              onTimePayments++;
            } else {
              latePayments++;
              totalDelay += delay;
            }
          }

          // Get property address
          if (propertyAddress.isEmpty) {
            final propertyId = paymentData['propertyId'] as String?;
            if (propertyId != null) {
              final propertyDoc = await _firestore
                  .collection('properties')
                  .doc(propertyId)
                  .get();
              if (propertyDoc.exists) {
                propertyAddress = propertyDoc.data()?['address'] as String? ?? 'Unknown';
              }
            }
          }
        }

        if (totalPayments > 0) {
          final averageDelay = latePayments > 0 ? totalDelay / latePayments : 0.0;
          final onTimeRate = (onTimePayments / totalPayments) * 100;

          String status;
          if (onTimeRate >= 90) {
            status = 'excellent';
          } else if (onTimeRate >= 70) {
            status = 'good';
          } else if (onTimeRate >= 50) {
            status = 'average';
          } else {
            status = 'poor';
          }

          behaviors.add(TenantBehavior(
            tenantId: tenantId,
            tenantName: tenantName,
            propertyAddress: propertyAddress,
            totalPayments: totalPayments,
            onTimePayments: onTimePayments,
            latePayments: latePayments,
            averageDelay: averageDelay,
            status: status,
            totalPaid: totalPaid,
            lastPaymentDate: lastPaymentDate ?? DateTime.now(),
          ));
        }
      }

      // Sort by status (excellent first)
      behaviors.sort((a, b) {
        final statusOrder = {'excellent': 0, 'good': 1, 'average': 2, 'poor': 3};
        return (statusOrder[a.status] ?? 4).compareTo(statusOrder[b.status] ?? 4);
      });

      return behaviors;
    } catch (e) {
      debugPrint('Error getting tenant behaviors: $e');
      return [];
    }
  }

  /// Get dashboard summary
  Future<DashboardSummary> getDashboardSummary(String ownerId) async {
    try {
      // Get all properties
      final propertiesSnapshot = await _firestore
          .collection('properties')
          .where('ownerId', isEqualTo: ownerId)
          .get();

      int totalProperties = propertiesSnapshot.docs.length;
      int occupiedProperties = 0;
      int vacantProperties = 0;

      for (var doc in propertiesSnapshot.docs) {
        final data = doc.data();
        final isOccupied = data['isOccupied'] as bool? ?? false;
        if (isOccupied) {
          occupiedProperties++;
        } else {
          vacantProperties++;
        }
      }

      // Get current month payments
      final now = DateTime.now();
      final currentMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      
      final monthPaymentsSnapshot = await _firestore
          .collection('payments')
          .where('ownerId', isEqualTo: ownerId)
          .where('month', isEqualTo: currentMonth)
          .get();

      double monthlyRevenue = 0;
      int pendingPayments = 0;
      double pendingAmount = 0;

      for (var doc in monthPaymentsSnapshot.docs) {
        final data = doc.data();
        final status = data['status'] as String?;
        final amount = (data['amount'] as num).toDouble();

        if (status == 'paid') {
          monthlyRevenue += amount;
        } else {
          pendingPayments++;
          pendingAmount += amount;
        }
      }

      // Get yearly revenue
      final yearStart = DateTime(now.year, 1, 1);
      final yearPaymentsSnapshot = await _firestore
          .collection('payments')
          .where('ownerId', isEqualTo: ownerId)
          .where('dueDate', isGreaterThanOrEqualTo: yearStart)
          .where('status', isEqualTo: 'paid')
          .get();

      double yearlyRevenue = 0;
      for (var doc in yearPaymentsSnapshot.docs) {
        yearlyRevenue += (doc.data()['amount'] as num).toDouble();
      }

      // Get total tenants
      final tenantsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'tenant')
          .where('ownerId', isEqualTo: ownerId)
          .get();

      return DashboardSummary(
        totalProperties: totalProperties,
        occupiedProperties: occupiedProperties,
        vacantProperties: vacantProperties,
        monthlyRevenue: monthlyRevenue,
        yearlyRevenue: yearlyRevenue,
        totalTenants: tenantsSnapshot.docs.length,
        pendingPayments: pendingPayments,
        pendingAmount: pendingAmount,
      );
    } catch (e) {
      debugPrint('Error getting dashboard summary: $e');
      return DashboardSummary(
        totalProperties: 0,
        occupiedProperties: 0,
        vacantProperties: 0,
        monthlyRevenue: 0,
        yearlyRevenue: 0,
        totalTenants: 0,
        pendingPayments: 0,
        pendingAmount: 0,
      );
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}
