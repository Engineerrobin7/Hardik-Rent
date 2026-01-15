import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../../theme/app_theme.dart';
import 'package:intl/intl.dart';

class AgreementListScreen extends StatefulWidget {
  const AgreementListScreen({super.key});

  @override
  State<AgreementListScreen> createState() => _AgreementListScreenState();
}

class _AgreementListScreenState extends State<AgreementListScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _agreements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAgreements();
  }

  Future<void> _loadAgreements() async {
    setState(() => _isLoading = true);
    try {
      final agreements = await _apiService.getMyAgreements();
      setState(() {
        _agreements = agreements;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Rent Agreements'),
        elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _agreements.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _agreements.length,
              itemBuilder: (context, index) {
                final agreement = _agreements[index];
                return _buildAgreementCard(agreement);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('No agreements found', style: TextStyle(color: Colors.grey.shade500, fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildAgreementCard(dynamic agreement) {
    final startDate = DateTime.parse(agreement['start_date']);
    final endDate = DateTime.parse(agreement['end_date']);
    final bool isActive = agreement['status'] == 'active';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(7),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: isActive ? AppTheme.primaryColor.withAlpha(25) : Colors.grey.shade100,
              child: Row(
                children: [
                  Icon(Icons.verified_user_rounded, size: 18, color: isActive ? AppTheme.primaryColor : Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    isActive ? 'ACTIVE AGREEMENT' : 'EXPIRED',
                    style: TextStyle(
                      fontSize: 12, 
                      fontWeight: FontWeight.w900, 
                      color: isActive ? AppTheme.primaryColor : Colors.grey,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.more_horiz, color: Colors.grey),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(agreement['propertyName'] ?? 'Property Name', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Unit ${agreement['unit_number']}', style: TextStyle(color: Colors.grey.shade600)),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Divider(),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _dateInfo('Starts', DateFormat('dd MMM yyyy').format(startDate)),
                      const Icon(Icons.arrow_forward_rounded, color: Colors.grey, size: 16),
                      _dateInfo('Ends', DateFormat('dd MMM yyyy').format(endDate)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                         // Open PDF Viewer logic
                      },
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      label: const Text('View Agreement PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black87,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateInfo(String label, String date) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade400, fontWeight: FontWeight.w600)),
        Text(date, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
