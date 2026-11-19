import 'package:myprojectflut/shared/widgets/home_button.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/admin_context_service.dart';
import '../../../../core/services/assistant_assignment_service.dart';

/// Affectation des assistants aux sessions d'évaluation de la faculté.
class AssistantAssignmentPage extends StatefulWidget {
  const AssistantAssignmentPage({super.key});

  @override
  State<AssistantAssignmentPage> createState() =>
      _AssistantAssignmentPageState();
}

class _AssistantAssignmentPageState extends State<AssistantAssignmentPage> {
  final _service = AssistantAssignmentService();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  AdminContext? _context;
  List<Map<String, dynamic>> _sessions = [];
  List<Map<String, dynamic>> _assistants = [];
  List<Map<String, dynamic>> _assignments = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _service.loadData();

      if (!mounted) return;

      setState(() {
        _context = data['context'] as AdminContext;
        _sessions = data['sessions'] as List<Map<String, dynamic>>;
        _assistants = data['assistants'] as List<Map<String, dynamic>>;
        _assignments = data['assignments'] as List<Map<String, dynamic>>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _showMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: error ? AppColors.error : AppColors.success,
        content: Text(message),
      ),
    );
  }

  String _sessionLabel(Map<String, dynamic>? session) {
    if (session == null) return 'Session inconnue';

    final year = session['academic_years'];
    final yearName = year is Map ? year['name']?.toString() : null;

    return [
      session['session_name']?.toString() ?? 'Session',
      session['semester']?.toString(),
      yearName,
    ].whereType<String>().where((v) => v.isNotEmpty).join(' • ');
  }

  Future<void> _openAssignDialog() async {
    final activeAssistants =
        _assistants.where((a) => a['is_active'] == true).toList();

    if (_sessions.isEmpty) {
      _showMessage(
        'Créez d’abord une session d’évaluation pour votre faculté.',
        error: true,
      );
      return;
    }

    if (activeAssistants.isEmpty) {
      _showMessage(
        'Aucun assistant actif. Un compte assistant actif est requis.',
        error: true,
      );
      return;
    }

    String? sessionId = _sessions.first['id'] as String;
    String? assistantId;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final alreadyAssigned = _assignments
                .where((a) => a['exam_session_id'] == sessionId)
                .map((a) => a['assistant_id'])
                .toSet();

            final available = activeAssistants
                .where((a) => !alreadyAssigned.contains(a['id']))
                .toList();

            if (assistantId != null &&
                !available.any((a) => a['id'] == assistantId)) {
              assistantId = null;
            }

            return AlertDialog(
              title: const Text('Nouvelle affectation'),
              content: SizedBox(
                width: 460,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: sessionId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Session d’évaluation',
                        prefixIcon: Icon(Icons.event_note_rounded),
                      ),
                      items: _sessions
                          .map(
                            (s) => DropdownMenuItem<String>(
                              value: s['id'] as String,
                              child: Text(
                                _sessionLabel(s),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setDialogState(() => sessionId = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    if (available.isEmpty)
                      Text(
                        'Tous les assistants actifs sont déjà affectés '
                        'à cette session.',
                        style: TextStyle(color: AppColors.textSecondary),
                      )
                    else
                      DropdownButtonFormField<String>(
                        initialValue: assistantId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Assistant',
                          prefixIcon: Icon(Icons.support_agent_rounded),
                        ),
                        items: available
                            .map(
                              (a) => DropdownMenuItem<String>(
                                value: a['id'] as String,
                                child: Text(
                                  '${a['full_name']} — ${a['email'] ?? ''}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setDialogState(() => assistantId = value);
                        },
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
                  onPressed: sessionId == null || assistantId == null
                      ? null
                      : () => Navigator.pop(dialogContext, true),
                  child: const Text('Affecter'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true ||
        sessionId == null ||
        assistantId == null ||
        _context == null) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _service.assign(
        adminId: _context!.id,
        assistantId: assistantId!,
        examSessionId: sessionId!,
      );

      if (!mounted) return;

      _showMessage('Assistant affecté avec succès.');
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      _showMessage(
        e.toString().replaceFirst('Exception: ', ''),
        error: true,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _removeAssignment(Map<String, dynamic> assignment) async {
    final assistant = assignment['assistants'];
    final name = assistant is Map ? assistant['full_name'] : 'cet assistant';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Retirer l’affectation'),
        content: Text(
          'Retirer $name de la session '
          '« ${_sessionLabel(assignment['exam_sessions'] as Map<String, dynamic>?)} » ?\n\n'
          'L’assistant ne pourra plus contrôler cette session. '
          'Les paiements déjà validés et leurs remises ne sont pas modifiés.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSaving = true);

    try {
      await _service.remove(assignment['id'] as String);

      if (!mounted) return;

      _showMessage('Affectation retirée.');
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      _showMessage(
        e.toString().replaceFirst('Exception: ', ''),
        error: true,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Affectations des assistants',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          tooltip: 'Retour',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.maybePop(context),
        ),
        actions: [
          const HomeButton(),
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _isLoading ? null : _loadData,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading || _isSaving || _error != null
            ? null
            : _openAssignDialog,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: _isSaving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Affecter'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
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
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 100),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  if (_assignments.isEmpty)
                    _buildEmpty()
                  else
                    ..._sessions.map(_buildSessionGroup),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            (_context?.facultyName ?? 'Faculté').toUpperCase(),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${_assignments.length} affectation(s)',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${_sessions.length} session(s) • '
            '${_assistants.where((a) => a['is_active'] == true).length} '
            'assistant(s) actif(s)',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(
            Icons.assignment_ind_outlined,
            size: 52,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 12),
          Text(
            'Aucune affectation pour le moment.',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Affectez un assistant actif à une session pour qu’il puisse '
            'vérifier les étudiants, les reçus et valider les paiements '
            'en espèces.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionGroup(Map<String, dynamic> session) {
    final items = _assignments
        .where((a) => a['exam_session_id'] == session['id'])
        .toList();

    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event_note_rounded, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _sessionLabel(session),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (session['payment_open'] == true)
                const _Badge(
                  label: 'Paiements ouverts',
                  color: AppColors.success,
                ),
            ],
          ),
          const SizedBox(height: 8),
          ...items.map((assignment) {
            final assistant = assignment['assistants'];
            final name = assistant is Map
                ? assistant['full_name']?.toString() ?? '—'
                : '—';
            final email =
                assistant is Map ? assistant['email']?.toString() ?? '' : '';
            final active = assistant is Map && assistant['is_active'] == true;

            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: .12),
                child: Icon(
                  Icons.support_agent_rounded,
                  color: AppColors.primary,
                ),
              ),
              title: Text(name),
              subtitle: Text(
                active ? email : '$email • Compte désactivé',
              ),
              trailing: IconButton(
                tooltip: 'Retirer l’affectation',
                onPressed:
                    _isSaving ? null : () => _removeAssignment(assignment),
                icon: const Icon(
                  Icons.person_remove_alt_1_rounded,
                  color: AppColors.error,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
