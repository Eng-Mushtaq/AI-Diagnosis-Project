import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/app_colors.dart';

/// A custom app bar widget for consistent UI across the app
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final Color? textColor;
  final double elevation;
  final Widget? leading;
  final PreferredSizeWidget? bottom;

  const CustomAppBar({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.actions,
    this.backgroundColor,
    this.textColor,
    this.elevation = 0.5,
    this.leading,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      backgroundColor: backgroundColor ?? Colors.white,
      elevation: elevation,
      leading: showBackButton && Navigator.canPop(context)
          ? leading ??
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, size: 20),
                color: textColor ?? Colors.black,
                onPressed: () => Get.back(),
              )
          : leading,
      actions: actions,
      bottom: bottom,
      iconTheme: IconThemeData(
        color: textColor ?? Colors.black,
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
      kToolbarHeight + (bottom?.preferredSize.height ?? 0.0));
}
