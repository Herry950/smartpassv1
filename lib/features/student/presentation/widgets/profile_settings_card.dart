import 'package:flutter/material.dart';

class ProfileSettingsCard extends StatelessWidget {
  const ProfileSettingsCard({
    super.key,
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

            _settingTile(
              context,
              icon: Icons.lock_outline_rounded,
              title: "Modifier le mot de passe",
              subtitle: "Sécurisez votre compte",
              color: Colors.blue,
              onTap: () {},
            ),

            _settingTile(
              context,
              icon: Icons.language_rounded,
              title: "Langue",
              subtitle: "Français",
              color: Colors.green,
              onTap: () {},
            ),

            _settingTile(
              context,
              icon: Icons.notifications_active_rounded,
              title: "Notifications",
              subtitle: "Gérer les alertes SmartPass",
              color: Colors.orange,
              onTap: () {},
            ),

            _settingTile(
              context,
              icon: Icons.security_rounded,
              title: "Confidentialité",
              subtitle: "Protection des données",
              color: Colors.purple,
              onTap: () {},
            ),

            _settingTile(
              context,
              icon: Icons.info_outline_rounded,
              title: "À propos de SmartPass",
              subtitle: "Version 1.0.0",
              color: Colors.teal,
              onTap: () {},
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
        child: Icon(
          icon,
          color: color,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(
        Icons.chevron_right_rounded,
      ),
      onTap: onTap,
    );
  }
}