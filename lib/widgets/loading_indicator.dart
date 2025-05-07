import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// A reusable loading indicator widget
class LoadingIndicator extends StatelessWidget {
  final Color? color;
  final double size;

  const LoadingIndicator({
    super.key,
    this.color,
    this.size = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            color ?? AppColors.primaryColor,
          ),
          strokeWidth: 3.0,
        ),
      ),
    );
  }
}
