import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'api_service.dart';
import 'package:flutter/material.dart';

class PaymentService {
  late Razorpay _razorpay;
  final ApiService _apiService = ApiService();
  final String _razorpayKey = 'rzp_test_placeholder'; // Replace with real key

  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  void init(Function(PaymentSuccessResponse) onSuccess, Function(PaymentFailureResponse) onFailure) {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, onSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, onFailure);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    // Optional: Handle external wallets like Paytm
  }

  Future<void> startPayment({
    required double amount,
    required String unitId,
    required String userEmail,
    required String userPhone,
  }) async {
    try {
      // 1. Create order in backend
      final orderData = await _apiService.createRazorpayOrder(
        amount: amount,
        unitId: unitId,
      );

      // 2. Setup options
      var options = {
        'key': _razorpayKey,
        'amount': orderData['amount'],
        'name': 'Hardik Rent',
        'order_id': orderData['id'], // Generate in backend
        'description': 'Rent Payment for $unitId',
        'timeout': 60, // in seconds
        'prefill': {
          'contact': userPhone,
          'email': userEmail,
        }
      };

      // 3. Open Razorpay Checkout
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Payment Start Error: $e');
    }
  }

  Future<bool> verifyPayment(PaymentSuccessResponse response) async {
    return await _apiService.verifyRazorpayPayment(
      orderId: response.orderId!,
      paymentId: response.paymentId!,
      signature: response.signature!,
    );
  }

  void dispose() {
    _razorpay.clear();
  }
}
