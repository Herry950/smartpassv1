import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../core/services/auth_service.dart';

/// « À propos de SmartPass » adapté au rôle réel de l'utilisateur
/// (rôle déterminé en base, cf. AuthService.getCachedUserRole).
Future<void> showRoleAboutDialog(BuildContext context) async {
  String? role;
  try {
    role = await AuthService.getCachedUserRole();
  } catch (_) {
    role = null;
  }

  if (!context.mounted) return;

  final content = _contentFor(role);

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.primary),
          const SizedBox(width: 10),
          const Expanded(child: Text('À propos de SmartPass')),
        ],
      ),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SmartPass — ULPGL Goma, version 1.0.0. Plateforme de '
                'recouvrement des frais d’examen et de contrôle d’accès '
                'aux examens.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              _section('Votre rôle', [content.role]),
              _section('Vos fonctionnalités', content.features),
              _section('Vos responsabilités', content.duties),
              _section('Limites de vos autorisations', content.limits),
              _section('Les autres acteurs', content.others),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Fermer'),
        ),
      ],
    ),
  );
}

Widget _section(String title, List<String> lines) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        ...lines.map(
          (line) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('•  ', style: TextStyle(color: AppColors.primary)),
                Expanded(
                  child: Text(
                    line,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _RoleContent {
  const _RoleContent({
    required this.role,
    required this.features,
    required this.duties,
    required this.limits,
    required this.others,
  });

  final String role;
  final List<String> features;
  final List<String> duties;
  final List<String> limits;
  final List<String> others;
}

const _othersCentral =
    'Administration centrale : structure universitaire (facultés, départements, '
    'promotions, années, salles), comptes des administrateurs facultaires et '
    'cartes étudiantes. Aucun rôle financier.';
const _othersFaculty =
    'Administration facultaire : cours, sessions, examens, paiements, assistants, '
    'remises, remboursements et rapports de sa faculté.';
const _othersAssistant =
    'Assistant : contrôle des étudiants (matricule, QR, reçu) et validation des '
    'paiements en espèces pour les sessions qui lui sont affectées.';
const _othersStudent =
    'Étudiant : paiement de ses sessions, consultation de sa carte, de ses '
    'examens, reçus et notifications.';

_RoleContent _contentFor(String? role) {
  switch (role) {
    case AuthService.roleCentralAdmin:
      return const _RoleContent(
        role: 'Administrateur central : responsable de la structure '
            'universitaire et des comptes administratifs.',
        features: [
          'Créer, activer et désactiver les comptes des administrateurs facultaires.',
          'Gérer les facultés, les départements et les promotions affectées.',
          'Gérer les années académiques et l’année courante.',
          'Gérer les salles universitaires.',
          'Consulter les étudiants, générer, télécharger et imprimer leurs cartes.',
        ],
        duties: [
          'Maintenir une structure académique cohérente pour toutes les facultés.',
          'Attribuer chaque administrateur facultaire à une seule faculté.',
        ],
        limits: [
          'Aucun accès aux paiements, reçus, transactions, remises, fonds, '
              'remboursements ou rapports financiers des facultés.',
          'Pas de gestion des sessions, des examens ni des assistants des facultés.',
        ],
        others: [_othersFaculty, _othersAssistant, _othersStudent],
      );
    case AuthService.roleFacultyAdmin:
      return const _RoleContent(
        role: 'Administrateur facultaire : responsable de toutes les '
            'opérations de sa faculté, y compris financières.',
        features: [
          'Gérer les cours, les sessions d’évaluation et la programmation des examens.',
          'Ouvrir et fermer les paiements des sessions.',
          'Créer, activer, désactiver et affecter les assistants de la faculté.',
          'Consulter les paiements en ligne et en espèces, les reçus et les rapports PDF.',
          'Confirmer les remises d’espèces des assistants.',
          'Traiter les doubles paiements et déclarer les remboursements manuels.',
        ],
        duties: [
          'Vérifier les fonds physiques disponibles avant tout remboursement.',
          'Conserver les preuves des remboursements effectués.',
        ],
        limits: [
          'Périmètre limité à votre faculté.',
          'Pas de modification des ressources universitaires (salles, années, '
              'facultés, départements, promotions).',
          'Impossible de confirmer un remboursement à la place de l’étudiant.',
        ],
        others: [_othersCentral, _othersAssistant, _othersStudent],
      );
    case AuthService.roleAssistant:
      return const _RoleContent(
        role: 'Assistant : contrôle d’accès et encaissement en espèces '
            'pour les sessions qui vous sont affectées.',
        features: [
          'Vérifier un étudiant par matricule ou par le QR code de sa carte.',
          'Vérifier l’authenticité d’un reçu.',
          'Valider un paiement en espèces (compte actif requis).',
          'Enregistrer les contrôles d’accès et consulter vos remises.',
        ],
        duties: [
          'Remettre les espèces encaissées à l’administration de la faculté.',
        ],
        limits: [
          'Uniquement les sessions qui vous sont affectées.',
          'Pas de gestion des sessions, affectations ou remboursements.',
          'Un compte désactivé ne peut plus valider de nouveaux paiements en espèces.',
        ],
        others: [_othersCentral, _othersFaculty, _othersStudent],
      );
    case AuthService.roleStudent:
      return const _RoleContent(
        role: 'Étudiant : vous payez vos sessions et présentez votre carte '
            'numérique lors des contrôles.',
        features: [
          'Consulter votre profil, votre carte numérique et vos examens.',
          'Payer les sessions ouvertes qui vous concernent (carte via Flutterwave).',
          'Consulter vos paiements, reçus et notifications.',
          'Confirmer ou contester un remboursement déclaré par votre faculté.',
        ],
        duties: [
          'Vérifier vos informations et signaler toute erreur à votre faculté.',
        ],
        limits: [
          'Vous ne voyez que vos propres données.',
          'La carte officielle imprimable est délivrée par l’administration centrale.',
          'Un paiement n’est confirmé que par le serveur SmartPass.',
        ],
        others: [_othersCentral, _othersFaculty, _othersAssistant],
      );
    default:
      return const _RoleContent(
        role: 'Rôle non déterminé : reconnectez-vous pour afficher votre présentation.',
        features: [],
        duties: [],
        limits: [],
        others: [_othersCentral, _othersFaculty, _othersAssistant, _othersStudent],
      );
  }
}
