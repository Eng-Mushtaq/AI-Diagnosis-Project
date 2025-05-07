import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../controllers/doctor_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/doctor_verification_controller.dart';
import '../../constants/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_app_bar.dart';

class DoctorVerificationScreen extends StatefulWidget {
  const DoctorVerificationScreen({Key? key}) : super(key: key);

  @override
  State<DoctorVerificationScreen> createState() =>
      _DoctorVerificationScreenState();
}

class _DoctorVerificationScreenState extends State<DoctorVerificationScreen> {
  final DoctorController _doctorController = Get.find<DoctorController>();
  final AuthController _authController = Get.find<AuthController>();
  final DoctorVerificationController _verificationController =
      Get.find<DoctorVerificationController>();

  final ImagePicker _picker = ImagePicker();
  final RxString _selectedDocumentType = ''.obs;
  final Rx<File?> _selectedFile = Rx<File?>(null);
  final RxBool _isUploading = false.obs;

  @override
  void initState() {
    super.initState();
    _loadDocuments();

    // Set initial document type
    if (_verificationController.documentTypes.isNotEmpty) {
      _selectedDocumentType.value = _verificationController.documentTypes.first;
    }
  }

  Future<void> _loadDocuments() async {
    if (_doctorController.selectedDoctor != null) {
      await _verificationController.getVerificationDocuments(
        _doctorController.selectedDoctor!.id,
      );
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1800,
        maxHeight: 1800,
      );

      if (pickedFile != null) {
        _selectedFile.value = File(pickedFile.path);
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick image: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _pickDocument() async {
    try {
      // TODO: Implement document picker for PDF files
      // For now, we'll just use image picker
      await _pickImage(ImageSource.gallery);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick document: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _uploadDocument() async {
    if (_selectedFile.value == null) {
      Get.snackbar(
        'Error',
        'Please select a file to upload',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (_selectedDocumentType.value.isEmpty) {
      Get.snackbar(
        'Error',
        'Please select a document type',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    _isUploading.value = true;

    try {
      final success = await _verificationController.uploadVerificationDocument(
        _selectedFile.value!.path,
        _doctorController.selectedDoctor!.id,
        _selectedDocumentType.value,
      );

      if (success) {
        _selectedFile.value = null;
        Get.snackbar(
          'Success',
          'Document uploaded successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Error',
          'Failed to upload document: ${_verificationController.errorMessage}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } finally {
      _isUploading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Verification Documents',
        showBackButton: true,
      ),
      body: Obx(() {
        if (_doctorController.selectedDoctor == null) {
          return const Center(child: Text('No doctor selected'));
        }

        final verificationStatus =
            _doctorController.selectedDoctor!.verificationStatus ?? 'pending';

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Verification status card
              _buildVerificationStatusCard(verificationStatus),
              const SizedBox(height: 24),

              // Upload new document section
              const Text(
                'Upload New Document',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                ),
              ),
              const SizedBox(height: 16),

              // Document type dropdown
              DropdownButtonFormField<String>(
                value:
                    _selectedDocumentType.value.isNotEmpty
                        ? _selectedDocumentType.value
                        : null,
                hint: const Text('Select Document Type'),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                items:
                    _verificationController.documentTypes
                        .map(
                          (type) =>
                              DropdownMenuItem(value: type, child: Text(type)),
                        )
                        .toList(),
                onChanged: (value) {
                  if (value != null) {
                    _selectedDocumentType.value = value;
                  }
                },
              ),
              const SizedBox(height: 16),

              // File selection
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _selectedFile.value != null
                            ? _selectedFile.value!.path.split('/').last
                            : 'No file selected',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _pickDocument,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Browse'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Upload button
              CustomButton(
                text: 'Upload Document',
                onPressed: _isUploading.value ? () {} : () => _uploadDocument(),
                isLoading: _isUploading.value,
                width: double.infinity,
              ),
              const SizedBox(height: 24),

              // Uploaded documents section
              const Text(
                'Uploaded Documents',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                ),
              ),
              const SizedBox(height: 16),

              // Documents list
              Expanded(
                child:
                    _verificationController.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _verificationController.documents.isEmpty
                        ? const Center(
                          child: Text(
                            'No documents uploaded yet',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                        : ListView.builder(
                          itemCount: _verificationController.documents.length,
                          itemBuilder: (context, index) {
                            final document =
                                _verificationController.documents[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                title: Text(document['documentType']),
                                subtitle: Text(
                                  'Uploaded on: ${document['uploadedAt'].toString().split(' ')[0]}',
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.visibility,
                                    color: AppColors.primaryColor,
                                  ),
                                  onPressed: () {
                                    // Open document in browser
                                    // TODO: Implement document viewer
                                  },
                                ),
                              ),
                            );
                          },
                        ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildVerificationStatusCard(String status) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status) {
      case 'verified':
        statusColor = Colors.green;
        statusIcon = Icons.verified;
        statusText = 'Your account is verified';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Your verification was rejected';
        break;
      case 'pending':
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        statusText = 'Your verification is pending';
        break;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withOpacity(0.5), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  if (status == 'rejected')
                    FutureBuilder<String?>(
                      future: _verificationController.getRejectionReason(
                        _doctorController.selectedDoctor!.id,
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Text('Loading reason...');
                        }

                        final reason = snapshot.data;
                        return Text(
                          reason != null && reason.isNotEmpty
                              ? 'Reason: $reason'
                              : 'No reason provided',
                          style: const TextStyle(color: Colors.red),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
