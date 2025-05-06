import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/app_colors.dart';

/// Base bottom navigation bar widget that can be customized for different user types
class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<BottomNavItem> items;

  const BottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primaryColor,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.normal,
          fontSize: 12,
        ),
        elevation: 0,
        items: items.map((item) => item.toBottomNavBarItem()).toList(),
      ),
    );
  }
}

/// Model class for bottom navigation items
class BottomNavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const BottomNavItem({
    required this.label,
    required this.icon,
    IconData? activeIcon,
  }) : activeIcon = activeIcon ?? icon;

  BottomNavigationBarItem toBottomNavBarItem() {
    return BottomNavigationBarItem(
      icon: Icon(icon),
      activeIcon: Icon(activeIcon),
      label: label,
    );
  }
}

/// Patient bottom navigation bar
class PatientBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const PatientBottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavBar(
      currentIndex: currentIndex,
      onTap: onTap,
      items: const [
        BottomNavItem(
          label: 'Home',
          icon: Icons.home_outlined,
          activeIcon: Icons.home,
        ),
        BottomNavItem(
          label: 'Health',
          icon: Icons.favorite_outline,
          activeIcon: Icons.favorite,
        ),
        BottomNavItem(
          label: 'Diagnosis',
          icon: Icons.medical_services_outlined,
          activeIcon: Icons.medical_services,
        ),
        BottomNavItem(
          label: 'Doctors',
          icon: Icons.people_outline,
          activeIcon: Icons.people,
        ),
        BottomNavItem(
          label: 'Profile',
          icon: Icons.person_outline,
          activeIcon: Icons.person,
        ),
      ],
    );
  }
}

/// Doctor bottom navigation bar
class DoctorBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const DoctorBottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavBar(
      currentIndex: currentIndex,
      onTap: onTap,
      items: const [
        BottomNavItem(
          label: 'Home',
          icon: Icons.home_outlined,
          activeIcon: Icons.home,
        ),
        BottomNavItem(
          label: 'Appointments',
          icon: Icons.calendar_today_outlined,
          activeIcon: Icons.calendar_today,
        ),
        BottomNavItem(
          label: 'Patients',
          icon: Icons.people_outline,
          activeIcon: Icons.people,
        ),
        BottomNavItem(
          label: 'Messages',
          icon: Icons.message_outlined,
          activeIcon: Icons.message,
        ),
        BottomNavItem(
          label: 'Profile',
          icon: Icons.person_outline,
          activeIcon: Icons.person,
        ),
      ],
    );
  }
}

/// Admin bottom navigation bar
class AdminBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const AdminBottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavBar(
      currentIndex: currentIndex,
      onTap: onTap,
      items: const [
        BottomNavItem(
          label: 'Dashboard',
          icon: Icons.dashboard_outlined,
          activeIcon: Icons.dashboard,
        ),
        BottomNavItem(
          label: 'Users',
          icon: Icons.people_outline,
          activeIcon: Icons.people,
        ),
        BottomNavItem(
          label: 'Doctors',
          icon: Icons.medical_services_outlined,
          activeIcon: Icons.medical_services,
        ),
        BottomNavItem(
          label: 'Messages',
          icon: Icons.message_outlined,
          activeIcon: Icons.message,
        ),
        BottomNavItem(
          label: 'Settings',
          icon: Icons.settings_outlined,
          activeIcon: Icons.settings,
        ),
      ],
    );
  }
}
