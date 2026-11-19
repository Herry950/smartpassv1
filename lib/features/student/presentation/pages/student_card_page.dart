import 'package:myprojectflut/shared/widgets/home_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import 'package:myprojectflut/app/theme/app_colors.dart';
import 'package:myprojectflut/core/models/student.dart';
import 'package:myprojectflut/features/student/data/repositories/student_card_page_repository.dart';

import '../widgets/student_identity_card.dart';

/// Carte étudiante : version numérique (écran) et version physique
/// imprimable (PDF), construites à partir des mêmes données Supabase.
class StudentCardPage extends StatefulWidget {
  const StudentCardPage({super.key});

  @override
  State<StudentCardPage> createState() => _StudentCardPageState();
}

class _StudentCardPageState extends State<StudentCardPage> {
  late Future<Map<String, dynamic>?> _future =
      StudentCardPageRepository.load();

  void _refresh() {
    setState(() {
      _future = StudentCardPageRepository.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ma carte étudiante'),
        actions: [
          const HomeButton(),
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Impossible de charger la carte : ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final data = snapshot.data;

          if (data == null) {
            return const Center(
              child: Text('Carte étudiante introuvable.'),
            );
          }

          final Student student = data['student'];
          final Map<String, dynamic>? card = data['card'];

          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    children: [
                      StudentIdentityCard(student: student)
                          .animate()
                          .fadeIn()
                          .scale(begin: const Offset(.92, .92)),
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: .06),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.badge_outlined, color: AppColors.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Carte numérique officielle. La carte physique '
                                'imprimable est délivrée par l’administration '
                                'centrale de l’université.',
                                style: TextStyle(color: AppColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildStatusCard(student, card),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(Student student, Map<String, dynamic>? card) {
    final bool cardDeactivated = card != null && card['is_active'] != true;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ListTile(
              leading: Icon(
                student.examAuthorized
                    ? Icons.verified_rounded
                    : Icons.gpp_maybe_rounded,
                color: student.examAuthorized
                    ? AppColors.success
                    : AppColors.textSecondary,
              ),
              title: const Text('Accès aux examens'),
              subtitle: Text(
                student.examAuthorized
                    ? 'Autorisé : paiement de la session validé.'
                    : student.paymentValidated
                        ? 'Non autorisé : carte désactivée.'
                        : 'Non autorisé : paiement de la session non validé.',
              ),
            ),
            const Divider(),
            ListTile(
              leading: Icon(
                Icons.qr_code_rounded,
                color: AppColors.primary,
              ),
              title: const Text('QR code de vérification'),
              subtitle: const Text(
                'Présentez ce QR code à l’assistant : il identifie votre '
                'profil, puis l’assistant vérifie votre paiement en ligne.',
              ),
            ),
            const Divider(),
            ListTile(
              leading: Icon(
                Icons.calendar_month_rounded,
                color: AppColors.primary,
              ),
              title: const Text('Validité'),
              subtitle: Text(
                student.expiryDate != null
                    ? 'Expire le '
                        '${DateFormat('dd/MM/yyyy').format(student.expiryDate!)}'
                    : 'Année académique ${student.academicYear}',
              ),
            ),
            if (cardDeactivated) ...[
              const Divider(),
              const ListTile(
                leading: Icon(
                  Icons.block_rounded,
                  color: AppColors.error,
                ),
                title: Text('Carte désactivée'),
                subtitle: Text(
                  'Contactez l’administration de votre faculté.',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
