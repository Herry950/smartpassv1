
import 'package:flutter/material.dart';

import 'package:myprojectflut/app/theme/app_colors.dart';
import 'package:myprojectflut/core/services/auth_service.dart';

class AssistantHeader extends StatefulWidget {
  final String assistantName;

  const AssistantHeader({
    super.key,
    this.assistantName = 'Assistant',
  });

  @override
  State<AssistantHeader> createState() => _AssistantHeaderState();
}

class _AssistantHeaderState extends State<AssistantHeader> {
  late Future<Map<String, dynamic>?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    _profileFuture = AuthService.getAssistantProfile();
  }

  void _retryLoading() {
    setState(() {
      _loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _profileFuture,
      builder: (context, snapshot) {
        final profile = snapshot.data;

        final fullName =
            profile?['full_name']?.toString().trim();

        final displayName =
            fullName != null && fullName.isNotEmpty
                ? fullName
                : widget.assistantName;

        final firstName = displayName.split(' ').first;

        final employeeNumber =
            profile?['employee_number']?.toString();

        final isActive = profile?['is_active'] == true;

        final facultyData = profile?['faculty'];

        final facultyName = facultyData is Map
            ? facultyData['name']?.toString()
            : null;

        final facultyIsActive = facultyData is Map
            ? facultyData['is_active'] == true
            : null;

        final isLoading =
            snapshot.connectionState == ConnectionState.waiting;

        final hasError = snapshot.hasError;

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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 560;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          isLoading
                              ? 'Bonjour 👋'
                              : 'Bonjour $firstName 👋',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isCompact ? 24 : 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        const Text(
                          "Contrôle d'accès aux examens",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 15,
                          ),
                        ),

                        const SizedBox(height: 20),

                        if (isLoading)
                          _buildInfoRow(
                            Icons.sync_rounded,
                            'Chargement de votre profil...',
                          )
                        else if (hasError)
                          _buildErrorMessage()
                        else if (profile == null)
                          _buildInfoRow(
                            Icons.person_off_rounded,
                            'Profil assistant introuvable.',
                          )
                        else ...[
                          _buildInfoRow(
                            Icons.person_rounded,
                            displayName,
                          ),

                          if (employeeNumber != null &&
                              employeeNumber.trim().isNotEmpty) ...[
                            const SizedBox(height: 10),
                            _buildInfoRow(
                              Icons.badge_rounded,
                              'Matricule professionnel : $employeeNumber',
                            ),
                          ],

                          const SizedBox(height: 10),

                          _buildInfoRow(
                            Icons.account_balance_rounded,
                            facultyName ?? 'Faculté non renseignée',
                          ),

                          const SizedBox(height: 16),

                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildStatusBadge(
                                label: isActive
                                    ? 'COMPTE ACTIF'
                                    : 'COMPTE DÉSACTIVÉ',
                                isPositive: isActive,
                              ),

                              if (facultyIsActive != null)
                                _buildStatusBadge(
                                  label: facultyIsActive
                                      ? 'FACULTÉ ACTIVE'
                                      : 'FACULTÉ INACTIVE',
                                  isPositive: facultyIsActive,
                                ),
                            ],
                          ),
                        ],

                        const SizedBox(height: 20),

                        const Row(
                          children: [
                            Icon(
                              Icons.verified_user_rounded,
                              color: Colors.white70,
                              size: 18,
                            ),
                            SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Scanner • Vérifier • Autoriser',
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

                  if (!isCompact) ...[
                    const SizedBox(width: 20),

                    CircleAvatar(
                      radius: 38,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.qr_code_scanner_rounded,
                        size: 40,
                        color: AppColors.primary,
                      ),
                    ),
                  ],

                  if (hasError)
                    IconButton(
                      onPressed: _retryLoading,
                      tooltip: 'Réessayer',
                      icon: const Icon(
                        Icons.refresh_rounded,
                        color: Colors.white,
                      ),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: Colors.white70,
          size: 19,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge({
    required String label,
    required bool isPositive,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .15),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withValues(alpha: .35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive
                ? Icons.check_circle_rounded
                : Icons.cancel_rounded,
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: .3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.cloud_off_rounded,
          color: Colors.white,
          size: 19,
        ),
        const SizedBox(width: 9),
        const Expanded(
          child: Text(
            'Impossible de charger les informations du profil.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
