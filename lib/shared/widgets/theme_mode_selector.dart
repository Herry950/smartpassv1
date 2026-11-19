import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/theme_controller.dart';

/// Choix manuel du thème : « Clair » ou « Sombre ».
/// Le choix est conservé entre les sessions par `ThemeController`.
class ThemeModeSelector extends StatelessWidget {
  const ThemeModeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.mode,
      builder: (context, mode, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: .15),
                child: Icon(
                  mode == ThemeMode.dark
                      ? Icons.dark_mode_rounded
                      : Icons.light_mode_rounded,
                  color: AppColors.primary,
                ),
              ),
              title: const Text(
                'Thème',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Apparence de l’application'),
            ),
            SegmentedButton<ThemeMode>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                value: ThemeMode.light,
                label: Text('Clair'),
                icon: Icon(Icons.light_mode_outlined, size: 18),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text('Sombre'),
                icon: Icon(Icons.dark_mode_outlined, size: 18),
              ),
            ],
            selected: {mode},
            onSelectionChanged: (selection) {
              ThemeController.setMode(selection.first);
            },
            ),
          ],
        );
      },
    );
  }
}
