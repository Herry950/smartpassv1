import 'package:myprojectflut/shared/widgets/home_button.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/central_admin_service.dart';

/// Gestion des administrateurs facultaires par l'administrateur central.
/// La création passe par l'Edge Function sécurisée `create-faculty-admin`
/// (invitation e-mail, clé service_role uniquement côté serveur).
class CentralAdminsPage extends StatefulWidget {
  const CentralAdminsPage({super.key});

  @override
  State<CentralAdminsPage> createState() => _CentralAdminsPageState();
}

class _CentralAdminsPageState extends State<CentralAdminsPage> {
  final CentralAdminService _service = CentralAdminService();

  bool _loading = true;
  bool _saving = false;
  String? _error;
  List<Map<String, dynamic>> _admins = [];
  List<Map<String, dynamic>> _faculties = [];

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
      final results = await Future.wait([
        _service.loadAdmins(),
        _service.loadFaculties(),
      ]);

      if (!mounted) return;

      setState(() {
        _admins = results[0];
        _faculties = results[1];
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

  void _toast(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: error ? AppColors.error : AppColors.success,
        content: Text(message),
      ),
    );
  }

  Future<void> _create() async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    String? facultyId;
    String? formError;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Nouvel administrateur facultaire'),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom complet',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Adresse e-mail',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: facultyId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Faculté administrée',
                    prefixIcon: Icon(Icons.account_balance_rounded),
                  ),
                  items: _faculties
                      .map(
                        (f) => DropdownMenuItem<String>(
                          value: f['id'] as String,
                          child: Text(f['name'].toString()),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setDialogState(() => facultyId = value),
                ),
                if (formError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    formError!,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  'Un e-mail d’invitation sera envoyé. L’administrateur '
                  'définira son mot de passe et ne pourra gérer que '
                  'cette faculté.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () {
                final email = emailController.text.trim();
                if (nameController.text.trim().isEmpty ||
                    !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email) ||
                    facultyId == null) {
                  setDialogState(
                    () => formError =
                        'Renseignez le nom, une adresse e-mail valide '
                        'et la faculté.',
                  );
                  return;
                }
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Envoyer l’invitation'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || facultyId == null) return;

    setState(() => _saving = true);

    try {
      await _service.inviteFacultyAdmin(
        fullName: nameController.text,
        email: emailController.text,
        facultyId: facultyId!,
      );
      if (!mounted) return;
      _toast('Invitation envoyée.');
      await _load();
    } catch (e) {
      if (!mounted) return;
      _toast(e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _toggle(Map<String, dynamic> admin) async {
    final active = admin['is_active'] == true;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(active ? 'Désactiver le compte' : 'Réactiver le compte'),
        content: Text(
          active
              ? '${admin['full_name']} ne pourra plus administrer sa faculté. '
                  'Les données de la faculté sont conservées.'
              : '${admin['full_name']} pourra de nouveau administrer sa faculté.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(active ? 'Désactiver' : 'Réactiver'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _saving = true);

    try {
      await _service.setFacultyAdminActive(
        adminId: admin['id'] as String,
        active: !active,
      );
      if (!mounted) return;
      _toast(active ? 'Compte désactivé.' : 'Compte réactivé.');
      await _load();
    } catch (e) {
      if (!mounted) return;
      _toast(e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          tooltip: 'Retour',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Administrateurs facultaires',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          const HomeButton(),
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loading || _saving ? null : _create,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Inviter'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.error),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                children: _admins.isEmpty
                    ? [
                        Text(
                          'Aucun administrateur enregistré.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ]
                    : _admins.map(_buildAdminTile).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminTile(Map<String, dynamic> admin) {
    final isCentral = admin['faculty_id'] == null;
    final active = admin['is_active'] == true;
    final faculty = admin['academic_faculties'];
    final facultyName = faculty is Map ? faculty['name']?.toString() : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: .12),
          child: Icon(
            isCentral
                ? Icons.account_balance_rounded
                : Icons.admin_panel_settings_rounded,
            color: AppColors.primary,
          ),
        ),
        title: Text(
          (admin['full_name'] ?? '—').toString(),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          [
            admin['email']?.toString(),
            isCentral ? 'Administration centrale' : facultyName,
            active ? 'Actif' : 'Désactivé',
          ].whereType<String>().join(' • '),
        ),
        trailing: isCentral
            ? null
            : Switch(
                value: active,
                onChanged: _saving ? null : (_) => _toggle(admin),
              ),
      ),
    );
  }
}
