import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart' as auth;

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:3000/api'; // Change for production
  final auth.FirebaseAuth _firebaseAuth = auth.FirebaseAuth.instance;

  // Singleton
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _firebaseAuth.currentUser?.getIdToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Properties & Units
  Future<List<dynamic>> getProperties() async {
    final response = await http.get(Uri.parse('$baseUrl/properties'), headers: await _getHeaders());
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to load properties');
  }

  Future<void> createProperty(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/properties'),
      headers: await _getHeaders(),
      body: json.encode(data),
    );
    if (response.statusCode != 201) {
       throw Exception('Failed to create property: ${response.body}');
    }
  }

  Future<void> updateUnitStatus(String unitId, String status, {String? tenantId}) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/properties/unit-status'),
      headers: await _getHeaders(),
      body: json.encode({
        'unitId': unitId,
        'status': status,
        'tenantId': tenantId,
      }),
    );
    if (response.statusCode != 200) {
       throw Exception('Failed to update unit: ${response.body}');
    }
  }

  // Analytics
  Future<Map<String, dynamic>> getOwnerAnalytics() async {
     // This would call a new analytics endpoint
     final response = await http.get(Uri.parse('$baseUrl/analytics/summary'), headers: await _getHeaders());
     if (response.statusCode == 200) {
       return json.decode(response.body);
     }
     return {'totalRevenue': 0, 'occupancyRate': 0};
  }

  // Payments
  Future<Map<String, dynamic>> createRazorpayOrder({required double amount, required String unitId}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/payments/create-order'),
      headers: await _getHeaders(),
      body: json.encode({
        'amount': amount,
        'unitId': unitId,
        'receipt': 'rcpt_${DateTime.now().millisecondsSinceEpoch}',
      }),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to create payment order');
  }

  Future<bool> verifyRazorpayPayment({
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/payments/verify'),
      headers: await _getHeaders(),
      body: json.encode({
        'razorpay_order_id': orderId,
        'razorpay_payment_id': paymentId,
        'razorpay_signature': signature,
      }),
    );
    return response.statusCode == 200;
  }

  // Agreements
  Future<void> uploadAgreement(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/agreements'),
      headers: await _getHeaders(),
      body: json.encode(data),
    );
    if (response.statusCode != 201) {
       throw Exception('Failed to upload agreement');
    }
  }

  // Maintenance
  Future<void> createMaintenanceTicket(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/maintenance'),
      headers: await _getHeaders(),
      body: json.encode(data),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to create maintenance ticket: ${response.body}');
    }
  }

  Future<List<dynamic>> getMyAgreements() async {
    final response = await http.get(
      Uri.parse('$baseUrl/agreements/my-agreements'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to fetch agreements');
  }

  // Auth Sync
  Future<void> syncUserWithBackend({
    required String email,
    required String name,
    required String role,
    String? phone,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/sync'),
      headers: await _getHeaders(),
      body: json.encode({
        'email': email,
        'name': name,
        'role': role,
        'phone': phone,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to sync user with backend');
    }
  }
}
