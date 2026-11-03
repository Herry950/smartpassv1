import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/assistant_management_service.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() =>
      _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _selectedIndex = 0;
  bool _isTestingAdmin = false;

  Future<void> _testAdminAuthorization() async {
    if (_isTestingAdmin) return;

    setState(() => _isTestingAdmin = true);

    try {
      final result =
          await AssistantManagementService().testAdminAuthorization();

      if (!mounted) return;

      final isAuthorized =
          result['success'] == true &&
          result['code'] == 'ADMIN_AUTHORIZED';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor:
              isAuthorized ? Colors.green : AppColors.error,
          content: Text(
            isAuthorized
                ? 'Autorisation Admin confirmée par Supabase.'
                : 'Les droits administrateur n’ont pas été confirmés.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text('Échec du test : $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isTestingAdmin = false);
      }
    }
  }

  final List<_AdminModule> _modules = const [
    _AdminModule(
      title: 'Assistants',
      description: 'Créer et gérer les comptes assistants',
      icon: Icons.support_agent_rounded,
    ),
    _AdminModule(
      title: 'Affectations',
      description: 'Gérer les salles et les sessions',
      icon: Icons.assignment_ind_rounded,
    ),
    _AdminModule(
      title: 'Années académiques',
      description: 'Ouvrir et clôturer les années',
      icon: Icons.calendar_month_rounded,
    ),
    _AdminModule(
      title: 'Étudiants et cartes',
      description: 'Consulter les étudiants et émettre les cartes',
      icon: Icons.badge_outlined,
    ),
    _AdminModule(
      title: 'Sessions d’examen',
      description: 'Créer, ouvrir et clôturer les sessions',
      icon: Icons.event_note_rounded,
    ),
    _AdminModule(
      title: 'Paiements',
      description: 'Suivre les paiements électroniques et espèces',
      icon: Icons.payments_outlined,
    ),
    _AdminModule(
      title: 'Salles et cours',
      description: 'Consulter les salles et les cours',
      icon: Icons.meeting_room_outlined,
    ),
    _AdminModule(
      title: 'Rapports et contrôle',
      description: 'Consulter les activités et les historiques',
      icon: Icons.analytics_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: isDesktop
              ? null
              : AppBar(
                  title: const Text(
                    'SmartPass Admin',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: AppColors.surface,
                  actions: [
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.notifications_none_rounded,
                      ),
                    ),
                  ],
                ),
          drawer: isDesktop
              ? null
              : Drawer(
                  child: SafeArea(
                    child: _buildNavigation(),
                  ),
                ),
          body: Row(
            children: [
              if (isDesktop)
                SizedBox(
                  width: 260,
                  child: _buildNavigation(),
                ),
              Expanded(
                child: _buildDashboard(isDesktop),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavigation() {
    return Container(
      color: AppColors.surface,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: 500,
          ),
          child: IntrinsicHeight(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'SmartPass',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                const Text(
                  'ESPACE ADMINISTRATEUR',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                _navigationItem(
                  icon: Icons.dashboard_rounded,
                  label: 'Tableau de bord',
                  index: 0,
                ),
                const SizedBox(height: 8),
                const Text(
                  'GESTION',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                ...List.generate(_modules.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: _navigationItem(
                      icon: _modules[index].icon,
                      label: _modules[index].title,
                      index: index + 1,
                    ),
                  );
                }),
                const Spacer(),
                const Divider(color: AppColors.border),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.logout_rounded,
                    color: AppColors.error,
                  ),
                  title: const Text(
                    'Déconnexion',
                    style: TextStyle(color: AppColors.error),
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'La déconnexion sera reliée à AuthService.',
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navigationItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final selected = _selectedIndex == index;

    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.10)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() => _selectedIndex = index);

          final scaffold = Scaffold.maybeOf(context);

          if (scaffold?.isDrawerOpen ?? false) {
            Navigator.pop(context);
          }

          // Assistants : ouverture de la page de gestion.
          if (index == 1) {
            context.push('/admin/assistants');
            return;
          }

          if (index != 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '$label : module à connecter prochainement.',
                ),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: selected
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? AppColors.primary
                        : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard(bool isDesktop) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 32 : 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tableau de bord',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Vue générale de la gestion universitaire.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isDesktop)
                IconButton(
                  tooltip: 'Notifications',
                  onPressed: () {},
                  icon: const Icon(
                    Icons.notifications_none_rounded,
                    size: 26,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed:
                  _isTestingAdmin ? null : _testAdminAuthorization,
              icon: _isTestingAdmin
                  ? const SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.verified_user_outlined),
              label: Text(
                _isTestingAdmin
                    ? 'Vérification en cours...'
                    : 'Tester les droits administrateur',
              ),
            ),
          ),
          const SizedBox(height: 28),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bienvenue dans votre espace',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Administration SmartPass',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Pilotez les opérations académiques, '
                  'les paiements et le contrôle d’accès aux examens.',
                  style: TextStyle(
                    color: Colors.white,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Vue d’ensemble',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: isDesktop ? 4 : 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: isDesktop ? 1.65 : 1.25,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: const [
              _StatCard(
                title: 'Étudiants',
                value: '—',
                icon: Icons.school_outlined,
              ),
              _StatCard(
                title: 'Assistants',
                value: '—',
                icon: Icons.support_agent_rounded,
              ),
              _StatCard(
                title: 'Sessions ouvertes',
                value: '—',
                icon: Icons.event_available_rounded,
              ),
              _StatCard(
                title: 'Paiements validés',
                value: '—',
                icon: Icons.payments_outlined,
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Text(
            'Modules de gestion',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Sélectionnez un module pour accéder à ses fonctionnalités.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _modules.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isDesktop ? 3 : 1,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              mainAxisExtent: 112,
            ),
            itemBuilder: (context, index) {
              final module = _modules[index];

              return _ModuleCard(
                module: module,
                onTap: () {
                  setState(() => _selectedIndex = index + 1);

                  // La première carte est celle des Assistants.
                  if (index == 0) {
                    context.push('/admin/assistants');
                    return;
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${module.title} : module à développer.',
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: AppColors.primary, size: 23),
            Text(
              value,
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDark,
              ),
            ),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final _AdminModule module;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.module,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  module.icon,
                  color: AppColors.primary,
                  size: 25,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      module.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      module.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 15,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminModule {
  final String title;
  final String description;
  final IconData icon;

  const _AdminModule({
    required this.title,
    required this.description,
    required this.icon,
  });
}