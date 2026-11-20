import 'package:myprojectflut/app/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Notification de l'étudiant : cliquable, état « Non lu » / « Lu » visible.
class NotificationItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final String time;
  final bool unread;

  /// Ouverture de la notification (marquage lu + navigation éventuelle).
  final VoidCallback? onTap;

  /// Marquage individuel comme lu, sans navigation.
  final VoidCallback? onMarkRead;

  /// Vrai si la notification conduit vers une page de l'application.
  final bool hasDestination;

  const NotificationItem({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    required this.time,
    this.unread = false,
    this.onTap,
    this.onMarkRead,
    this.hasDestination = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: unread
            ? color.withValues(alpha: .08)
            : AppColors.background,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: unread
                    ? color.withValues(alpha: .35)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: color.withValues(alpha: .15),
                  child: Icon(
                    icon,
                    color: color,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight:
                              unread ? FontWeight.bold : FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _StatusChip(unread: unread, color: color),
                          if (unread && onMarkRead != null)
                            TextButton(
                              onPressed: onMarkRead,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                minimumSize: const Size(0, 30),
                                visualDensity: VisualDensity.compact,
                              ),
                              child: const Text('Marquer comme lu'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  children: [
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (hasDestination)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.unread, required this.color});

  final bool unread;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final chipColor = unread ? color : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            unread ? Icons.circle : Icons.done_all_rounded,
            size: 10,
            color: chipColor,
          ),
          const SizedBox(width: 5),
          Text(
            unread ? 'Non lu' : 'Lu',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: chipColor,
            ),
          ),
        ],
      ),
    );
  }
}
