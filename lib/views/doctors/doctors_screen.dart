import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../controllers/doctor_controller.dart';
import '../../models/doctor_model.dart';
import '../../routes/app_routes.dart';
import '../../widgets/doctor_card.dart';

// Doctors screen to display list of available doctors
class DoctorsScreen extends StatefulWidget {
  const DoctorsScreen({super.key});

  @override
  State<DoctorsScreen> createState() => _DoctorsScreenState();
}

class _DoctorsScreenState extends State<DoctorsScreen> {
  final DoctorController _doctorController = Get.find<DoctorController>();
  final TextEditingController _searchController = TextEditingController();
  final RxString _selectedSpecialization = ''.obs;
  final RxString _selectedCity = ''.obs;
  final RxBool _filterByVideo = false.obs;
  final RxBool _filterByChat = false.obs;
  final RxString _sortBy = 'rating'.obs;
  final RxBool _sortAscending = false.obs;

  @override
  void initState() {
    super.initState();
    // Use post-frame callback to ensure loading happens after the build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDoctors();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Load all doctors
  Future<void> _loadDoctors() async {
    await _doctorController.getAllDoctors();
  }

  // Apply filters and sorting
  List<DoctorModel> _getFilteredDoctors() {
    List<DoctorModel> filteredDoctors = List.from(_doctorController.doctors);

    // Apply specialization filter
    if (_selectedSpecialization.value.isNotEmpty) {
      filteredDoctors =
          filteredDoctors
              .where(
                (doctor) =>
                    doctor.specialization == _selectedSpecialization.value,
              )
              .toList();
    }

    // Apply city filter
    if (_selectedCity.value.isNotEmpty) {
      filteredDoctors =
          filteredDoctors
              .where((doctor) => doctor.city == _selectedCity.value)
              .toList();
    }

    // Apply video/chat filters
    if (_filterByVideo.value || _filterByChat.value) {
      filteredDoctors =
          filteredDoctors.where((doctor) {
            if (_filterByVideo.value && _filterByChat.value) {
              return doctor.isAvailableForVideo && doctor.isAvailableForChat;
            } else if (_filterByVideo.value) {
              return doctor.isAvailableForVideo;
            } else if (_filterByChat.value) {
              return doctor.isAvailableForChat;
            }
            return true;
          }).toList();
    }

    // Apply search filter
    if (_searchController.text.isNotEmpty) {
      final searchTerm = _searchController.text.toLowerCase();
      filteredDoctors =
          filteredDoctors.where((doctor) {
            return doctor.name.toLowerCase().contains(searchTerm) ||
                doctor.specialization.toLowerCase().contains(searchTerm) ||
                doctor.hospital.toLowerCase().contains(searchTerm);
          }).toList();
    }

    // Apply sorting
    switch (_sortBy.value) {
      case 'rating':
        filteredDoctors.sort(
          (a, b) =>
              _sortAscending.value
                  ? a.rating.compareTo(b.rating)
                  : b.rating.compareTo(a.rating),
        );
        break;
      case 'experience':
        filteredDoctors.sort(
          (a, b) =>
              _sortAscending.value
                  ? a.experience.compareTo(b.experience)
                  : b.experience.compareTo(a.experience),
        );
        break;
      case 'fee':
        filteredDoctors.sort(
          (a, b) =>
              _sortAscending.value
                  ? a.consultationFee.compareTo(b.consultationFee)
                  : b.consultationFee.compareTo(a.consultationFee),
        );
        break;
    }

    return filteredDoctors;
  }

  // Show filter bottom sheet
  void _showFilterBottomSheet() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filter Doctors',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    Get.back();
                  },
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),

            // Specialization filter
            const Text(
              'Specialization',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Obx(
              () => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: _selectedSpecialization.value.isEmpty,
                    onSelected: (selected) {
                      if (selected) {
                        _selectedSpecialization.value = '';
                      }
                    },
                  ),
                  ..._doctorController.getAvailableSpecializations().map((
                    spec,
                  ) {
                    return ChoiceChip(
                      label: Text(spec),
                      selected: _selectedSpecialization.value == spec,
                      onSelected: (selected) {
                        if (selected) {
                          _selectedSpecialization.value = spec;
                        } else {
                          _selectedSpecialization.value = '';
                        }
                      },
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // City filter
            const Text('City', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Obx(
              () => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: _selectedCity.value.isEmpty,
                    onSelected: (selected) {
                      if (selected) {
                        _selectedCity.value = '';
                      }
                    },
                  ),
                  ..._doctorController.getAvailableCities().map((city) {
                    return ChoiceChip(
                      label: Text(city),
                      selected: _selectedCity.value == city,
                      onSelected: (selected) {
                        if (selected) {
                          _selectedCity.value = city;
                        } else {
                          _selectedCity.value = '';
                        }
                      },
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Consultation type
            const Text(
              'Consultation Type',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Obx(
                  () => FilterChip(
                    label: const Text('Video Consultation'),
                    selected: _filterByVideo.value,
                    onSelected: (selected) {
                      _filterByVideo.value = selected;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Obx(
                  () => FilterChip(
                    label: const Text('Chat Consultation'),
                    selected: _filterByChat.value,
                    onSelected: (selected) {
                      _filterByChat.value = selected;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Apply button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Get.back();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Apply Filters'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Show sort bottom sheet
  void _showSortBottomSheet() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Sort Doctors',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    Get.back();
                  },
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),

            // Sort options
            Obx(
              () => RadioListTile<String>(
                title: const Text('Rating (Highest first)'),
                value: 'rating',
                groupValue: _sortBy.value,
                onChanged: (value) {
                  _sortBy.value = value!;
                  _sortAscending.value = false;
                },
              ),
            ),
            Obx(
              () => RadioListTile<String>(
                title: const Text('Experience (Most first)'),
                value: 'experience',
                groupValue: _sortBy.value,
                onChanged: (value) {
                  _sortBy.value = value!;
                  _sortAscending.value = false;
                },
              ),
            ),
            Obx(
              () => RadioListTile<String>(
                title: const Text('Fee (Lowest first)'),
                value: 'fee',
                groupValue: _sortBy.value,
                onChanged: (value) {
                  _sortBy.value = value!;
                  _sortAscending.value = true;
                },
              ),
            ),
            Obx(
              () => RadioListTile<String>(
                title: const Text('Fee (Highest first)'),
                value: 'fee_desc',
                groupValue:
                    _sortBy.value == 'fee' && !_sortAscending.value
                        ? 'fee_desc'
                        : '',
                onChanged: (value) {
                  _sortBy.value = 'fee';
                  _sortAscending.value = false;
                },
              ),
            ),
            const SizedBox(height: 16),

            // Apply button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Get.back();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Apply Sorting'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Doctors'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterBottomSheet,
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: _showSortBottomSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search doctors, specializations...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    _searchController.text.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Obx(
                  () =>
                      _selectedSpecialization.value.isNotEmpty
                          ? Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Chip(
                              label: Text(_selectedSpecialization.value),
                              deleteIcon: const Icon(Icons.close, size: 16),
                              onDeleted: () {
                                _selectedSpecialization.value = '';
                              },
                            ),
                          )
                          : const SizedBox.shrink(),
                ),
                Obx(
                  () =>
                      _selectedCity.value.isNotEmpty
                          ? Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Chip(
                              label: Text(_selectedCity.value),
                              deleteIcon: const Icon(Icons.close, size: 16),
                              onDeleted: () {
                                _selectedCity.value = '';
                              },
                            ),
                          )
                          : const SizedBox.shrink(),
                ),
                Obx(
                  () =>
                      _filterByVideo.value
                          ? Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Chip(
                              label: const Text('Video'),
                              deleteIcon: const Icon(Icons.close, size: 16),
                              onDeleted: () {
                                _filterByVideo.value = false;
                              },
                            ),
                          )
                          : const SizedBox.shrink(),
                ),
                Obx(
                  () =>
                      _filterByChat.value
                          ? Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Chip(
                              label: const Text('Chat'),
                              deleteIcon: const Icon(Icons.close, size: 16),
                              onDeleted: () {
                                _filterByChat.value = false;
                              },
                            ),
                          )
                          : const SizedBox.shrink(),
                ),
                Obx(
                  () =>
                      (_selectedSpecialization.value.isNotEmpty ||
                              _selectedCity.value.isNotEmpty ||
                              _filterByVideo.value ||
                              _filterByChat.value)
                          ? TextButton.icon(
                            icon: const Icon(Icons.clear_all),
                            label: const Text('Clear All'),
                            onPressed: () {
                              _selectedSpecialization.value = '';
                              _selectedCity.value = '';
                              _filterByVideo.value = false;
                              _filterByChat.value = false;
                            },
                          )
                          : const SizedBox.shrink(),
                ),
              ],
            ),
          ),

          // Doctor list
          Expanded(
            child: Obx(() {
              if (_doctorController.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              final filteredDoctors = _getFilteredDoctors();

              if (filteredDoctors.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      const Text(
                        'No doctors found',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Try changing your search or filters',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: _loadDoctors,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredDoctors.length,
                  itemBuilder: (context, index) {
                    final doctor = filteredDoctors[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: DoctorCard(
                        doctor: doctor,
                        onTap: () {
                          _doctorController.setSelectedDoctor(doctor);
                          Get.toNamed(AppRoutes.doctorDetails);
                        },
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
