import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:myprojectflut/shared/widgets/module_tile_grid.dart';

/// Actions rapides de l'étudiant, avec la même grille de tuiles
/// que l'espace d'administration centrale (référence visuelle).
class QuickActionsCard extends StatelessWidget {
  const QuickActionsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final tiles = [
      ModuleTileData(
        icon: Icons.qr_code_2_rounded,
        label: 'Ma carte',
        onTap: () => context.push('/student/card'),
      ),
      ModuleTileData(
        icon: Icons.payment_rounded,
        label: 'Payer',
        onTap: () => context.push('/student/payment'),
      ),
      ModuleTileData(
        icon: Icons.event_available_rounded,
        label: 'Mes examens',
        onTap: () => context.push('/student/exams'),
      ),
      ModuleTileData(
        icon: Icons.receipt_long_rounded,
        label: 'Mes reçus',
        onTap: () => context.push('/student/receipts'),
      ),
      ModuleTileData(
        icon: Icons.notifications_active_rounded,
        label: 'Notifications',
        onTap: () => context.push('/student/notifications'),
      ),
      ModuleTileData(
        icon: Icons.currency_exchange_rounded,
        label: 'Remboursements',
        onTap: () => context.push('/student/reconciliations'),
      ),
      ModuleTileData(
        icon: Icons.person_rounded,
        label: 'Mon profil',
        onTap: () => context.push('/student/profile'),
      ),
    ];

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
              'Actions rapides',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            ModuleTileGrid(tiles: tiles),
          ],
        ),
      ),
    );
  }
}
