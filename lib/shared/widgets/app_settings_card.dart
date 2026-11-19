import 'package:myprojectflut/app/theme/app_colors.dart';
import 'package:flutter/material.dart';

import 'role_about_dialog.dart';
import 'theme_mode_selector.dart';

class AppSettingsCard extends StatelessWidget {
  final VoidCallback? onChangePassword;
  final VoidCallback? onPrivacy;
  final VoidCallback? onAbout;

  const AppSettingsCard({
    super.key,
    this.onChangePassword,
    this.onPrivacy,
    this.onAbout,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Paramètres",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            const ThemeModeSelector(),
            const SizedBox(height: 8),
            _settingTile(
              context,
              icon: Icons.lock_outline_rounded,
              title: "Modifier le mot de passe",
              subtitle: "Sécurisez votre compte",
              color: AppColors.primary,
              onTap: onChangePassword ?? () {},
            ),
            _settingTile(
              context,
              icon: Icons.security_rounded,
              title: "Confidentialité",
              subtitle: "Protection des données",
              color: AppColors.primary,
              onTap: onPrivacy ?? () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Confidentialité & Sécurité'),
                    content: const Text('SmartPass protège vos données conformément aux normes de l\'ULPGL.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Compris'),
                      ),
                    ],
                  ),
                );
              },
            ),
            _settingTile(
              context,
              icon: Icons.info_outline_rounded,
              title: "À propos de SmartPass",
              subtitle: "Version 1.0.0",
              color: AppColors.primary,
              onTap: onAbout ?? () => showRoleAboutDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: .15),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}