import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/admin_context_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../shared/widgets/app_settings_card.dart';
import '../../../../shared/widgets/change_password_dialog.dart';
import '../../../../shared/widgets/module_tile_grid.dart';

/// Espace de l'administrateur central (distinct de l'espace facultaire).
/// Le statut central est confirmé par `is_central_admin()`.
class CentralDashboardPage extends StatefulWidget {
  const CentralDashboardPage({super.key});

  @override
  State<CentralDashboardPage> createState() => _CentralDashboardPageState();
}

class _CentralDashboardPageState extends State<CentralDashboardPage> {
  final AdminContextService _service = AdminContextService();

  AdminContext? _adminContext;
  Map<String, int>? _stats;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final adminContext = await _service.load();

      if (!adminContext.isCentral) {
        throw Exception('Espace réservé à l’administrateur central.');
      }

      final stats = await _service.loadCentralStats();

      if (!mounted) return;

      setState(() {
        _adminContext = adminContext;
        _stats = stats;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _logout() async {
    await AuthService.signOut();
    if (mounted) context.go('/login');
  }

  void _openProfile() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
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
                        Icons.account_balance_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    title: Text(
                      _adminContext?.fullName.isNotEmpty == true
                          ? _adminContext!.fullName
                          : 'Administrateur central',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(_adminContext?.email ?? ''),
                  ),
                  const SizedBox(height: 8),
                  AppSettingsCard(
                    onChangePassword: () =>
                        showChangePasswordDialog(sheetContext),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tiles = [
      ModuleTileData(
        icon: Icons.account_tree_rounded,
        label: 'Facultés et départements',
        onTap: () => context.push('/central/faculties'),
      ),
      ModuleTileData(
        icon: Icons.workspace_premium_rounded,
        label: 'Promotions des facultés',
        onTap: () => context.push('/central/faculties?tab=promotions'),
      ),
      ModuleTileData(
        icon: Icons.calendar_month_rounded,
        label: 'Années académiques',
        onTap: () => context.push('/admin/academic-years'),
      ),
      ModuleTileData(
        icon: Icons.meeting_room_rounded,
        label: 'Salles',
        onTap: () => context.push('/admin/rooms'),
      ),
      ModuleTileData(
        icon: Icons.badge_rounded,
        label: 'Étudiants et cartes',
        onTap: () => context.push('/central/students'),
      ),
      ModuleTileData(
        icon: Icons.admin_panel_settings_rounded,
        label: 'Administrateurs facultaires',
        onTap: () => context.push('/central/admins'),
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text(
          'SmartPass — Administration centrale',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Mon Profil',
            onPressed: _openProfile,
            icon: const Icon(Icons.person_outline_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 40),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _sectionTitle('Vue d’ensemble'),
                    const SizedBox(height: 12),
                    _buildStats(),
                    const SizedBox(height: 28),
                    _sectionTitle('Modules de gestion'),
                    const SizedBox(height: 12),
                    ModuleTileGrid(tiles: tiles),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      );

  Widget _buildHeader() {
    return Container(
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
            'ADMINISTRATION CENTRALE — ULPGL',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _adminContext?.fullName.isNotEmpty == true
                ? 'Bienvenue, ${_adminContext!.fullName}'
                : 'Bienvenue',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Structure académique, années, salles, étudiants et cartes, '
            'administrateurs facultaires.',
            style: TextStyle(color: Colors.white70, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          _error!,
          style: const TextStyle(color: AppColors.error),
        ),
      );
    }

    final stats = _stats ?? const {};
    final items = <(String, String, IconData)>[
      ('Facultés', 'faculties', Icons.account_balance_rounded),
      ('Départements actifs', 'departments', Icons.account_tree_rounded),
      ('Étudiants', 'students', Icons.school_rounded),
      ('Admins facultaires', 'faculty_admins', Icons.admin_panel_settings_rounded),
      ('Salles actives', 'rooms', Icons.meeting_room_rounded),
      ('Années académiques', 'academic_years', Icons.calendar_month_rounded),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 600 ? 2 : 3;

        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: columns == 2 ? 1.6 : 1.9,
          children: items.map((item) {
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(item.$3, color: AppColors.primary, size: 22),
                  Text(
                    '${stats[item.$2] ?? 0}',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    item.$1,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
