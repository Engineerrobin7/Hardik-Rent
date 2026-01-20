import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/models/models.dart';
import '../../theme/app_theme.dart';

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  String _verificationId = '';
  bool _codeSent = false;
  bool _isVerifying = false;

  void _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return;

    setState(() => _isVerifying = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    await auth.verifyPhone(
      phoneNumber: phone,
      onCodeSent: (verificationId) {
        setState(() {
          _verificationId = verificationId;
          _codeSent = true;
          _isVerifying = false;
        });
      },
      onError: (error) {
        setState(() => _isVerifying = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: AppTheme.errorColor),
        );
      },
    );
  }

  void _verifyOtp() async {
    final smsCode = _otpController.text.trim();
    if (smsCode.isEmpty) return;

    setState(() => _isVerifying = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.signInWithPhoneNumber(_verificationId, smsCode);

    if (success && mounted) {
      if (auth.currentUser?.role == UserRole.owner) {
        Navigator.pushReplacementNamed(context, '/owner-dashboard');
      } else {
        Navigator.pushReplacementNamed(context, '/tenant-dashboard');
      }
    } else if (mounted) {
      setState(() => _isVerifying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid OTP'), backgroundColor: AppTheme.errorColor),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Phone Authentication')),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _codeSent ? 'Enter OTP' : 'Login with\nPhone Number',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, height: 1.1),
            ),
            const SizedBox(height: 12),
            Text(
              _codeSent 
                ? 'We sent a code to ${_phoneController.text}'
                : 'Enter your phone number with country code (e.g. +91)',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
            ),
            const SizedBox(height: 48),
            if (!_codeSent)
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone),
                  hintText: '+91 00000 00000',
                ),
              )
            else
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: '6-Digit OTP',
                  prefixIcon: Icon(Icons.lock_clock),
                ),
              ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isVerifying ? null : (_codeSent ? _verifyOtp : _sendOtp),
              child: _isVerifying 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(_codeSent ? 'Verify OTP' : 'Send Code'),
            ),
            if (_codeSent)
              TextButton(
                onPressed: () => setState(() => _codeSent = false),
                child: const Text('Change Phone Number'),
              ),
          ],
        ),
      ),
    );
  }
}
