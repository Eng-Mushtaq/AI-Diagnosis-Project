import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/doctor_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../constants/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_app_bar.dart';

class DoctorTimeSlotsScreen extends StatefulWidget {
  const DoctorTimeSlotsScreen({Key? key}) : super(key: key);

  @override
  State<DoctorTimeSlotsScreen> createState() => _DoctorTimeSlotsScreenState();
}

class _DoctorTimeSlotsScreenState extends State<DoctorTimeSlotsScreen> {
  final DoctorController _doctorController = Get.find<DoctorController>();
  final AuthController _authController = Get.find<AuthController>();

  final List<String> _daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  final List<String> _timeSlots = [
    '08:00-08:30',
    '08:30-09:00',
    '09:00-09:30',
    '09:30-10:00',
    '10:00-10:30',
    '10:30-11:00',
    '11:00-11:30',
    '11:30-12:00',
    '12:00-12:30',
    '12:30-13:00',
    '13:00-13:30',
    '13:30-14:00',
    '14:00-14:30',
    '14:30-15:00',
    '15:00-15:30',
    '15:30-16:00',
    '16:00-16:30',
    '16:30-17:00',
    '17:00-17:30',
    '17:30-18:00',
  ];

  final RxString _selectedDay = ''.obs;
  final RxList<String> _selectedTimeSlots = <String>[].obs;
  final RxBool _isLoading = false.obs;

  @override
  void initState() {
    super.initState();
    // Set initial selected day if doctor has available days
    if (_doctorController.selectedDoctor != null &&
        _doctorController.selectedDoctor!.availableDays != null &&
        _doctorController.selectedDoctor!.availableDays!.isNotEmpty) {
      _selectedDay.value =
          _doctorController.selectedDoctor!.availableDays!.first;
      _updateSelectedTimeSlots();
    }
  }

  // Update selected time slots based on selected day
  void _updateSelectedTimeSlots() {
    if (_doctorController.selectedDoctor != null &&
        _doctorController.selectedDoctor!.availableTimeSlots != null &&
        _doctorController.selectedDoctor!.availableTimeSlots!.containsKey(
          _selectedDay.value,
        )) {
      _selectedTimeSlots.value = List<String>.from(
        _doctorController.selectedDoctor!.availableTimeSlots![_selectedDay
            .value]!,
      );
    } else {
      _selectedTimeSlots.clear();
    }
  }

  // Check if a day is available
  bool _isDayAvailable(String day) {
    return _doctorController.selectedDoctor != null &&
        _doctorController.selectedDoctor!.availableDays != null &&
        _doctorController.selectedDoctor!.availableDays!.contains(day);
  }

  // Toggle day availability
  Future<void> _toggleDayAvailability(String day) async {
    if (_doctorController.selectedDoctor == null) return;

    _isLoading.value = true;

    try {
      if (_isDayAvailable(day)) {
        // Remove day
        await _doctorController.removeDoctorAvailableDay(
          _doctorController.selectedDoctor!.id,
          day,
        );

        // Update selected day if it was removed
        if (_selectedDay.value == day) {
          if (_doctorController.selectedDoctor!.availableDays != null &&
              _doctorController.selectedDoctor!.availableDays!.isNotEmpty) {
            _selectedDay.value =
                _doctorController.selectedDoctor!.availableDays!.first;
          } else {
            _selectedDay.value = '';
          }
          _updateSelectedTimeSlots();
        }
      } else {
        // Add day
        await _doctorController.addDoctorAvailableDay(
          _doctorController.selectedDoctor!.id,
          day,
        );

        // Set as selected day if no day is selected
        if (_selectedDay.value.isEmpty) {
          _selectedDay.value = day;
          _updateSelectedTimeSlots();
        }
      }
    } finally {
      _isLoading.value = false;
    }
  }

  // Toggle time slot selection
  Future<void> _toggleTimeSlot(String timeSlot) async {
    if (_doctorController.selectedDoctor == null || _selectedDay.value.isEmpty)
      return;

    _isLoading.value = true;

    try {
      if (_selectedTimeSlots.contains(timeSlot)) {
        // Remove time slot
        await _doctorController.removeDoctorTimeSlot(
          _doctorController.selectedDoctor!.id,
          _selectedDay.value,
          timeSlot,
        );
        _selectedTimeSlots.remove(timeSlot);
      } else {
        // Add time slot
        await _doctorController.addDoctorTimeSlot(
          _doctorController.selectedDoctor!.id,
          _selectedDay.value,
          timeSlot,
        );
        _selectedTimeSlots.add(timeSlot);
      }
    } finally {
      _isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Manage Time Slots', showBackButton: true),
      body: Obx(() {
        if (_doctorController.selectedDoctor == null) {
          return const Center(child: Text('No doctor selected'));
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Available days section
              const Text(
                'Available Days',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                ),
              ),
              const SizedBox(height: 16),

              // Days of week chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    _daysOfWeek.map((day) {
                      final isAvailable = _isDayAvailable(day);
                      final isSelected = _selectedDay.value == day;

                      return FilterChip(
                        label: Text(day),
                        selected: isAvailable,
                        onSelected: (_) => _toggleDayAvailability(day),
                        backgroundColor: Colors.grey[200],
                        selectedColor: AppColors.primaryColor.withOpacity(0.2),
                        checkmarkColor: AppColors.primaryColor,
                        labelStyle: TextStyle(
                          color:
                              isSelected
                                  ? AppColors.primaryColor
                                  : Colors.black,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color:
                                isSelected
                                    ? AppColors.primaryColor
                                    : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      );
                    }).toList(),
              ),
              const SizedBox(height: 24),

              // Time slots section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Time Slots',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  if (_selectedDay.value.isNotEmpty)
                    Text(
                      'for $_selectedDay',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Day selection dropdown
              if (_doctorController.selectedDoctor!.availableDays != null &&
                  _doctorController.selectedDoctor!.availableDays!.isNotEmpty)
                DropdownButtonFormField<String>(
                  value:
                      _selectedDay.value.isNotEmpty ? _selectedDay.value : null,
                  hint: const Text('Select a day'),
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
                      _doctorController.selectedDoctor!.availableDays!
                          .map(
                            (day) =>
                                DropdownMenuItem(value: day, child: Text(day)),
                          )
                          .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      _selectedDay.value = value;
                      _updateSelectedTimeSlots();
                    }
                  },
                ),

              if (_selectedDay.value.isEmpty &&
                  (_doctorController.selectedDoctor!.availableDays == null ||
                      _doctorController.selectedDoctor!.availableDays!.isEmpty))
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Please select an available day first',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Time slots grid
              if (_selectedDay.value.isNotEmpty)
                Expanded(
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 2.5,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                    itemCount: _timeSlots.length,
                    itemBuilder: (context, index) {
                      final timeSlot = _timeSlots[index];
                      final isSelected = _selectedTimeSlots.contains(timeSlot);

                      return InkWell(
                        onTap: () => _toggleTimeSlot(timeSlot),
                        child: Container(
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? AppColors.primaryColor
                                    : Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            timeSlot,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

              // Loading indicator
              if (_isLoading.value)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}
