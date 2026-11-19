import 'package:myprojectflut/shared/widgets/home_button.dart';
import 'package:myprojectflut/app/theme/app_colors.dart';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:myprojectflut/shared/widgets/change_password_dialog.dart';

import 'package:myprojectflut/core/models/student.dart';
import 'package:myprojectflut/features/student/data/repositories/student_repository.dart';
import 'package:myprojectflut/shared/widgets/app_logout_card.dart';
import 'package:myprojectflut/shared/widgets/app_settings_card.dart';

import '../widgets/profile_header.dart';
import '../widgets/profile_info_card.dart';

class StudentProfilePage extends StatefulWidget {
  const StudentProfilePage({super.key});

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  late Future<Student?> _studentFuture;

  @override
  void initState() {
    super.initState();
    _loadStudent();
  }

  void _loadStudent() {
    _studentFuture = StudentRepository.getCurrentStudent();
  }

  Future<void> _refreshStudent() async {
    setState(_loadStudent);
    await _studentFuture;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mon profil"),
        actions: [
          const HomeButton(),
          IconButton(
            tooltip: "Actualiser",
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refreshStudent,
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<Student?>(
          future: _studentFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              );
            }

            if (snapshot.hasError) {
              return _buildMessage(
                icon: Icons.error_outline_rounded,
                title: "Impossible de charger le profil",
                message:
                    "Une erreur est survenue lors de la récupération de vos informations.",
                actionLabel: "Réessayer",
                onAction: _refreshStudent,
              );
            }

            final student = snapshot.data;

            if (student == null) {
              return _buildMessage(
                icon: Icons.person_off_outlined,
                title: "Profil introuvable",
                message:
                    "Aucune information d'étudiant n'est associée à votre compte. Veuillez contacter l'administration.",
              );
            }

            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _refreshStudent,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 80 : 24,
                  vertical: 30,
                ),
                child: Column(
                  children: [
                    ProfileHeader(
                      student: student,
                    )
                        .animate()
                        .fadeIn()
                        .slideY(begin: .15),

                    const SizedBox(height: 24),

                    ProfileInfoCard(
                      student: student,
                    )
                        .animate()
                        .fadeIn(delay: 150.ms)
                        .slideY(begin: .15),

                    const SizedBox(height: 24),

                    AppSettingsCard(
                      onChangePassword: () =>
                          showChangePasswordDialog(context),
                    )
                        .animate()
                        .fadeIn(delay: 300.ms)
                        .slideY(begin: .15),

                    const SizedBox(height: 24),

                    const AppLogoutCard()
                        .animate()
                        .fadeIn(delay: 450.ms)
                        .slideY(begin: .15),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMessage({
    required IconData icon,
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: AppColors.primary,
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(actionLabel),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
