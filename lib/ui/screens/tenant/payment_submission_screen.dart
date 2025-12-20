import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/app_provider.dart';
import '../../../data/models/models.dart';

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

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.rent.amount.toInt().toString();
  }

  void _submit() {
    if (_txnIdController.text.isEmpty || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    final app = Provider.of<AppProvider>(context, listen: false);
    
    final payment = PaymentRecord(
      id: 'pay_${DateTime.now().millisecondsSinceEpoch}',
      rentId: widget.rent.id,
      tenantId: widget.rent.tenantId,
      amount: double.parse(_amountController.text),
      transactionId: _txnIdController.text,
      paymentDate: _paymentDate,
      status: PaymentStatus.pending,
    );

    app.submitPayment(payment);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: const Text('Payment details submitted successfully. Keep the transaction ID for reference.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // back to dashboard
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Submit Payment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paying for ${widget.rent.month}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount Paid',
                prefixText: '₹ ',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _txnIdController,
              decoration: const InputDecoration(
                labelText: 'Transaction ID / Reference No.',
                helperText: 'Enter the ID from your UPI/Bank app',
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              title: const Text('Payment Date'),
              subtitle: Text('${_paymentDate.day}/${_paymentDate.month}/${_paymentDate.year}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _paymentDate,
                  firstDate: DateTime(2023),
                  lastDate: DateTime.now(),
                );
                if (date != null) setState(() => _paymentDate = date);
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This is a manual verification system. The owner will approve your payment once confirmed.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: _submit,
              child: const Text('Submit Payment'),
            ),
          ],
        ),
      ),
    );
  }
}
