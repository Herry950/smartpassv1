import 'package:flutter/material.dart';

import 'package:myprojectflut/app/theme/app_colors.dart';

class AssistantHeader extends StatelessWidget {
  final String assistantName;

  const AssistantHeader({
    super.key,
    required this.assistantName,
  });

  @override
  Widget build(BuildContext context) {
    final firstName = assistantName.split(" ").first;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: AppColors.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .12),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  "Bonjour $firstName 👋",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  "Contrôle d'accès aux examens",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 18),

                const Row(
                  children: [
                    Icon(
                      Icons.verified_user_rounded,
                      color: Colors.white70,
                      size: 18,
                    ),

                    SizedBox(width: 6),

                    Expanded(
                      child: Text(
                        "Scanner • Vérifier • Autoriser",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 20),

          const CircleAvatar(
            radius: 38,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.qr_code_scanner_rounded,
              size: 40,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}