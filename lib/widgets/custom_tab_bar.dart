import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// A custom tab bar widget for consistent UI across the app
class CustomTabBar extends StatelessWidget implements PreferredSizeWidget {
  final TabController controller;
  final List<Widget> tabs;
  final Color? labelColor;
  final Color? unselectedLabelColor;
  final Color? indicatorColor;
  final double indicatorWeight;
  final EdgeInsetsGeometry? labelPadding;
  final TextStyle? labelStyle;
  final TextStyle? unselectedLabelStyle;
  final bool isScrollable;

  const CustomTabBar({
    super.key,
    required this.controller,
    required this.tabs,
    this.labelColor,
    this.unselectedLabelColor,
    this.indicatorColor,
    this.indicatorWeight = 2.0,
    this.labelPadding,
    this.labelStyle,
    this.unselectedLabelStyle,
    this.isScrollable = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: controller,
        tabs: tabs,
        labelColor: labelColor ?? AppColors.primaryColor,
        unselectedLabelColor: unselectedLabelColor ?? Colors.grey,
        indicatorColor: indicatorColor ?? AppColors.primaryColor,
        indicatorWeight: indicatorWeight,
        labelPadding: labelPadding,
        labelStyle: labelStyle ?? const TextStyle(fontWeight: FontWeight.bold),
        unselectedLabelStyle: unselectedLabelStyle,
        isScrollable: isScrollable,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(48.0);
}
