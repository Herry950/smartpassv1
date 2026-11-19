
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/admin_context_service.dart';
import '../../../../core/services/assistant_management_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/reconciliation_service.dart';
import '../../../../shared/widgets/app_settings_card.dart';
import '../../../../shared/widgets/change_password_dialog.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() =>
      _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _selectedIndex = 0;
  bool _isTestingAdmin = false;

  final AdminContextService _contextService = AdminContextService();
  AdminContext? _adminContext;
  Map<String, int>? _stats;
  String? _statsError;

  /// Dossiers de double paiement nécessitant une action (null : module
  /// indisponible, par exemple non encore déployé).
  int? _reconciliationsToHandle;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _statsError = null);

    try {
      final adminContext = await _contextService.load();
      final stats = await _contextService.loadFacultyStats(adminContext);

      if (!mounted) return;

      setState(() {
        _adminContext = adminContext;
        _stats = stats;
      });

      _loadReconciliationCount();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _statsError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _loadReconciliationCount() async {
    try {
      final data = await ReconciliationService().list();
      const toHandle = {
        'suspected',
        'confirmed',
        'awaiting_funds',
        'refund_contested',
      };
      final count = (data['items'] as List? ?? const [])
          .whereType<Map>()
          .where((item) => toHandle.contains(item['status']))
          .length;
      if (mounted) setState(() => _reconciliationsToHandle = count);
    } catch (_) {
      if (mounted) setState(() => _reconciliationsToHandle = null);
    }
  }

  String _statValue(String key) {
    if (_statsError != null) return '!';
    final value = _stats?[key];
    return value == null ? '…' : value.toString();
  }

  Future<void> _logout() async {
    try {
      await AuthService.signOut();
      if (mounted) context.go('/login');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la déconnexion : $e')),
      );
    }
  }

  void _openProfile() {
    final adminContext = _adminContext;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor:
                            AppColors.primary.withValues(alpha: .12),
                        child: Icon(
                          Icons.admin_panel_settings_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                      title: Text(
                        adminContext?.fullName.isNotEmpty == true
                            ? adminContext!.fullName
                            : 'Administrateur facultaire',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        [
                          adminContext?.email,
                          adminContext?.facultyName,
                        ].whereType<String>().join(' • '),
                      ),
                    ),
                    const SizedBox(height: 8),
                    AppSettingsCard(
                      onChangePassword: () =>
                          showChangePasswordDialog(sheetContext),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          _logout();
                        },
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text('Déconnexion'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _openModule(int moduleIndex) {
    setState(() => _selectedIndex = moduleIndex + 1);
    context.push(_modules[moduleIndex].route);
  }

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
              isAuthorized ? AppColors.success : AppColors.error,
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

  // Modules réservés à l'administration facultaire.
  final List<_AdminModule> _modules = const [
    _AdminModule(
      title: 'Cours et Évaluations',
      description: 'Gérer les cours et les évaluations de la faculté',
      icon: Icons.menu_book_rounded,
      route: '/admin/courses',
    ),
    _AdminModule(
      title: 'Sessions d’Évaluation',
      description: 'Créer, ouvrir et clôturer les sessions de la faculté',
      icon: Icons.event_note_rounded,
      route: '/admin/sessions',
    ),
    _AdminModule(
      title: 'Assistants',
      description: 'Créer et gérer les assistants de la faculté',
      icon: Icons.support_agent_rounded,
      route: '/admin/assistants',
    ),
    _AdminModule(
      title: 'Remises des paiements',
      description:
          'Suivre les espèces collectées par les assistants et confirmer les remises',
      icon: Icons.account_balance_wallet_outlined,
      route: '/admin/cash-remittances',
    ),
    _AdminModule(
      title: 'Affectations',
      description: 'Affecter les assistants aux sessions d’évaluation de la faculté',
      icon: Icons.assignment_ind_rounded,
      route: '/admin/assignments',
    ),
    _AdminModule(
      title: 'Rapports et Contrôle',
      description: 'Consulter les activités et les historiques de la faculté',
      icon: Icons.analytics_outlined,
      route: '/admin/reports',
    ),
    _AdminModule(
      title: 'Doubles paiements',
      description:
          'Traiter les encaissements en trop et les remboursements manuels',
      icon: Icons.currency_exchange_rounded,
      route: '/admin/reconciliations',
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
                    'SmartPass Faculté',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: AppColors.surface,
                  actions: [
                    IconButton(
                      tooltip: 'Actualiser',
                      onPressed: _loadStats,
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                    IconButton(
                      tooltip: 'Mon Profil',
                      onPressed: _openProfile,
                      icon: const Icon(Icons.person_outline_rounded),
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
                    Expanded(
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
                Text(
                  'ESPACE ADMINISTRATEUR FACULTAIRE',
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
                Text(
                  'GESTION DE LA FACULTÉ',
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
                Divider(color: AppColors.border),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.person_outline_rounded,
                    color: AppColors.textSecondary,
                  ),
                  title: const Text('Mon Profil'),
                  onTap: _openProfile,
                ),
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
                  onTap: _logout,
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

          if (index > 0 && index <= _modules.length) {
            context.push(_modules[index - 1].route);
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
                    Text(
                      'Espace de gestion et de suivi de votre faculté.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isDesktop)
                IconButton(
                  tooltip: 'Actualiser',
                  onPressed: _loadStats,
                  icon: const Icon(
                    Icons.refresh_rounded,
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
                  'Administration facultaire SmartPass',
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
                  'Gérez les activités académiques, les assistants, '
                  'les paiements et le contrôle d’accès aux examens '
                  'dans le périmètre de votre faculté.',
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
            children: [
              _StatCard(
                title: 'Étudiants de la faculté',
                value: _statValue('students'),
                icon: Icons.school_outlined,
              ),
              _StatCard(
                title: 'Assistants actifs',
                value: _statValue('active_assistants'),
                icon: Icons.support_agent_rounded,
              ),
              _StatCard(
                title: 'Sessions ouvertes aux paiements',
                value: _statValue('open_sessions'),
                icon: Icons.event_available_rounded,
              ),
              _StatCard(
                title: 'Paiements validés',
                value: _statValue('validated_payments'),
                icon: Icons.payments_outlined,
              ),
              _StatCard(
                title: 'Doubles paiements à traiter',
                value: _reconciliationsToHandle?.toString() ?? '—',
                icon: Icons.currency_exchange_rounded,
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
          Text(
            'Sélectionnez un module pour gérer les activités de votre faculté.',
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
                onTap: () => _openModule(index),
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
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDark,
              ),
            ),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
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
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
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
  final String route;

  const _AdminModule({
    required this.title,
    required this.description,
    required this.icon,
    required this.route,
  });
}
