import 'package:myprojectflut/shared/widgets/home_button.dart';

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/academic_year_service.dart';

class AcademicYearManagementPage extends StatefulWidget {
  const AcademicYearManagementPage({super.key});

  @override
  State<AcademicYearManagementPage> createState() =>
      _AcademicYearManagementPageState();
}

class _AcademicYearManagementPageState
    extends State<AcademicYearManagementPage> {
  final AcademicYearService _service = AcademicYearService();

  List<Map<String, dynamic>> _years = [];

  bool _isLoading = true;
  bool _isSaving = false;

  int get _totalYears => _years.length;

  int get _currentYears =>
      _years.where((year) => year['is_current'] == true).length;

  int get _historicalYears => _totalYears - _currentYears;

  @override
  void initState() {
    super.initState();
    _loadYears();
  }

  Future<void> _loadYears() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final result = await _service.getAcademicYears();

      if (!mounted) return;

      setState(() {
        _years = result;
        _isLoading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('Erreur chargement années académiques : $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() => _isLoading = false);

      _showMessage(
        'Impossible de charger les années académiques.',
        details: error.toString(),
      );
    }
  }

  void _showMessage(String message, {String? details}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            details == null ? message : '$message\n$details',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _openCreateDialog() async {
    if (_isSaving) return;

    final data = await showDialog<_AcademicYearFormData>(
      context: context,
      builder: (_) => const _AcademicYearFormDialog(),
    );

    if (data == null || !mounted) return;

    await _createYear(data);
  }

  Future<void> _createYear(_AcademicYearFormData data) async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      await _service.createAcademicYear(
        name: data.name,
        startDate: data.startDate,
        endDate: data.endDate,
      );

      if (!mounted) return;

      _showMessage('Année académique créée avec succès.');

      await _loadYears();
    } catch (error, stackTrace) {
      debugPrint('Erreur création année académique : $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      _showMessage(
        'Impossible de créer cette année académique.',
        details: error.toString(),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _setCurrentYear(
    Map<String, dynamic> year,
  ) async {
    if (_isSaving || year['is_current'] == true) return;

    final yearId = year['id']?.toString();

    if (yearId == null || yearId.isEmpty) return;

    final yearName = year['name']?.toString() ?? '';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Changer l’année courante ?'),
        content: Text(
          'Voulez-vous définir $yearName comme année académique '
          'courante ?\n\n'
          'L’année courante actuelle sera remplacée. '
          'Les données historiques seront conservées.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isSaving = true);

    try {
      await _service.setCurrentAcademicYear(yearId);

      if (!mounted) return;

      _showMessage('$yearName est maintenant l’année courante.');

      await _loadYears();
    } catch (error, stackTrace) {
      debugPrint('Erreur changement année courante : $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      _showMessage(
        'Impossible de changer l’année courante.',
        details: error.toString(),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String _formatDate(dynamic value) {
    if (value == null) return 'Non renseignée';

    final date = DateTime.tryParse(value.toString());

    if (date == null) return value.toString();

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Années académiques',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        elevation: 0,
        actions: [
          const HomeButton(),
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _isLoading || _isSaving ? null : _loadYears,
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving ? null : _openCreateDialog,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle année'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadYears,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            isDesktop ? 32 : 16,
            20,
            isDesktop ? 32 : 16,
            100,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1150),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildIntroduction(),
                  const SizedBox(height: 24),
                  _buildStatistics(),
                  const SizedBox(height: 30),
                  _buildYearList(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIntroduction() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'GESTION ACADÉMIQUE',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Années académiques',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Organisez les périodes académiques, définissez l’année '
          'opérationnelle et conservez l’historique des activités.',
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildStatistics() {
    final cards = [
      _YearStat(
        label: 'Total des années',
        value: _totalYears.toString(),
        icon: Icons.calendar_month_rounded,
      ),
      _YearStat(
        label: 'Année courante',
        value: _currentYears.toString(),
        icon: Icons.event_available_rounded,
      ),
      _YearStat(
        label: 'Années historiques',
        value: _historicalYears.toString(),
        icon: Icons.history_rounded,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 700 ? 3 : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            mainAxisExtent: 100,
          ),
          itemBuilder: (context, index) {
            final data = cards[index];

            return Container(
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Theme.of(context)
                      .dividerColor
                      .withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      data.icon,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.value,
                          style: const TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          data.label,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildYearList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Historique des années',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'L’année courante est utilisée comme référence pour '
          'les nouvelles opérations académiques.',
          style: TextStyle(
            fontSize: 12,
            height: 1.4,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        if (_years.isEmpty)
          _buildEmptyState()
        else
          ..._years.map(_buildYearCard),
      ],
    );
  }

  Widget _buildYearCard(Map<String, dynamic> year) {
    final isCurrent = year['is_current'] == true;
    final name = year['name']?.toString() ?? 'Année sans nom';

    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isCurrent
              ? AppColors.primary.withValues(alpha: 0.55)
              : Theme.of(context).dividerColor.withValues(alpha: 0.35),
          width: isCurrent ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.calendar_month_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (isCurrent) _buildCurrentBadge(),
            ],
          ),
          const SizedBox(height: 17),
          _buildDateRow(
            Icons.calendar_today_outlined,
            'Début',
            _formatDate(year['start_date']),
          ),
          const SizedBox(height: 9),
          _buildDateRow(
            Icons.event_outlined,
            'Fin',
            _formatDate(year['end_date']),
          ),
          if (!isCurrent) ...[
            const SizedBox(height: 15),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: _isSaving
                    ? null
                    : () => _setCurrentYear(year),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.4),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(
                  Icons.check_circle_outline,
                  size: 17,
                ),
                label: const Text('Définir comme année courante'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCurrentBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'COURANTE',
        style: TextStyle(
          color: AppColors.primary,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildDateRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 9),
        Text(
          '$label : ',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 40,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.calendar_month_outlined,
            size: 46,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 13),
          const Text(
            'Aucune année académique',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Créez une année académique pour commencer.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _YearStat {
  const _YearStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;
}

class _AcademicYearFormData {
  const _AcademicYearFormData({
    required this.name,
    required this.startDate,
    required this.endDate,
  });

  final String name;
  final DateTime startDate;
  final DateTime endDate;
}

class _AcademicYearFormDialog extends StatefulWidget {
  const _AcademicYearFormDialog();

  @override
  State<_AcademicYearFormDialog> createState() =>
      _AcademicYearFormDialogState();
}

class _AcademicYearFormDialogState
    extends State<_AcademicYearFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Choisir une date';

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initialDate = isStart
        ? _startDate ?? DateTime.now()
        : _endDate ?? _startDate ?? DateTime.now();

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: isStart
          ? 'Date de début de l’année'
          : 'Date de fin de l’année',
      cancelText: 'Annuler',
      confirmText: 'Confirmer',
    );

    if (selectedDate == null || !mounted) return;

    setState(() {
      if (isStart) {
        _startDate = selectedDate;

        if (_endDate != null &&
            !_startDate!.isBefore(_endDate!)) {
          _endDate = null;
        }
      } else {
        _endDate = selectedDate;
      }
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sélectionnez les deux dates.'),
        ),
      );
      return;
    }

    if (!_startDate!.isBefore(_endDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La date de début doit être antérieure à la date de fin.',
          ),
        ),
      );
      return;
    }

    Navigator.pop(
      context,
      _AcademicYearFormData(
        name: _nameController.text.trim(),
        startDate: _startDate!,
        endDate: _endDate!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 24,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      title: Row(
        children: [
          Icon(
            Icons.calendar_month_rounded,
            color: AppColors.primary,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Nouvelle année académique',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 430,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.none,
                  decoration: InputDecoration(
                    labelText: 'Nom de l’année',
                    hintText: 'Ex. 2026-2027',
                    prefixIcon: const Icon(Icons.label_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Le nom de l’année est obligatoire.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildDateSelector(
                  label: 'Date de début',
                  date: _startDate,
                  onTap: () => _pickDate(isStart: true),
                ),
                const SizedBox(height: 12),
                _buildDateSelector(
                  label: 'Date de fin',
                  date: _endDate,
                  onTap: _startDate == null
                      ? null
                      : () => _pickDate(isStart: false),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.primary,
                        size: 19,
                      ),
                      SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          'La nouvelle année sera créée comme année '
                          'historique. Vous pourrez ensuite la définir '
                          'explicitement comme année courante.',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          onPressed: _submit,
          icon: const Icon(Icons.add),
          label: const Text('Créer l’année'),
        ),
      ],
    );
  }

  Widget _buildDateSelector({
    required String label,
    required DateTime? date,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today_outlined),
          suffixIcon: const Icon(Icons.edit_calendar_outlined),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
        child: Text(
          _formatDate(date),
          style: TextStyle(
            color: date == null
                ? Theme.of(context).colorScheme.onSurfaceVariant
                : Theme.of(context).colorScheme.onSurface,
            fontWeight: date == null ? FontWeight.normal : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
