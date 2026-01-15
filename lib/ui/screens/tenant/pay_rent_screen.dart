import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../services/payment_service.dart';
import '../../theme/app_theme.dart';

class PayRentScreen extends StatefulWidget {
  final String unitId;
  final double amount;

  const PayRentScreen({
    super.key, 
    required this.unitId, 
    required this.amount
  });

  @override
  State<PayRentScreen> createState() => _PayRentScreenState();
}

class _PayRentScreenState extends State<PayRentScreen> {
  final PaymentService _paymentService = PaymentService();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _paymentService.init(_handlePaymentSuccess, _handlePaymentError);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    setState(() => _isProcessing = true);
    final isVerified = await _paymentService.verifyPayment(response);
    
    if (mounted) {
      setState(() => _isProcessing = false);
      if (isVerified) {
        _showStatusDialog(true, 'Payment Successful!');
      } else {
        _showStatusDialog(false, 'Payment Verification Failed');
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment Failed: ${response.message}'), backgroundColor: Colors.red),
      );
    }
  }

  void _showStatusDialog(bool success, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              success ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded,
              color: success ? Colors.green : Colors.red,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(message, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                 Navigator.pop(context); // Close dialog
                 Navigator.pop(context); // Go back
              },
              child: const Text('Back to Home'),
            )
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _paymentService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rent Payment')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Amount to Pay', style: TextStyle(fontSize: 16, color: Colors.grey)),
            Text('₹${widget.amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: AppTheme.primaryColor)),
            const Divider(height: 48),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.home_work_rounded),
              title: const Text('Unit Information'),
              subtitle: Text(widget.unitId),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : () {
                   _paymentService.startPayment(
                     amount: widget.amount, 
                     unitId: widget.unitId, 
                     userEmail: 'tenant@hardik.com', // In real app, get from AuthProvider
                     userPhone: '9876543210'
                   );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isProcessing 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Pay with Razorpay', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
            const Center(child: Text('Secured by Razorpay Encryption', style: TextStyle(fontSize: 12, color: Colors.grey))),
          ],
        ),
      ),
    );
  }
}
