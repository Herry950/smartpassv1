import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LogoutCard extends StatelessWidget {
  const LogoutCard({
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
              "Compte",
              style: Theme.of(context).textTheme.titleLarge,
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      title: const Text(
                        "Déconnexion",
                      ),
                      content: const Text(
                        "Voulez-vous vraiment vous déconnecter de SmartPass ?",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text(
                            "Annuler",
                          ),
                        ),

                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            context.go('/login');
                          },
                          child: const Text(
                            "Déconnexion",
                          ),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(
                  Icons.logout_rounded,
                ),
                label: const Text(
                  "Se déconnecter",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}