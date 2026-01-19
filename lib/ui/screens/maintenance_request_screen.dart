// Sprint 3: Maintenance Request Screen
// File: lib/ui/screens/tenant/maintenance_request_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';


import '../../../data/models/maintenance_models.dart';
import '../../../services/firebase_service.dart';

class MaintenanceRequestScreen extends StatefulWidget {
  final String tenantId;
  final String tenantName;
  final String propertyId;
  final String propertyAddress;
  final String ownerId;

  const MaintenanceRequestScreen({
    Key? key,
    required this.tenantId,
    required this.tenantName,
    required this.propertyId,
    required this.propertyAddress,
    required this.ownerId,
  }) : super(key: key);

  @override
  State<MaintenanceRequestScreen> createState() => _MaintenanceRequestScreenState();
}

class _MaintenanceRequestScreenState extends State<MaintenanceRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  
  TicketPriority _priority = TicketPriority.medium;
  final List<XFile> _selectedImages = [];
  bool _isSubmitting = false;
  
  final FirebaseService _storageService = FirebaseService();

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images);
      });
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      // 1. Upload images to Firebase Storage
      List<String> photoUrls = [];
      for (var image in _selectedImages) {
        final path = 'maintenance/${DateTime.now().millisecondsSinceEpoch}_${image.name}';
        final url = await _storageService.uploadFile(path, File(image.path));
        photoUrls.add(url);
      }

      // 2. Submit to Firestore
      String newTicketId = _storageService.getNewMaintenanceTicketId(); // Generate a new ID from Firebase

      final newTicket = MaintenanceTicket(
        id: newTicketId,
        propertyId: widget.propertyId,
        propertyAddress: widget.propertyAddress,
        tenantId: widget.tenantId,
        tenantName: widget.tenantName,
        ownerId: widget.ownerId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        priority: _priority,
        status: TicketStatus.open, // Default status
        photoUrls: photoUrls,
        createdAt: DateTime.now(),
      );

      await _storageService.addMaintenanceTicket(newTicket);

      // 3. Notify Owner (simulated)
      // await NotificationService.sendNotification(...)

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Maintenance request submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Maintenance Request'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Property Info Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50], // Hardcoded color
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200] ?? Colors.blue), // Hardcoded color
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Requesting for Property:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.propertyAddress,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Title Input
              const Text(
                'Issue Title',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'e.g., Leaking Tap in Kitchen',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter a title' : null,
              ),

              const SizedBox(height: 20),

              // Priority Selector
              const Text(
                'Priority Level',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<TicketPriority>(
                    value: _priority,
                    isExpanded: true,
                    items: TicketPriority.values.map((priority) {
                      Color color;
                      switch (priority) {
                        case TicketPriority.low: color = Colors.green; break;
                        case TicketPriority.medium: color = Colors.blue; break;
                        case TicketPriority.high: color = Colors.orange; break;
                        case TicketPriority.urgent: color = Colors.red; break;
                      }
                      
                      return DropdownMenuItem(
                        value: priority,
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                             // Capitalize first letter logic
                            Text(priority.name[0].toUpperCase() + priority.name.substring(1)),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _priority = val);
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Description Input
              const Text(
                'Detailed Description',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Please describe the issue in detail...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter a description' : null,
              ),

              const SizedBox(height: 20),

              // Photos Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Photos',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  TextButton.icon(
                    onPressed: _pickImages,
                    icon: const Icon(Icons.add_a_photo),
                    label: const Text('Add Photos'),
                  ),
                ],
              ),
              
              if (_selectedImages.isNotEmpty)
                Container(
                  height: 100,
                  margin: const EdgeInsets.only(top: 8),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedImages.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          Container(
                            width: 100,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: FileImage(File(_selectedImages[index].path)),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 8,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedImages.removeAt(index);
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700], // Hardcoded color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Submit Request',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
