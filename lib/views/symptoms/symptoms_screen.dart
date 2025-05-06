import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/symptom_controller.dart';
import '../../models/symptom_model.dart';
import '../../routes/app_routes.dart';
import '../../widgets/custom_button.dart';

class SymptomsScreen extends StatefulWidget {
  const SymptomsScreen({super.key});

  @override
  State<SymptomsScreen> createState() => _SymptomsScreenState();
}

class _SymptomsScreenState extends State<SymptomsScreen> {
  final SymptomController _symptomController = Get.find<SymptomController>();
  final AuthController _authController = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    // Use post-frame callback to ensure loading happens after the build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSymptoms();
    });
  }

  Future<void> _loadSymptoms() async {
    await _symptomController.getSymptoms(_authController.user!.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Symptoms History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Get.toNamed(AppRoutes.addSymptom),
          ),
        ],
      ),
      body: Obx(() {
        if (_symptomController.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_symptomController.symptomList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.sick_outlined, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'No symptoms recorded yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: 'Add Symptom',
                  onPressed: () => Get.toNamed(AppRoutes.addSymptom),
                  icon: Icons.add,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _symptomController.symptomList.length,
          itemBuilder: (context, index) {
            final symptom = _symptomController.symptomList[index];
            return _buildSymptomCard(symptom);
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed(AppRoutes.addSymptom),
        backgroundColor: AppColors.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSymptomCard(SymptomModel symptom) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.circle,
                  size: 12,
                  color:
                      symptom.severity <= 3
                          ? Colors.green
                          : symptom.severity <= 6
                          ? Colors.orange
                          : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  symptom.severityText,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '${symptom.duration} days',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(symptom.description, style: const TextStyle(fontSize: 16)),
            if (symptom.bodyParts != null && symptom.bodyParts!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children:
                    symptom.bodyParts!
                        .map(
                          (part) => Chip(
                            label: Text(part),
                            backgroundColor: AppColors.secondaryLightColor,
                          ),
                        )
                        .toList(),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Recorded on ${symptom.timestamp.toString().split('.')[0]}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
