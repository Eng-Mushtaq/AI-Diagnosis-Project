import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../constants/app_colors.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/navigation_controller.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/custom_loading_indicator.dart';
import '../../widgets/bottom_nav_bar.dart';

class LabResultsScreen extends StatefulWidget {
  const LabResultsScreen({Key? key}) : super(key: key);

  @override
  State<LabResultsScreen> createState() => _LabResultsScreenState();
}

class _LabResultsScreenState extends State<LabResultsScreen> with SingleTickerProviderStateMixin {
  final AuthController _authController = Get.find<AuthController>();
  final PatientNavigationController _navigationController = Get.find<PatientNavigationController>();
  
  late TabController _tabController;
  final RxBool _isLoading = false.obs;
  final RxList<LabResult> _labResults = <LabResult>[].obs;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadLabResults();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  // Load lab results
  Future<void> _loadLabResults() async {
    _isLoading.value = true;
    
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      
      // Mock data
      final List<LabResult> mockResults = [
        LabResult(
          id: '1',
          title: 'Complete Blood Count (CBC)',
          date: DateTime.now().subtract(const Duration(days: 5)),
          doctor: 'Dr. Mohammed Al-Saud',
          status: LabResultStatus.normal,
          items: [
            LabResultItem(
              name: 'Hemoglobin',
              value: '14.2',
              unit: 'g/dL',
              referenceRange: '13.5-17.5',
              status: LabResultStatus.normal,
            ),
            LabResultItem(
              name: 'White Blood Cells',
              value: '7.5',
              unit: 'x10^9/L',
              referenceRange: '4.5-11.0',
              status: LabResultStatus.normal,
            ),
            LabResultItem(
              name: 'Platelets',
              value: '250',
              unit: 'x10^9/L',
              referenceRange: '150-450',
              status: LabResultStatus.normal,
            ),
          ],
        ),
        LabResult(
          id: '2',
          title: 'Lipid Profile',
          date: DateTime.now().subtract(const Duration(days: 10)),
          doctor: 'Dr. Sara Ahmed',
          status: LabResultStatus.abnormal,
          items: [
            LabResultItem(
              name: 'Total Cholesterol',
              value: '220',
              unit: 'mg/dL',
              referenceRange: '<200',
              status: LabResultStatus.abnormal,
            ),
            LabResultItem(
              name: 'HDL Cholesterol',
              value: '45',
              unit: 'mg/dL',
              referenceRange: '>40',
              status: LabResultStatus.normal,
            ),
            LabResultItem(
              name: 'LDL Cholesterol',
              value: '150',
              unit: 'mg/dL',
              referenceRange: '<130',
              status: LabResultStatus.abnormal,
            ),
            LabResultItem(
              name: 'Triglycerides',
              value: '180',
              unit: 'mg/dL',
              referenceRange: '<150',
              status: LabResultStatus.abnormal,
            ),
          ],
        ),
        LabResult(
          id: '3',
          title: 'Liver Function Test',
          date: DateTime.now().subtract(const Duration(days: 15)),
          doctor: 'Dr. Ahmed Al-Farsi',
          status: LabResultStatus.normal,
          items: [
            LabResultItem(
              name: 'ALT',
              value: '25',
              unit: 'U/L',
              referenceRange: '7-55',
              status: LabResultStatus.normal,
            ),
            LabResultItem(
              name: 'AST',
              value: '22',
              unit: 'U/L',
              referenceRange: '8-48',
              status: LabResultStatus.normal,
            ),
            LabResultItem(
              name: 'Alkaline Phosphatase',
              value: '70',
              unit: 'U/L',
              referenceRange: '40-129',
              status: LabResultStatus.normal,
            ),
          ],
        ),
      ];
      
      _labResults.assignAll(mockResults);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load lab results: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      _isLoading.value = false;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lab Results'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Results'),
            Tab(text: 'Abnormal'),
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLabResults,
          ),
        ],
      ),
      body: Obx(() {
        if (_isLoading.value) {
          return const CustomLoadingIndicator();
        }
        
        if (_labResults.isEmpty) {
          return const EmptyState(
            icon: Icons.science,
            title: 'No Lab Results',
            message: 'You don\'t have any lab results yet.',
          );
        }
        
        return TabBarView(
          controller: _tabController,
          children: [
            // All results tab
            _buildLabResultsList(_labResults),
            
            // Abnormal results tab
            _buildLabResultsList(_labResults.where(
              (result) => result.status == LabResultStatus.abnormal
            ).toList()),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.snackbar(
            'Coming Soon',
            'Upload lab results feature is not implemented yet',
            snackPosition: SnackPosition.BOTTOM,
          );
        },
        backgroundColor: AppColors.primaryColor,
        child: const Icon(Icons.upload_file),
      ),
      bottomNavigationBar: Obx(
        () => PatientBottomNavBar(
          currentIndex: _navigationController.currentIndex,
          onTap: _navigationController.changePage,
        ),
      ),
    );
  }
  
  // Build lab results list
  Widget _buildLabResultsList(List<LabResult> results) {
    if (results.isEmpty) {
      return const EmptyState(
        icon: Icons.science,
        title: 'No Abnormal Results',
        message: 'You don\'t have any abnormal lab results.',
      );
    }
    
    return ListView.builder(
      itemCount: results.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final result = results[index];
        return _buildLabResultCard(result);
      },
    );
  }
  
  // Build lab result card
  Widget _buildLabResultCard(LabResult result) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showLabResultDetails(result),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: result.status == LabResultStatus.normal
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    result.status == LabResultStatus.normal
                        ? Icons.check_circle
                        : Icons.warning,
                    color: result.status == LabResultStatus.normal
                        ? Colors.green
                        : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMMM d, yyyy').format(result.date),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: result.status == LabResultStatus.normal
                          ? Colors.green
                          : Colors.red,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      result.status == LabResultStatus.normal
                          ? 'Normal'
                          : 'Abnormal',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Doctor: ${result.doctor}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${result.items.length} items',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: 'View Details',
                          icon: Icons.visibility,
                          onPressed: () => _showLabResultDetails(result),
                          height: 40,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.share, color: AppColors.primaryColor),
                        onPressed: () {
                          Get.snackbar(
                            'Coming Soon',
                            'Share feature is not implemented yet',
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.download, color: AppColors.primaryColor),
                        onPressed: () {
                          Get.snackbar(
                            'Coming Soon',
                            'Download feature is not implemented yet',
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Show lab result details
  void _showLabResultDetails(LabResult result) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(16),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      result.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Date: ${DateFormat('MMMM d, yyyy').format(result.date)}',
                style: const TextStyle(fontSize: 14),
              ),
              Text(
                'Doctor: ${result.doctor}',
                style: const TextStyle(fontSize: 14),
              ),
              Text(
                'Status: ${result.status == LabResultStatus.normal ? 'Normal' : 'Abnormal'}',
                style: TextStyle(
                  fontSize: 14,
                  color: result.status == LabResultStatus.normal
                      ? Colors.green
                      : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              
              // Results table
              Expanded(
                child: SingleChildScrollView(
                  child: Table(
                    columnWidths: const {
                      0: FlexColumnWidth(3),
                      1: FlexColumnWidth(2),
                      2: FlexColumnWidth(1),
                      3: FlexColumnWidth(2),
                      4: FlexColumnWidth(1),
                    },
                    border: TableBorder.all(
                      color: Colors.grey[300]!,
                      width: 1,
                    ),
                    children: [
                      // Table header
                      TableRow(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                        ),
                        children: [
                          _buildTableCell('Test', isHeader: true),
                          _buildTableCell('Result', isHeader: true),
                          _buildTableCell('Unit', isHeader: true),
                          _buildTableCell('Reference', isHeader: true),
                          _buildTableCell('Status', isHeader: true),
                        ],
                      ),
                      
                      // Table rows
                      ...result.items.map((item) => TableRow(
                        children: [
                          _buildTableCell(item.name),
                          _buildTableCell(item.value),
                          _buildTableCell(item.unit),
                          _buildTableCell(item.referenceRange),
                          _buildTableCell(
                            item.status == LabResultStatus.normal
                                ? 'Normal'
                                : 'Abnormal',
                            textColor: item.status == LabResultStatus.normal
                                ? Colors.green
                                : Colors.red,
                          ),
                        ],
                      )),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                    onPressed: () {
                      Get.back();
                      Get.snackbar(
                        'Coming Soon',
                        'Share feature is not implemented yet',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.download),
                    label: const Text('Download'),
                    onPressed: () {
                      Get.back();
                      Get.snackbar(
                        'Coming Soon',
                        'Download feature is not implemented yet',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Build table cell
  Widget _buildTableCell(String text, {bool isHeader = false, Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          color: textColor,
        ),
        textAlign: isHeader ? TextAlign.center : TextAlign.left,
      ),
    );
  }
}

// Lab result model
class LabResult {
  final String id;
  final String title;
  final DateTime date;
  final String doctor;
  final LabResultStatus status;
  final List<LabResultItem> items;
  
  LabResult({
    required this.id,
    required this.title,
    required this.date,
    required this.doctor,
    required this.status,
    required this.items,
  });
}

// Lab result item model
class LabResultItem {
  final String name;
  final String value;
  final String unit;
  final String referenceRange;
  final LabResultStatus status;
  
  LabResultItem({
    required this.name,
    required this.value,
    required this.unit,
    required this.referenceRange,
    required this.status,
  });
}

// Lab result status enum
enum LabResultStatus {
  normal,
  abnormal,
}
