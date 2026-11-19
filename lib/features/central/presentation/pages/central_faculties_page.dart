import 'package:myprojectflut/shared/widgets/home_button.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/central_admin_service.dart';

/// Structure académique globale : facultés, départements et
/// affectation des promotions de référence aux facultés.
class CentralFacultiesPage extends StatefulWidget {
  const CentralFacultiesPage({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<CentralFacultiesPage> createState() => _CentralFacultiesPageState();
}

class _CentralFacultiesPageState extends State<CentralFacultiesPage> {
  final CentralAdminService _service = CentralAdminService();

  bool _loading = true;
  bool _saving = false;
  String? _error;
  List<Map<String, dynamic>> _faculties = [];
  List<Map<String, dynamic>> _promotions = [];

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
        _service.loadFaculties(),
        _service.loadPromotions(),
      ]);

      if (!mounted) return;

      setState(() {
        _faculties = results[0];
        _promotions = results[1];
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

  Future<void> _run(Future<void> Function() action, String success) async {
    setState(() => _saving = true);
    try {
      await action();
      if (!mounted) return;
      _toast(success);
      await _load();
    } catch (e) {
      if (!mounted) return;
      _toast(e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<String?> _askText({
    required String title,
    required String label,
    String initial = '',
  }) {
    final controller = TextEditingController(text: initial);

    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 420,
          child: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(labelText: label),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) Navigator.pop(dialogContext, value);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  Future<void> _departmentDialog({
    required Map<String, dynamic> faculty,
    Map<String, dynamic>? department,
  }) async {
    final nameController = TextEditingController(
      text: department?['name']?.toString() ?? '',
    );
    int rank = (department?['minimum_promotion_rank'] as int?) ??
        (_promotions.isNotEmpty ? _promotions.first['rank'] as int : 0);

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(
            department == null
                ? 'Nouveau département — ${faculty['name']}'
                : 'Modifier le département',
          ),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Nom du département',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  initialValue: rank,
                  decoration: const InputDecoration(
                    labelText: 'Promotion minimale',
                    helperText:
                        'Le département est accessible à partir de cette promotion.',
                  ),
                  items: _promotions
                      .map(
                        (p) => DropdownMenuItem<int>(
                          value: p['rank'] as int,
                          child: Text('${p['code']} (rang ${p['rank']})'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setDialogState(() => rank = value ?? rank),
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
                if (nameController.text.trim().isNotEmpty) {
                  Navigator.pop(dialogContext, true);
                }
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );

    if (result != true) return;

    if (department == null) {
      await _run(
        () => _service.createDepartment(
          facultyId: faculty['id'] as String,
          name: nameController.text,
          minimumPromotionRank: rank,
        ),
        'Département créé.',
      );
    } else {
      await _run(
        () => _service.updateDepartment(
          departmentId: department['id'] as String,
          name: nameController.text,
          minimumPromotionRank: rank,
        ),
        'Département modifié.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: widget.initialTab.clamp(0, 1),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          leading: IconButton(
            tooltip: 'Retour',
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.maybePop(context),
          ),
          title: const Text(
            'Structure académique',
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
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Facultés et départements'),
              Tab(text: 'Promotions'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _loading || _saving
              ? null
              : () async {
                  final name = await _askText(
                    title: 'Nouvelle faculté',
                    label: 'Nom de la faculté',
                  );
                  if (name != null) {
                    await _run(
                      () => _service.createFaculty(name),
                      'Faculté créée.',
                    );
                  }
                },
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Nouvelle faculté'),
        ),
        body: _buildBody(),
      ),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AppColors.error,
              ),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    return TabBarView(
      children: [
        _buildFacultiesTab(),
        _buildPromotionsTab(),
      ],
    );
  }

  Widget _wrapList(List<Widget> children) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFacultiesTab() {
    if (_faculties.isEmpty) {
      return _wrapList([
        Text(
          'Aucune faculté enregistrée.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ]);
    }

    return _wrapList(
      _faculties.map((faculty) {
        final departments = List<Map<String, dynamic>>.from(
          faculty['academic_departments'] as List? ?? const [],
        )..sort(
            (a, b) => a['name'].toString().compareTo(b['name'].toString()),
          );

        return Card(
          margin: const EdgeInsets.only(bottom: 14),
          child: ExpansionTile(
            shape: const Border(),
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withValues(alpha: .12),
              child: Icon(
                Icons.account_balance_rounded,
                color: AppColors.primary,
              ),
            ),
            title: Text(
              faculty['name'].toString(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${departments.length} département(s)'),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            children: [
              Row(
                children: [
                  TextButton.icon(
                    onPressed: _saving
                        ? null
                        : () async {
                            final name = await _askText(
                              title: 'Renommer la faculté',
                              label: 'Nom de la faculté',
                              initial: faculty['name'].toString(),
                            );
                            if (name != null) {
                              await _run(
                                () => _service.renameFaculty(
                                  faculty['id'] as String,
                                  name,
                                ),
                                'Faculté renommée.',
                              );
                            }
                          },
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    label: const Text('Renommer'),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _saving
                        ? null
                        : () => _departmentDialog(faculty: faculty),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Département'),
                  ),
                ],
              ),
              if (departments.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    'Aucun département actif.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ...departments.map((department) {
                final rank = department['minimum_promotion_rank'];
                final promo = _promotions.firstWhere(
                  (p) => p['rank'] == rank,
                  orElse: () => {'code': 'rang $rank'},
                );

                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.account_tree_outlined),
                  title: Text(department['name'].toString()),
                  subtitle: Text('À partir de ${promo['code']}'),
                  trailing: IconButton(
                    tooltip: 'Modifier',
                    onPressed: _saving
                        ? null
                        : () => _departmentDialog(
                              faculty: faculty,
                              department: department,
                            ),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                );
              }),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPromotionsTab() {
    return _wrapList([
      Text(
        'Cochez les promotions ouvertes dans chaque faculté. '
        'Seules ces promotions sont proposées à l’inscription, aux cours '
        'et à la programmation des examens de la faculté.',
        style: TextStyle(color: AppColors.textSecondary),
      ),
      const SizedBox(height: 16),
      ..._faculties.map((faculty) {
        final assigned = (faculty['faculty_promotions'] as List? ?? const [])
            .whereType<Map>()
            .map((row) => row['promotion_code'].toString())
            .toSet();

        return Card(
          margin: const EdgeInsets.only(bottom: 14),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  faculty['name'].toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _promotions.map((promotion) {
                    final code = promotion['code'].toString();
                    final selected = assigned.contains(code);

                    return FilterChip(
                      label: Text(code),
                      selected: selected,
                      onSelected: _saving
                          ? null
                          : (value) async {
                              if (!value) {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (dialogContext) => AlertDialog(
                                    title: Text('Retirer $code ?'),
                                    content: Text(
                                      'Les étudiants de ${faculty['name']} '
                                      'inscrits en $code ne verront plus '
                                      'leurs examens et ne pourront plus '
                                      'payer leurs sessions tant que la '
                                      'promotion n’est pas réaffectée.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(
                                          dialogContext,
                                          false,
                                        ),
                                        child: const Text('Annuler'),
                                      ),
                                      FilledButton(
                                        style: FilledButton.styleFrom(
                                          backgroundColor: AppColors.error,
                                        ),
                                        onPressed: () => Navigator.pop(
                                          dialogContext,
                                          true,
                                        ),
                                        child: const Text('Retirer'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirmed != true) return;
                              }

                              await _run(
                                () => _service.setFacultyPromotion(
                                  facultyId: faculty['id'] as String,
                                  promotionCode: code,
                                  assigned: value,
                                ),
                                value
                                    ? 'Promotion $code affectée.'
                                    : 'Promotion $code retirée.',
                              );
                            },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      }),
    ]);
  }
}
