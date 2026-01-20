import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('Help & Support'),
            backgroundColor: AppTheme.secondaryColor,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Frequently Asked Questions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildFaq(
                    'How to pay rent?',
                    'Navigate to your dashboard, click on "PAY NOW" on the current due card, and upload your payment proof.',
                  ),
                  _buildFaq(
                    'How is electricity billed?',
                    'Electricity bills are fetched directly from the state board and updated in your rent records monthly.',
                  ),
                  _buildFaq(
                    'Can I raise maintenance requests?',
                    'Yes, soon you will be able to raise tickets directly from the app for repairs and maintenance.',
                  ),
                  const SizedBox(height: 32),
                  const Text('Contact Us', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10)],
                    ),
                    child: Column(
                      children: [
                        _buildContactRow(Icons.email_outlined, 'support@hardikrent.com'),
                        const Divider(height: 32),
                        _buildContactRow(Icons.phone_outlined, '+91 98765 43210'),
                        const Divider(height: 32),
                        _buildContactRow(Icons.location_on_outlined, 'New Delhi, India'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaq(String question, String answer) {
    return ExpansionTile(
      title: Text(question, style: const TextStyle(fontWeight: FontWeight.bold)),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(answer, style: TextStyle(color: Colors.grey.shade600)),
        ),
      ],
    );
  }

  Widget _buildContactRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.secondaryColor),
        const SizedBox(width: 16),
        Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
