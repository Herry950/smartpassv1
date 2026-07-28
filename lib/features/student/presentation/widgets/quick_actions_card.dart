import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'quick_action_button.dart';

class QuickActionsCard extends StatelessWidget {
  const QuickActionsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    final crossAxisCount = width >= 1100
        ? 3
        : width >= 700
            ? 3
            : 2;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "⚡ Actions rapides",
              style: Theme.of(context).textTheme.titleLarge,
            ),

            const SizedBox(height: 24),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.15,
              children: [
                QuickActionButton(
                  icon: Icons.qr_code_2_rounded,
                  label: "Ma carte",
                  color: Colors.indigo,
                  onTap: () {
                    context.go('/student/card');
                  },
                ),

                QuickActionButton(
                  icon: Icons.payment_rounded,
                  label: "Payer",
                  color: Colors.green,
                  onTap: () {
                    context.go('/student/payment');
                  },
                ),

                QuickActionButton(
                  icon: Icons.picture_as_pdf_rounded,
                  label: "Mes reçus",
                  color: Colors.red,
                  onTap: () {
                    context.go('/student/receipts');
                  },
                ),

                QuickActionButton(
                  icon: Icons.notifications_active_rounded,
                  label: "Notifications",
                  color: Colors.orange,
                  onTap: () {
                    context.go('/student/notifications');
                  },
                ),

                QuickActionButton(
                  icon: Icons.person_rounded,
                  label: "Mon profil",
                  color: Colors.deepPurple,
                  onTap: () {
                    context.go('/student/profile');
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}