import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import 'smartpass_messages.dart';

/// Centre de présentation des messages de SmartPass.
///
/// Le contenu du message est défini dans SmartPassMessages.
/// Cette classe gère uniquement sa présentation à l'écran.
class SmartPassFeedback {
  SmartPassFeedback._();

  /// Associe le type de message à la couleur officielle de SmartPass.
  static Color _colorFor(SmartPassMessageType type) {
    switch (type) {
      case SmartPassMessageType.success:
        return AppColors.success;
      case SmartPassMessageType.info:
        return AppColors.info;
      case SmartPassMessageType.warning:
        return AppColors.warning;
      case SmartPassMessageType.error:
        return AppColors.error;
    }
  }

  /// Associe le type de message à une icône appropriée.
  static IconData _iconFor(SmartPassMessageType type) {
    switch (type) {
      case SmartPassMessageType.success:
        return Icons.check_circle_outline;
      case SmartPassMessageType.info:
        return Icons.info_outline;
      case SmartPassMessageType.warning:
        return Icons.warning_amber_rounded;
      case SmartPassMessageType.error:
        return Icons.error_outline;
    }
  }

  /// Affiche une boîte de dialogue pour les messages importants.
  ///
  /// Exemple :
  /// await SmartPassFeedback.showDialogMessage(
  ///   context,
  ///   code: SmartPassMessageCode.paymentAlreadyValidated,
  ///   role: SmartPassRole.student,
  /// );
  static Future<void> showDialogMessage(
    BuildContext context, {
    required SmartPassMessageCode code,
    required SmartPassRole role,
    String? details,
    String buttonLabel = 'Compris',
    bool barrierDismissible = true,
  }) async {
    final message = SmartPassMessages.get(
      code: code,
      role: role,
    );

    final color = _colorFor(message.type);

    await showDialog<void>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.border),
          ),
          icon: Icon(
            _iconFor(message.type),
            color: color,
            size: 44,
          ),
          title: Text(
            message.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message.message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                if (details != null && details.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    details,
                    textAlign: TextAlign.center,
                    style: Theme.of(dialogContext).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          actions: [
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textLight,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: Text(buttonLabel),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Affiche une notification temporaire en bas de l'écran.
  ///
  /// À utiliser pour les confirmations qui ne nécessitent pas
  /// une action immédiate de l'utilisateur.
  static void showSnackBar(
    BuildContext context, {
    required SmartPassMessageCode code,
    required SmartPassRole role,
    String? details,
    Duration duration = const Duration(seconds: 4),
  }) {
    final message = SmartPassMessages.get(
      code: code,
      role: role,
    );

    final messenger = ScaffoldMessenger.maybeOf(context);

    if (messenger == null) return;

    final additionalDetails = details?.trim();

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: duration,
          backgroundColor: AppColors.primaryDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                _iconFor(message.type),
                color: AppColors.textLight,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.title,
                      style: const TextStyle(
                        color: AppColors.textLight,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      additionalDetails != null &&
                              additionalDetails.isNotEmpty
                          ? additionalDetails
                          : message.message,
                      style: const TextStyle(
                        color: AppColors.textLight,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
  }
}