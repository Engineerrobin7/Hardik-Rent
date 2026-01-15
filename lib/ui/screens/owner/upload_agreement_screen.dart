import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../../theme/app_theme.dart';
import 'package:intl/intl.dart';

class UploadAgreementScreen extends StatefulWidget {
  final String unitId;
  final String tenantId;

  const UploadAgreementScreen({
    super.key, 
    required this.unitId, 
    required this.tenantId
  });

  @override
  State<UploadAgreementScreen> createState() => _UploadAgreementScreenState();
}

class _UploadAgreementScreenState extends State<UploadAgreementScreen> {
  final ApiService _apiService = ApiService();
  DateTime? _startDate;
  DateTime? _endDate;
  final _pdfUrlController = TextEditingController();
  bool _isUploading = false;

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _handleUpload() async {
    if (_startDate == null || _endDate == null || _pdfUrlController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    setState(() => _isUploading = true);
    try {
      await _apiService.uploadAgreement({
        'unitId': widget.unitId,
        'tenantId': widget.tenantId,
        'pdfUrl': _pdfUrlController.text,
        'startDate': _startDate!.toIso8601String().substring(0, 10),
        'endDate': _endDate!.toIso8601String().substring(0, 10),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Agreement Uploaded!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Digital Agreement')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Setup New Agreement', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Attach a digital contract for Unit ${widget.unitId}', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),
            
            _datePickerField('Start Date', _startDate, () => _selectDate(context, true)),
            const SizedBox(height: 16),
            _datePickerField('End Date', _endDate, () => _selectDate(context, false)),
            
            const SizedBox(height: 32),
            TextField(
              controller: _pdfUrlController,
              decoration: const InputDecoration(
                labelText: 'PDF Document URL',
                hintText: 'Link to stored PDF in Firebase',
                prefixIcon: Icon(Icons.link_rounded),
              ),
            ),
            const SizedBox(height: 48),
            
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _handleUpload,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isUploading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Save & Issue Agreement', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _datePickerField(String label, DateTime? date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(
                  date != null ? DateFormat('dd MMM yyyy').format(date) : 'Choose Date',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Icon(Icons.calendar_today_rounded, color: AppTheme.primaryColor),
          ],
        ),
      ),
    );
  }
}
