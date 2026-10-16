import 'package:flutter/material.dart';

class AppLogoutCard extends StatelessWidget {
  final VoidCallback onLogout;

  const AppLogoutCard({
    super.key,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.red.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.red.withValues(alpha: 0.2)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Colors.red.withValues(alpha: 0.15),
          child: const Icon(Icons.logout_rounded, color: Colors.red),
        ),
        title: const Text(
          "Déconnexion",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.red,
          ),
        ),
        subtitle: const Text("Fermer la session en cours"),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.red),
        onTap: onLogout,
      ),
    );
  }
}