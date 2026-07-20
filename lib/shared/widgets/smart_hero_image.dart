import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class SmartHeroImage extends StatelessWidget {
  const SmartHeroImage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      height: 320,

      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.15),
            AppColors.primaryLight.withValues(alpha: 0.20),
          ],
        ),

        borderRadius: BorderRadius.circular(40),

        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.15),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),

      child: const Center(
        child: Icon(
          Icons.school_rounded,
          size: 120,
          color: AppColors.primary,
        ),
      ),
    );
  }
}