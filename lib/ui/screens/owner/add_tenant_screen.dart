import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../providers/app_provider.dart';
import '../../../data/models/models.dart';
import '../../theme/app_theme.dart';
import '../../../services/firebase_service.dart';

class AddTenantScreen extends StatefulWidget {
  const AddTenantScreen({super.key});

  @override
  State<AddTenantScreen> createState() => _AddTenantScreenState();
}

class _AddTenantScreenState extends State<AddTenantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _aadhaarController = TextEditingController();
  
  String? _selectedFlatId;
  File? _passportPhoto;
  File? _aadhaarPhoto;
  bool _isAadhaarVerified = false;
  bool _isSaving = false;
  int _currentStep = 0;

  final ImagePicker _picker = ImagePicker();
  final FirebaseService _firebaseService = FirebaseService();

  Future<void> _pickImage(bool isPassport) async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );
    if (image != null) {
      setState(() {
        if (isPassport) {
          _passportPhoto = File(image.path);
        } else {
          _aadhaarPhoto = File(image.path);
        }
      });
    }
  }

  Future<void> _verifyAadhaar() async {
    if (_aadhaarController.text.length != 12) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 12-digit Aadhaar number')),
      );
      return;
    }

    setState(() => _isSaving = true);
    
    // CALLING REAL API SERVICE
    final apiService = ApiService();
    final bool success = await apiService.verifyAadhaarReal(_aadhaarController.text);
    
    setState(() {
      _isSaving = false;
      _isAadhaarVerified = success;
    });

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aadhaar Verified via Real-time Secure Bridge'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification Failed. Please check the number or API credits.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveTenant() async {
    if (!_formKey.currentState!.validate() || _selectedFlatId == null || _passportPhoto == null || !_isAadhaarVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all verification steps including Photo & Aadhaar')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final app = Provider.of<AppProvider>(context, listen: false);
    
    try {
      // 1. Upload Photos
      final photoUrl = await _firebaseService.uploadFile(
        'tenants/photos/${DateTime.now().millisecondsSinceEpoch}.jpg', 
        _passportPhoto!
      );
      final idProofUrl = _aadhaarPhoto != null 
        ? await _firebaseService.uploadFile(
            'tenants/id_proofs/${DateTime.now().millisecondsSinceEpoch}.jpg', 
            _aadhaarPhoto!
          )
        : null;

      // 2. Create Tenant Object
      final newTenant = User(
        id: 'tenant_${DateTime.now().millisecondsSinceEpoch}',
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        role: UserRole.tenant,
        phoneNumber: _phoneController.text.trim(),
        photoUrl: photoUrl,
        idProofUrl: idProofUrl,
        aadhaarNumber: _aadhaarController.text.trim(),
        joinedDate: DateTime.now(),
      );

      final selectedFlat = app.flats.firstWhere((f) => f.id == _selectedFlatId);
      
      await app.addTenant(
        tenant: newTenant,
        propertyId: selectedFlat.apartmentId,
        unitId: _selectedFlatId!,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tenant Verified & Added Successfully'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Onboarding Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableFlats = Provider.of<AppProvider>(context).flats.where((f) => !f.isOccupied).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tenant KYC Verification'),
        elevation: 0,
      ),
      body: Stepper(
        type: StepperType.vertical,
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep < 2) {
            setState(() => _currentStep += 1);
          } else {
            _saveTenant();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep -= 1);
          }
        },
        steps: [
          Step(
            title: const Text('Basic Information'),
            subtitle: const Text('Contact & Unit Assignment'),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            content: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Full Name as per Aadhaar', prefixIcon: Icon(Icons.person)),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: 'Mobile Number', prefixIcon: Icon(Icons.phone)),
                    keyboardType: TextInputType.phone,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Assign Flat', prefixIcon: Icon(Icons.apartment)),
                    items: availableFlats.map((f) => DropdownMenuItem(value: f.id, child: Text('Flat ${f.flatNumber}'))).toList(),
                    onChanged: (val) => setState(() => _selectedFlatId = val),
                    validator: (v) => v == null ? 'Please select a flat' : null,
                  ),
                ],
              ),
            ),
          ),
          Step(
            title: const Text('Digital Presence'),
            subtitle: const Text('Passport Photo Upload'),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
            content: Column(
              children: [
                GestureDetector(
                  onTap: () => _pickImage(true),
                  child: Container(
                    height: 150,
                    width: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: _passportPhoto == null 
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [Icon(Icons.camera_alt, size: 40), Text('Take Photo')],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(_passportPhoto!, fit: BoxFit.cover),
                        ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Compulsory passport size photo for agreement', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Step(
            title: const Text('Identity Verification'),
            subtitle: const Text('UIDAI Aadhaar Authentication'),
            isActive: _currentStep >= 2,
            state: _isAadhaarVerified ? StepState.complete : StepState.indexed,
            content: Column(
              children: [
                TextFormField(
                  controller: _aadhaarController,
                  decoration: InputDecoration(
                    labelText: '12-Digit Aadhaar Number',
                    prefixIcon: const Icon(Icons.verified_user),
                    suffixIcon: _isAadhaarVerified ? const Icon(Icons.check_circle, color: Colors.green) : null,
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 12,
                  enabled: !_isAadhaarVerified,
                ),
                const SizedBox(height: 16),
                if (!_isAadhaarVerified)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _verifyAadhaar,
                      icon: const Icon(Icons.security),
                      label: Text(_isSaving ? 'Verifying with UIDAI...' : 'Verify via OTP / Biometric'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondaryColor),
                    ),
                  ),
                const SizedBox(height: 20),
                const Text('Note: Data is encrypted and authenticated via UIDAI secure protocols.', style: TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
