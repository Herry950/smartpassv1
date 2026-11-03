/// Catalogue central des messages métier de SmartPass.
///
/// Ce fichier contient les messages et leur formulation selon le rôle.
/// La présentation visuelle sera gérée séparément.
enum SmartPassRole {
  student,
  assistant,
  admin,
}

enum SmartPassMessageType {
  success,
  info,
  warning,
  error,
}

enum SmartPassMessageCode {
  paymentAlreadyValidated,
  paymentPending,
  paymentFailed,
  paymentValidated,
  manualValidationRefused,
  paymentConflict,
  receiptUnavailable,
  accessAuthorized,
  accessRefused,
  genericError,
}

class SmartPassMessage {
  const SmartPassMessage({
    required this.title,
    required this.message,
    required this.type,
  });

  final String title;
  final String message;
  final SmartPassMessageType type;
}

class SmartPassMessages {
  SmartPassMessages._();

  /// Retourne un message adapté au rôle et à la situation.
  static SmartPassMessage get({
    required SmartPassMessageCode code,
    required SmartPassRole role,
  }) {
    switch (code) {
      case SmartPassMessageCode.paymentAlreadyValidated:
        switch (role) {
          case SmartPassRole.student:
            return const SmartPassMessage(
              title: 'Paiement déjà effectué',
              message:
                  'Votre participation à cette session d’examen a déjà '
                  'été payée. Aucun nouveau paiement n’est nécessaire.',
              type: SmartPassMessageType.info,
            );

          case SmartPassRole.assistant:
            return const SmartPassMessage(
              title: 'Paiement déjà validé',
              message:
                  'Cet étudiant possède déjà un paiement validé pour '
                  'cette session. Aucune validation supplémentaire '
                  'n’est autorisée.',
              type: SmartPassMessageType.warning,
            );

          case SmartPassRole.admin:
            return const SmartPassMessage(
              title: 'Paiement déjà validé',
              message:
                  'Un paiement est déjà validé pour cet étudiant et '
                  'cette session. Consultez l’historique avant toute '
                  'intervention.',
              type: SmartPassMessageType.warning,
            );
        }

      case SmartPassMessageCode.paymentPending:
        switch (role) {
          case SmartPassRole.student:
            return const SmartPassMessage(
              title: 'Paiement en attente',
              message:
                  'Votre paiement est en cours de traitement. '
                  'Veuillez patienter avant de recommencer.',
              type: SmartPassMessageType.info,
            );

          case SmartPassRole.assistant:
            return const SmartPassMessage(
              title: 'Paiement en attente',
              message:
                  'Ce paiement n’est pas encore confirmé. '
                  'Vérifiez son état avant toute validation manuelle.',
              type: SmartPassMessageType.warning,
            );

          case SmartPassRole.admin:
            return const SmartPassMessage(
              title: 'Paiement en attente',
              message:
                  'Le paiement n’est pas encore confirmé. '
                  'Consultez son état et son historique.',
              type: SmartPassMessageType.warning,
            );
        }

      case SmartPassMessageCode.paymentFailed:
        switch (role) {
          case SmartPassRole.student:
            return const SmartPassMessage(
              title: 'Paiement non abouti',
              message:
                  'Le paiement n’a pas abouti. Vérifiez son état '
                  'avant de tenter une nouvelle opération.',
              type: SmartPassMessageType.error,
            );

          case SmartPassRole.assistant:
          case SmartPassRole.admin:
            return const SmartPassMessage(
              title: 'Paiement non confirmé',
              message:
                  'Cette tentative ne constitue pas un paiement '
                  'validé. Consultez son historique.',
              type: SmartPassMessageType.warning,
            );
        }

      case SmartPassMessageCode.paymentValidated:
        switch (role) {
          case SmartPassRole.student:
            return const SmartPassMessage(
              title: 'Paiement confirmé',
              message:
                  'Votre paiement a été confirmé. Vous pouvez '
                  'consulter votre reçu.',
              type: SmartPassMessageType.success,
            );

          case SmartPassRole.assistant:
          case SmartPassRole.admin:
            return const SmartPassMessage(
              title: 'Paiement confirmé',
              message:
                  'Le paiement est validé dans SmartPass.',
              type: SmartPassMessageType.success,
            );
        }

      case SmartPassMessageCode.manualValidationRefused:
        return const SmartPassMessage(
          title: 'Validation refusée',
          message:
              'Cette opération ne peut pas être validée dans son état '
              'actuel. Vérifiez le statut du paiement et son historique.',
          type: SmartPassMessageType.warning,
        );

      case SmartPassMessageCode.paymentConflict:
        switch (role) {
          case SmartPassRole.student:
            return const SmartPassMessage(
              title: 'Vérification nécessaire',
              message:
                  'Nous ne pouvons pas confirmer cette opération pour '
                  'le moment. Veuillez contacter le service compétent.',
              type: SmartPassMessageType.warning,
            );

          case SmartPassRole.assistant:
          case SmartPassRole.admin:
            return const SmartPassMessage(
              title: 'Conflit de paiement',
              message:
                  'Une incohérence a été détectée. Vérifiez les '
                  'paiements et leur historique avant toute intervention.',
              type: SmartPassMessageType.error,
            );
        }

      case SmartPassMessageCode.receiptUnavailable:
        return const SmartPassMessage(
          title: 'Reçu indisponible',
          message:
              'Le reçu n’est pas disponible pour le moment. '
              'Veuillez réessayer ultérieurement.',
          type: SmartPassMessageType.info,
        );

      case SmartPassMessageCode.accessAuthorized:
        return const SmartPassMessage(
          title: 'Accès autorisé',
          message:
              'Les conditions d’accès à cette session sont satisfaites.',
          type: SmartPassMessageType.success,
        );

      case SmartPassMessageCode.accessRefused:
        return const SmartPassMessage(
          title: 'Accès non autorisé',
          message:
              'Les conditions d’accès à cette session ne sont pas '
              'satisfaites. Vérifiez la situation de l’étudiant.',
          type: SmartPassMessageType.warning,
        );

      case SmartPassMessageCode.genericError:
        return const SmartPassMessage(
          title: 'Une erreur est survenue',
          message:
              'L’opération n’a pas pu être terminée. Veuillez réessayer '
              'ou contacter le service compétent.',
          type: SmartPassMessageType.error,
        );
    }
  }
}