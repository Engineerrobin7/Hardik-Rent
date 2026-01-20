import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../data/models/models.dart';

class ApiService {
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://10.0.2.2:3000/api',
  );
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

  Future<void> createUnit(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/properties/unit'),
      headers: await _getHeaders(),
      body: json.encode(data),
    );
    if (response.statusCode != 201) {
       throw Exception('Failed to create unit: ${response.body}');
    }
  }

  Future<void> updateUnitStatus(String propertyId, String unitId, String status) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/properties/unit-status'),
      headers: await _getHeaders(),
      body: json.encode({
        'propertyId': propertyId,
        'unitId': unitId,
        'status': status,
      }),
    );
    if (response.statusCode != 200) {
       throw Exception('Failed to update unit: ${response.body}');
    }
  }

  Future<String> createTenantUser({
    required String name,
    required String email,
    required String phone,
    String? propertyId,
    String? unitId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/create-tenant'),
      headers: await _getHeaders(),
      body: json.encode({
        'displayName': name,
        'email': email,
        'phoneNumber': phone,
        'propertyId': propertyId,
        'unitId': unitId,
      }),
    );

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      return data['uid'];
    } else {
       throw Exception('Failed to create tenant: ${response.body}');
    }
  }

  Future<void> toggleElectricity(String propertyId, String unitId, bool enabled) async {
    final response = await http.post(
      Uri.parse('$baseUrl/electricity/toggle'),
      headers: await _getHeaders(),
      body: json.encode({
        'propertyId': propertyId,
        'unitId': unitId,
        'enabled': enabled,
      }),
    );
    
    if (response.statusCode != 200) {
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? errorData['error'] ?? 'Failed to toggle electricity');
    }
  }

  Future<Map<String, dynamic>> getElectricityStatus(String propertyId, String unitId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/electricity/status/$propertyId/$unitId'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to fetch electricity status');
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
        'displayName': name,
        'role': role,
        'phoneNumber': phone ?? '',
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to sync user with backend');
    }
  }
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Identity Verification (Aadhaar KYC)
  // To use "Real" API, sign up at sandbox.co.in or surepass.io
  static const String kycApiKey = 'YOUR_REAL_KYC_API_KEY'; 
  
  Future<bool> verifyAadhaarReal(String aadhaarNumber) async {
    const providerUrl = 'https://api.sandbox.co.in/kyc/aadhaar/okyc/otp/request'; // Example Sandbox.co.in endpoint
    
    try {
      final response = await http.post(
        Uri.parse(providerUrl),
        headers: {
          'Authorization': kycApiKey,
          'Content-Type': 'application/json',
          'x-api-key': kycApiKey,
          'x-api-version': '1.0'
        },
        body: json.encode({
          'aadhaar_number': aadhaarNumber,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Successful API call logic
        return data['status'] == 'success' || data['code'] == 200;
      } else {
        debugPrint('KYC API Error: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('KYC Connection Error: $e');
      return false;
    }
  }
}
