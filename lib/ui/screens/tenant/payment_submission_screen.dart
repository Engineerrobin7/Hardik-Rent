import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../providers/app_provider.dart';
import '../../../data/models/models.dart';
import '../../theme/app_theme.dart';

class PaymentSubmissionScreen extends StatefulWidget {
  final RentRecord rent;

  const PaymentSubmissionScreen({super.key, required this.rent});

  @override
  State<PaymentSubmissionScreen> createState() => _PaymentSubmissionScreenState();
}

class _PaymentSubmissionScreenState extends State<PaymentSubmissionScreen> {
  final _amountController = TextEditingController();
  final _txnIdController = TextEditingController();
  DateTime _paymentDate = DateTime.now();
  late Razorpay _razorpay;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.rent.totalDue.toInt().toString();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    _finalizingPayment(response.paymentId!, 'Razorpay');
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() => _isProcessing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment Failed: ${response.message}'), backgroundColor: Colors.red),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
     ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('External Wallet: ${response.walletName}')),
    );
  }

  void _startRazorpay() {
    setState(() => _isProcessing = true);
    var options = {
      'key': 'rzp_test_YOUR_KEY', // Place your key here
      'amount': (widget.rent.totalDue * 100).toInt(),
      'name': 'Hardik Rent',
      'description': 'Rent for ${widget.rent.month}',
      'timeout': 300,
      'prefill': {
        'contact': '9876543210',
        'email': 'tenant@hardikrent.com'
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error: e');
      setState(() => _isProcessing = false);
    }
  }

  void _finalizingPayment(String txnId, String source) {
    final app = Provider.of<AppProvider>(context, listen: false);
    
    final payment = PaymentRecord(
      id: 'pay_${DateTime.now().millisecondsSinceEpoch}',
      rentId: widget.rent.id,
      tenantId: widget.rent.tenantId,
      amount: double.parse(_amountController.text),
      transactionId: txnId,
      paymentDate: _paymentDate,
      status: source == 'Razorpay' ? PaymentStatus.approved : PaymentStatus.pending,
    );

    app.submitPayment(payment);
    
    setState(() => _isProcessing = false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.verified_rounded, color: Colors.green, size: 64),
        title: Text(source == 'Razorpay' ? 'Payment Verified' : 'Submission Received'),
        content: Text(source == 'Razorpay' 
          ? 'Your payment has been settled instantly. Rent for ${widget.rent.month} is cleared.'
          : 'Payment details submitted successfully. Verification takes 12-24 hours.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('DONE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Portal'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Rent Summary Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)]),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.blue.withAlpha(51), blurRadius: 15, offset: const Offset(0, 10))],
              ),
              child: Column(
                children: [
                  Text(widget.rent.month, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('₹${widget.rent.totalDue.toInt()}', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
                  const Divider(color: Colors.white24, height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Penalty Included:', style: TextStyle(color: Colors.white70)),
                      Text('₹${widget.rent.penaltyApplied.toInt()}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Method 1: Instant Online
            SizedBox(
              width: double.infinity,
              height: 64,
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _startRazorpay,
                icon: const Icon(Icons.bolt_rounded),
                label: Text(_isProcessing ? 'PROCESSING...' : 'PAY ONLINE (RAZORPAY)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 5,
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            const Row(
              children: [
                Expanded(child: Divider()),
                Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('OR', style: TextStyle(color: Colors.grey))),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 24),
            
            // Method 2: Manual Upload
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Manual Bank/UPI Upload', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _txnIdController,
              decoration: const InputDecoration(
                labelText: 'UPI Reference / Transaction ID',
                prefixIcon: Icon(Icons.receipt_long_rounded),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Verify Amount', prefixIcon: Icon(Icons.currency_rupee_rounded)),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton(
                onPressed: () => _finalizingPayment(_txnIdController.text, 'Manual'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  side: const BorderSide(color: AppTheme.primaryColor),
                ),
                child: const Text('SUBMIT MANUAL PROOF'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
