// Sprint 1: Analytics Models
// File: lib/data/models/analytics_models.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// Revenue data for charts
class RevenueData {
  final String month;
  final double amount;
  final int propertyCount;
  final int paidCount;
  final int pendingCount;

  RevenueData({
    required this.month,
    required this.amount,
    required this.propertyCount,
    required this.paidCount,
    required this.pendingCount,
  });

  Map<String, dynamic> toJson() => {
        'month': month,
        'amount': amount,
        'propertyCount': propertyCount,
        'paidCount': paidCount,
        'pendingCount': pendingCount,
      };

  factory RevenueData.fromJson(Map<String, dynamic> json) => RevenueData(
        month: json['month'] as String,
        amount: (json['amount'] as num).toDouble(),
        propertyCount: json['propertyCount'] as int,
        paidCount: json['paidCount'] as int,
        pendingCount: json['pendingCount'] as int,
      );
}

/// Payment analytics summary
class PaymentAnalytics {
  final int totalPayments;
  final int onTimePayments;
  final int latePayments;
  final double averageCollectionTime; // in days
  final double totalRevenue;
  final double expectedRevenue;
  final DateTime periodStart;
  final DateTime periodEnd;

  PaymentAnalytics({
    required this.totalPayments,
    required this.onTimePayments,
    required this.latePayments,
    required this.averageCollectionTime,
    required this.totalRevenue,
    required this.expectedRevenue,
    required this.periodStart,
    required this.periodEnd,
  });

  double get onTimePercentage =>
      totalPayments > 0 ? (onTimePayments / totalPayments) * 100 : 0;

  double get latePercentage =>
      totalPayments > 0 ? (latePayments / totalPayments) * 100 : 0;

  double get collectionRate =>
      expectedRevenue > 0 ? (totalRevenue / expectedRevenue) * 100 : 0;

  Map<String, dynamic> toJson() => {
        'totalPayments': totalPayments,
        'onTimePayments': onTimePayments,
        'latePayments': latePayments,
        'averageCollectionTime': averageCollectionTime,
        'totalRevenue': totalRevenue,
        'expectedRevenue': expectedRevenue,
        'periodStart': periodStart.toIso8601String(),
        'periodEnd': periodEnd.toIso8601String(),
      };

  factory PaymentAnalytics.fromJson(Map<String, dynamic> json) =>
      PaymentAnalytics(
        totalPayments: json['totalPayments'] as int,
        onTimePayments: json['onTimePayments'] as int,
        latePayments: json['latePayments'] as int,
        averageCollectionTime: (json['averageCollectionTime'] as num).toDouble(),
        totalRevenue: (json['totalRevenue'] as num).toDouble(),
        expectedRevenue: (json['expectedRevenue'] as num).toDouble(),
        periodStart: DateTime.parse(json['periodStart'] as String),
        periodEnd: DateTime.parse(json['periodEnd'] as String),
      );
}

/// Tenant payment behavior tracking
class TenantBehavior {
  final String tenantId;
  final String tenantName;
  final String propertyAddress;
  final int totalPayments;
  final int onTimePayments;
  final int latePayments;
  final double averageDelay; // in days
  final String status; // 'excellent', 'good', 'average', 'poor'
  final double totalPaid;
  final DateTime lastPaymentDate;

  TenantBehavior({
    required this.tenantId,
    required this.tenantName,
    required this.propertyAddress,
    required this.totalPayments,
    required this.onTimePayments,
    required this.latePayments,
    required this.averageDelay,
    required this.status,
    required this.totalPaid,
    required this.lastPaymentDate,
  });

  double get onTimeRate =>
      totalPayments > 0 ? (onTimePayments / totalPayments) * 100 : 0;

  String get statusEmoji {
    switch (status) {
      case 'excellent':
        return '🌟';
      case 'good':
        return '✅';
      case 'average':
        return '⚠️';
      case 'poor':
        return '❌';
      default:
        return '❓';
    }
  }

  Map<String, dynamic> toJson() => {
        'tenantId': tenantId,
        'tenantName': tenantName,
        'propertyAddress': propertyAddress,
        'totalPayments': totalPayments,
        'onTimePayments': onTimePayments,
        'latePayments': latePayments,
        'averageDelay': averageDelay,
        'status': status,
        'totalPaid': totalPaid,
        'lastPaymentDate': lastPaymentDate.toIso8601String(),
      };

  factory TenantBehavior.fromJson(Map<String, dynamic> json) => TenantBehavior(
        tenantId: json['tenantId'] as String,
        tenantName: json['tenantName'] as String,
        propertyAddress: json['propertyAddress'] as String,
        totalPayments: json['totalPayments'] as int,
        onTimePayments: json['onTimePayments'] as int,
        latePayments: json['latePayments'] as int,
        averageDelay: (json['averageDelay'] as num).toDouble(),
        status: json['status'] as String,
        totalPaid: (json['totalPaid'] as num).toDouble(),
        lastPaymentDate: DateTime.parse(json['lastPaymentDate'] as String),
      );
}

/// Property performance metrics
class PropertyMetrics {
  final String propertyId;
  final String propertyAddress;
  final double totalRevenue;
  final double totalExpenses;
  final double netIncome;
  final int occupancyDays;
  final int totalDays;
  final double occupancyRate;

  PropertyMetrics({
    required this.propertyId,
    required this.propertyAddress,
    required this.totalRevenue,
    required this.totalExpenses,
    required this.netIncome,
    required this.occupancyDays,
    required this.totalDays,
    required this.occupancyRate,
  });

  Map<String, dynamic> toJson() => {
        'propertyId': propertyId,
        'propertyAddress': propertyAddress,
        'totalRevenue': totalRevenue,
        'totalExpenses': totalExpenses,
        'netIncome': netIncome,
        'occupancyDays': occupancyDays,
        'totalDays': totalDays,
        'occupancyRate': occupancyRate,
      };

  factory PropertyMetrics.fromJson(Map<String, dynamic> json) =>
      PropertyMetrics(
        propertyId: json['propertyId'] as String,
        propertyAddress: json['propertyAddress'] as String,
        totalRevenue: (json['totalRevenue'] as num).toDouble(),
        totalExpenses: (json['totalExpenses'] as num).toDouble(),
        netIncome: (json['netIncome'] as num).toDouble(),
        occupancyDays: json['occupancyDays'] as int,
        totalDays: json['totalDays'] as int,
        occupancyRate: (json['occupancyRate'] as num).toDouble(),
      );
}

/// Dashboard summary
class DashboardSummary {
  final int totalProperties;
  final int occupiedProperties;
  final int vacantProperties;
  final double monthlyRevenue;
  final double yearlyRevenue;
  final int totalTenants;
  final int pendingPayments;
  final double pendingAmount;

  DashboardSummary({
    required this.totalProperties,
    required this.occupiedProperties,
    required this.vacantProperties,
    required this.monthlyRevenue,
    required this.yearlyRevenue,
    required this.totalTenants,
    required this.pendingPayments,
    required this.pendingAmount,
  });

  double get occupancyRate =>
      totalProperties > 0 ? (occupiedProperties / totalProperties) * 100 : 0;

  Map<String, dynamic> toJson() => {
        'totalProperties': totalProperties,
        'occupiedProperties': occupiedProperties,
        'vacantProperties': vacantProperties,
        'monthlyRevenue': monthlyRevenue,
        'yearlyRevenue': yearlyRevenue,
        'totalTenants': totalTenants,
        'pendingPayments': pendingPayments,
        'pendingAmount': pendingAmount,
      };

  factory DashboardSummary.fromJson(Map<String, dynamic> json) =>
      DashboardSummary(
        totalProperties: json['totalProperties'] as int,
        occupiedProperties: json['occupiedProperties'] as int,
        vacantProperties: json['vacantProperties'] as int,
        monthlyRevenue: (json['monthlyRevenue'] as num).toDouble(),
        yearlyRevenue: (json['yearlyRevenue'] as num).toDouble(),
        totalTenants: json['totalTenants'] as int,
        pendingPayments: json['pendingPayments'] as int,
        pendingAmount: (json['pendingAmount'] as num).toDouble(),
      );
}
