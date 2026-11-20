import 'package:myprojectflut/shared/widgets/home_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/feedback/smartpass_feedback.dart';
import '../../../../core/feedback/smartpass_messages.dart';
import '../../../../core/services/course_management_service.dart';

class CourseManagementPage extends StatefulWidget {
  const CourseManagementPage({super.key});

  @override
  State<CourseManagementPage> createState() => _CourseManagementPageState();
}

class _CourseManagementPageState extends State<CourseManagementPage> {
  final CourseManagementService _service = CourseManagementService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _courses = [];

  bool _isLoading = true;
  bool _isSaving = false;

  String _searchQuery = '';
  String _filter = 'Toutes';

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int get _totalCourses => _courses.length;

  int get _activeCourses =>
      _courses.where((course) => course['is_active'] == true).length;

  int get _inactiveCourses => _totalCourses - _activeCourses;

  List<Map<String, dynamic>> get _filteredCourses {
    return _courses.where((course) {
      final code = (course['code'] ?? '').toString().toLowerCase();
      final name = (course['name'] ?? '').toString().toLowerCase();
      final faculty = (course['faculty'] ?? '').toString().toLowerCase();
      final department =
          (course['department'] ?? '').toString().toLowerCase();
      final promotion =
          (course['promotion'] ?? '').toString().toLowerCase();

      final departmentNames =
          (course['department_names'] ?? '').toString().toLowerCase();

      final matchesSearch = _searchQuery.isEmpty ||
          code.contains(_searchQuery) ||
          name.contains(_searchQuery) ||
          faculty.contains(_searchQuery) ||
          department.contains(_searchQuery) ||
          departmentNames.contains(_searchQuery) ||
          promotion.contains(_searchQuery);

      final isActive = course['is_active'] == true;

      final matchesFilter = switch (_filter) {
        'Actifs' => isActive,
        'Désactivés' => !isActive,
        _ => true,
      };

      return matchesSearch && matchesFilter;
    }).toList();
  }

  Future<void> _loadCourses() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final result = await _service.getCourses();

      if (!mounted) return;

      setState(() {
        _courses = result;
        _isLoading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('Erreur chargement cours : $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() => _isLoading = false);

      _showMessage(
        SmartPassMessageCode.courseOperationFailed,
      );
    }
  }

  void _showMessage(
    SmartPassMessageCode code, {
    String? details,
  }) {
    SmartPassFeedback.showSnackBar(
      context,
      code: code,
      role: SmartPassRole.admin,
      details: details,
    );
  }

  Future<void> _openCourseForm({
    Map<String, dynamic>? course,
  }) async {
    // Les trois types de cours sont modifiables : la cohérence est
    // garantie côté serveur (RPC atomique pour le tronc commun,
    // triggers d'intégrité, protection des cours déjà programmés).
    final result = await showDialog<CourseFormData>(
      context: context,
      barrierDismissible: !_isSaving,
      builder: (_) => CourseFormDialog(
        course: course,
        service: _service,
      ),
    );

    if (result == null || !mounted) return;

    await _saveCourse(result, course: course);
  }

  Future<void> _saveCourse(
    CourseFormData data, {
    Map<String, dynamic>? course,
  }) async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      if (course == null) {
        if (data.courseType == 'faculty') {
          await _service.createFacultyCourse(
            code: data.code,
            name: data.name,
            faculty: data.faculty,
            promotion: data.promotion,
            credits: data.credits,
          );
        } else if (data.courseType == 'common_core') {
          await _service.createCommonCoreCourse(
            code: data.code,
            name: data.name,
            faculty: data.faculty,
            promotion: data.promotion,
            departmentIds: data.departmentIds,
            credits: data.credits,
          );
        } else {
          await _service.createCourse(
            code: data.code,
            name: data.name,
            faculty: data.faculty,
            department: data.department,
            promotion: data.promotion,
            credits: data.credits,
          );
        }

        if (!mounted) return;

        _showMessage(SmartPassMessageCode.courseCreated);
      } else if (course['course_type'] == 'faculty') {
        await _service.updateFacultyCourse(
          courseId: course['id'].toString(),
          code: data.code,
          name: data.name,
          promotion: data.promotion,
          credits: data.credits,
        );

        if (!mounted) return;

        _showMessage(SmartPassMessageCode.courseUpdated);
      } else if (course['course_type'] == 'common_core') {
        await _service.updateCommonCoreCourse(
          courseId: course['id'].toString(),
          code: data.code,
          name: data.name,
          promotion: data.promotion,
          departmentIds: data.departmentIds,
          credits: data.credits,
        );

        if (!mounted) return;

        _showMessage(SmartPassMessageCode.courseUpdated);
      } else {
        await _service.updateCourse(
          courseId: course['id'].toString(),
          code: data.code,
          name: data.name,
          faculty: data.faculty,
          department: data.department,
          promotion: data.promotion,
          credits: data.credits,
        );

        if (!mounted) return;

        _showMessage(SmartPassMessageCode.courseUpdated);
      }

      await _loadCourses();
    } catch (error, stackTrace) {
      debugPrint('Erreur enregistrement cours : $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      final errorText = error.toString().toLowerCase();

      if (errorText.contains('23505') ||
          errorText.contains('duplicate') ||
          errorText.contains('already exists') ||
          errorText.contains('existe déjà')) {
        _showMessage(
          SmartPassMessageCode.courseCodeAlreadyExists,
        );
      } else {
        // Message serveur explicite (cours programmé, départements,
        // promotion…) sans détail technique sensible.
        _showMessage(
          SmartPassMessageCode.courseOperationFailed,
          details: error
              .toString()
              .replaceFirst('Exception: ', '')
              .replaceFirst('Impossible de modifier le cours : ', ''),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _toggleCourse(Map<String, dynamic> course) async {
    final courseId = course['id']?.toString();

    if (courseId == null || courseId.isEmpty) return;

    final isActive = course['is_active'] == true;
    final newStatus = !isActive;

    try {
      await _service.setCourseStatus(
        courseId: courseId,
        isActive: newStatus,
      );

      if (!mounted) return;

      _showMessage(
        newStatus
            ? SmartPassMessageCode.courseActivated
            : SmartPassMessageCode.courseDeactivated,
      );

      await _loadCourses();
    } catch (error, stackTrace) {
      debugPrint('Erreur changement statut cours : $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      _showMessage(
        SmartPassMessageCode.courseOperationFailed,
      );
    }
  }

  Future<void> _deleteCourse(Map<String, dynamic> course) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Supprimer ce cours ?'),
        content: Text(
          'Voulez-vous vraiment supprimer le cours '
          '"${course['name'] ?? ''}" (${course['code'] ?? ''}) ?\n\n'
          'Cette opération peut être impossible si ce cours est déjà '
          'utilisé dans des sessions d’évaluation.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final courseId = course['id']?.toString();

    if (courseId == null || courseId.isEmpty) return;

    try {
      await _service.deleteCourse(courseId);

      if (!mounted) return;

      _showMessage(SmartPassMessageCode.courseDeleted);

      await _loadCourses();
    } catch (error, stackTrace) {
      debugPrint('Erreur suppression cours : $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      _showMessage(
        SmartPassMessageCode.courseOperationFailed,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Retour au tableau de bord',
          onPressed: () => context.go('/admin'),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text(
          'Cours et Évaluations',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        elevation: 0,
        actions: [
          const HomeButton(),
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _isLoading ? null : _loadCourses,
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving ? null : () => _openCourseForm(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nouveau cours'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadCourses,
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
              constraints: const BoxConstraints(maxWidth: 1250),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildIntroduction(),
                  const SizedBox(height: 24),
                  _buildStatistics(isDesktop),
                  const SizedBox(height: 28),
                  _buildToolbar(isDesktop),
                  const SizedBox(height: 20),
                  _buildCourseList(isDesktop),
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
          'Gestion académique',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Cours et évaluations',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enregistrez les cours, gérez leurs promotions et '
          'contrôlez leur disponibilité dans SmartPass.',
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildStatistics(bool isDesktop) {
    final cards = [
      _StatData(
        label: 'Total des cours',
        value: _totalCourses.toString(),
        icon: Icons.menu_book_rounded,
        color: AppColors.primary,
      ),
      _StatData(
        label: 'Cours actifs',
        value: _activeCourses.toString(),
        icon: Icons.check_circle_outline,
        color: AppColors.success,
      ),
      _StatData(
        label: 'Cours désactivés',
        value: _inactiveCourses.toString(),
        icon: Icons.pause_circle_outline,
        color: AppColors.warning,
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
            mainAxisExtent: 105,
          ),
          itemBuilder: (context, index) {
            return _buildStatCard(cards[index]);
          },
        );
      },
    );
  }

  Widget _buildStatCard(_StatData data) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(data.icon, color: data.color, size: 24),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchController,
          onChanged: (value) {
            setState(() => _searchQuery = value.trim().toLowerCase());
          },
          decoration: InputDecoration(
            hintText: 'Rechercher par code, cours, faculté...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    tooltip: 'Effacer',
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                    icon: const Icon(Icons.close),
                  )
                : null,
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'Toutes',
                label: Text('Toutes'),
                icon: Icon(Icons.list_alt),
              ),
              ButtonSegment(
                value: 'Actifs',
                label: Text('Actifs'),
                icon: Icon(Icons.check_circle_outline),
              ),
              ButtonSegment(
                value: 'Désactivés',
                label: Text('Désactivés'),
                icon: Icon(Icons.pause_circle_outline),
              ),
            ],
            selected: {_filter},
            onSelectionChanged: (selection) {
              setState(() => _filter = selection.first);
            },
            showSelectedIcon: false,
          ),
        ),
      ],
    );
  }

  Widget _buildCourseList(bool isDesktop) {
    final courses = _filteredCourses;

    if (courses.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Liste des cours',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              '${courses.length} résultat(s)',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (isDesktop)
          _buildDesktopCourseList(courses)
        else
          ...courses.map(_buildCourseCard),
      ],
    );
  }

  Widget _buildDesktopCourseList(List<Map<String, dynamic>> courses) {
    return Column(
      children: courses.map((course) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildCourseCard(course),
        );
      }).toList(),
    );
  }

  String _departmentDisplay(Map<String, dynamic> course) {
    if (course['course_type'] == 'faculty') {
      return 'Cours de faculté (sans département)';
    }

    if (course['course_type'] != 'common_core') {
      return course['department']?.toString() ?? 'Non renseigné';
    }

    final names = course['department_names'];

    if (names is List && names.isNotEmpty) {
      return 'Tronc-commun (${names.join(', ')})';
    }

    if (names is String && names.trim().isNotEmpty) {
      return 'Tronc-commun ($names)';
    }

    return 'Tronc-commun';
  }

  Widget _buildCourseCard(Map<String, dynamic> course) {
    final isActive = course['is_active'] == true;
    final credits = course['credits'];
    final promotion = course['promotion']?.toString() ?? 'Non définie';
    final isCommonCore = course['course_type'] == 'common_core';
    final isFacultyCourse = course['course_type'] == 'faculty';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  isCommonCore
                      ? Icons.account_tree_outlined
                      : isFacultyCourse
                          ? Icons.account_balance_outlined
                          : Icons.menu_book_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course['name']?.toString() ?? 'Cours sans nom',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 8,
                      runSpacing: 5,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          course['code']?.toString() ?? 'Sans code',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        if (isFacultyCourse)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'COURS DE FACULTÉ',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        if (isCommonCore)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'TRONC-COMMUN',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(isActive),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.account_balance_outlined,
            'Faculté',
            course['faculty']?.toString() ?? 'Non renseignée',
          ),
          const SizedBox(height: 9),
          _buildInfoRow(
            Icons.school_outlined,
            'Département',
            _departmentDisplay(course),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: _buildInfoRow(
                  Icons.groups_outlined,
                  'Promotion',
                  promotion,
                ),
              ),
              if (credits != null)
                Expanded(
                  child: _buildInfoRow(
                    Icons.stars_outlined,
                    'Crédits',
                    '$credits',
                  ),
                ),
            ],
          ),
          const SizedBox(height: 15),
          Divider(
            height: 1,
            color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildActionButton(
                icon: Icons.edit_outlined,
                label: 'Modifier',
                onPressed: isCommonCore
                    ? null
                    : () => _openCourseForm(course: course),
              ),
              _buildActionButton(
                icon: isActive
                    ? Icons.pause_circle_outline
                    : Icons.play_circle_outline,
                label: isActive ? 'Désactiver' : 'Activer',
                onPressed: () => _toggleCourse(course),
              ),
              _buildActionButton(
                icon: Icons.delete_outline,
                label: 'Supprimer',
                color: AppColors.error,
                onPressed: () => _deleteCourse(course),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 7),
        Text(
          '$label : ',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    final color = isActive ? AppColors.success : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isActive ? 'ACTIF' : 'DÉSACTIVÉ',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    Color? color,
  }) {
    final actionColor = color ?? AppColors.primary;

    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: actionColor,
        disabledForegroundColor:
            Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35),
        side: BorderSide(
          color: actionColor.withValues(alpha: 0.35),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 11,
          vertical: 9,
        ),
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasSearch = _searchQuery.isNotEmpty || _filter != 'Toutes';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 45,
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
            hasSearch
                ? Icons.search_off_rounded
                : Icons.menu_book_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 14),
          Text(
            hasSearch ? 'Aucun résultat trouvé' : 'Aucun cours enregistré',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            hasSearch
                ? 'Essayez une autre recherche ou modifiez le filtre.'
                : 'Commencez par ajouter votre premier cours.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatData {
  const _StatData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class CourseFormData {
  const CourseFormData({
    required this.code,
    required this.name,
    required this.faculty,
    required this.department,
    required this.promotion,
    this.credits,
    this.courseType = 'departmental',
    this.departmentIds = const [],
  });

  final String code;
  final String name;
  final String faculty;
  final String department;
  final String promotion;
  final int? credits;
  final String courseType;
  final List<String> departmentIds;
}

class CourseFormDialog extends StatefulWidget {
  const CourseFormDialog({
    super.key,
    this.course,
    required this.service,
  });

  final Map<String, dynamic>? course;
  final CourseManagementService service;

  @override
  State<CourseFormDialog> createState() => _CourseFormDialogState();
}

class _CourseFormDialogState extends State<CourseFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _codeController;
  late final TextEditingController _nameController;
  late final TextEditingController _creditsController;

  List<Map<String, dynamic>> _faculties = [];
  List<Map<String, dynamic>> _departments = [];
  List<Map<String, dynamic>> _promotions = [];

  final Set<String> _selectedDepartmentIds = {};

  String? _facultyId;
  String? _departmentId;
  String? _promotion;

  bool _isCentralAdmin = false;

  String _courseType = 'departmental';

  int? _minimumPromotionRank;

  bool _isLoadingFaculties = true;
  bool _isLoadingDepartments = false;
  bool _isLoadingPromotions = false;
  bool _hasLoadingError = false;

  String? _loadingError;

  bool get _isEditing => widget.course != null;

  bool get _isCommonCore => _courseType == 'common_core';

  bool get _isFacultyCourse => _courseType == 'faculty';

  @override
  void initState() {
    super.initState();

    final course = widget.course;

    _codeController = TextEditingController(
      text: course?['code']?.toString() ?? '',
    );

    _nameController = TextEditingController(
      text: course?['name']?.toString() ?? '',
    );

    _creditsController = TextEditingController(
      text: course?['credits']?.toString() ?? '',
    );

    _courseType = course?['course_type']?.toString() ?? 'departmental';

    _loadFaculties();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _creditsController.dispose();
    super.dispose();
  }

  Future<void> _loadFaculties() async {
    if (mounted) {
      setState(() {
        _isLoadingFaculties = true;
        _hasLoadingError = false;
        _loadingError = null;
      });
    }

    try {
      final adminContext = await widget.service.getCurrentAdminContext();
      final isCentralAdmin = adminContext['isCentralAdmin'] == true;

      late final List<Map<String, dynamic>> faculties;

      if (isCentralAdmin) {
        // L'administrateur central conserve le choix de la faculté.
        faculties = await widget.service.getFaculties();
      } else {
        // Pour un administrateur facultaire, la faculté vient du profil.
        final facultyId = adminContext['facultyId']?.toString();
        final facultyName = adminContext['facultyName']?.toString();

        if (facultyId == null ||
            facultyId.isEmpty ||
            facultyName == null ||
            facultyName.isEmpty) {
          throw Exception(
            'Aucune faculté active n’est associée à votre compte.',
          );
        }

        faculties = [
          {
            'id': facultyId,
            'name': facultyName,
          },
        ];
      }

      if (!mounted) return;

      final savedFaculty = widget.course?['faculty']?.toString();
      final matchingFaculties = isCentralAdmin
          ? faculties.where(
              (faculty) => faculty['name']?.toString() == savedFaculty,
            ).toList()
          : faculties;

      final selectedFaculty = matchingFaculties.isEmpty
          ? null
          : matchingFaculties.first;

      setState(() {
        _isCentralAdmin = isCentralAdmin;
        _faculties = faculties;
        _facultyId = selectedFaculty?['id']?.toString();
        _isLoadingFaculties = false;
      });

      if (_facultyId != null) {
        if (_isFacultyCourse) {
          await _loadPromotions(restoreSavedPromotion: true);
        } else {
          await _loadDepartments(
            _facultyId!,
            restoreSavedValues: true,
          );
        }
      }
    } catch (error, stackTrace) {
      debugPrint('Erreur chargement contexte académique : $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _isLoadingFaculties = false;
        _hasLoadingError = true;
        _loadingError =
            'Impossible de récupérer votre faculté et les données académiques. '
            'Vérifiez votre connexion ou réessayez.';
      });
    }
  }

  Future<void> _loadDepartments(
    String facultyId, {
    bool restoreSavedValues = false,
  }) async {
    setState(() {
      _isLoadingDepartments = true;
      _departments = [];
      _departmentId = null;
      _selectedDepartmentIds.clear();
      _promotions = [];
      _promotion = null;
      _minimumPromotionRank = null;
    });

    try {
      final result = await widget.service.getDepartments(facultyId);

      if (!mounted) return;

      final savedDepartment = widget.course?['department']?.toString();

      final matchingDepartments = restoreSavedValues
          ? result.where(
              (department) =>
                  department['name']?.toString() == savedDepartment,
            )
          : <Map<String, dynamic>>[];

      final selectedDepartment = matchingDepartments.isEmpty
          ? null
          : matchingDepartments.first;

      setState(() {
        _departments = result;
        _departmentId = selectedDepartment?['id']?.toString();

        if (_departmentId != null) {
          _selectedDepartmentIds.add(_departmentId!);
        }

        _isLoadingDepartments = false;
      });

      if (_departmentId != null) {
        await _selectDepartment(
          _departmentId!,
          restoreSavedPromotion: true,
        );
      } else if (restoreSavedValues &&
          _isCommonCore &&
          widget.course?['id'] != null) {
        // Modification d'un tronc commun : restaurer ses départements
        // associés (course_departments) puis sa promotion.
        final savedIds = await widget.service.getCourseDepartmentIds(
          widget.course!['id'].toString(),
        );

        if (!mounted) return;

        final available =
            result.map((d) => d['id']?.toString()).toSet();

        setState(() {
          _selectedDepartmentIds
            ..clear()
            ..addAll(savedIds.where(available.contains));
        });

        await _loadPromotions(restoreSavedPromotion: true);
      }
    } catch (error, stackTrace) {
      debugPrint('Erreur chargement départements : $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _isLoadingDepartments = false;
        _hasLoadingError = true;
        _loadingError = error.toString();
      });
    }
  }

  int _calculateMinimumRank() {
    if (_selectedDepartmentIds.isEmpty) return 0;

    var maximumRank = 0;

    for (final department in _departments) {
      final id = department['id']?.toString();

      if (!_selectedDepartmentIds.contains(id)) continue;

      final rank = department['minimum_promotion_rank'];

      if (rank is num && rank.toInt() > maximumRank) {
        maximumRank = rank.toInt();
      }
    }

    return maximumRank;
  }

  Future<void> _loadPromotions({
    bool restoreSavedPromotion = false,
  }) async {
    if (_isFacultyCourse) {
      if (_facultyId == null || _facultyId!.isEmpty) {
        setState(() {
          _promotions = [];
          _promotion = null;
          _minimumPromotionRank = null;
          _isLoadingPromotions = false;
        });
        return;
      }
    } else if (_selectedDepartmentIds.isEmpty) {
      setState(() {
        _promotions = [];
        _promotion = null;
        _minimumPromotionRank = null;
        _isLoadingPromotions = false;
      });
      return;
    }

    final minimumRank = _isFacultyCourse ? 0 : _calculateMinimumRank();

    setState(() {
      _minimumPromotionRank = _isFacultyCourse ? null : minimumRank;
      _promotions = [];
      _promotion = null;
      _isLoadingPromotions = true;
    });

    try {
      final result = await widget.service.getFacultyPromotions(
        facultyId: _facultyId!,
        minimumRank: minimumRank,
      );

      if (!mounted) return;

      final savedPromotion = widget.course?['promotion']?.toString();

      final matchingPromotions = restoreSavedPromotion
          ? result.where(
              (promotion) =>
                  promotion['code']?.toString() == savedPromotion,
            )
          : <Map<String, dynamic>>[];

      final selectedPromotion = matchingPromotions.isEmpty
          ? null
          : matchingPromotions.first;

      setState(() {
        _promotions = result;
        _promotion = selectedPromotion?['code']?.toString();
        _isLoadingPromotions = false;
      });
    } catch (error, stackTrace) {
      debugPrint('Erreur chargement promotions : $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _isLoadingPromotions = false;
        _hasLoadingError = true;
        _loadingError = error.toString();
      });
    }
  }

  Future<void> _selectDepartment(
    String departmentId, {
    bool restoreSavedPromotion = false,
  }) async {
    final selectedDepartments = _departments.where(
      (department) => department['id']?.toString() == departmentId,
    );

    if (selectedDepartments.isEmpty) return;

    setState(() {
      _departmentId = departmentId;
      _selectedDepartmentIds
        ..clear()
        ..add(departmentId);
    });

    await _loadPromotions(
      restoreSavedPromotion: restoreSavedPromotion,
    );
  }

  Future<void> _toggleCommonDepartment(
    String departmentId,
    bool selected,
  ) async {
    setState(() {
      if (selected) {
        _selectedDepartmentIds.add(departmentId);
      } else {
        _selectedDepartmentIds.remove(departmentId);
      }

      _promotion = null;
      _promotions = [];
    });

    await _loadPromotions();
  }

  void _onFacultyChanged(String? facultyId) {
    if (facultyId == null) return;

    setState(() {
      _facultyId = facultyId;
      _departmentId = null;
      _promotion = null;
      _departments = [];
      _promotions = [];
      _selectedDepartmentIds.clear();
      _minimumPromotionRank = null;
    });

    if (_isFacultyCourse) {
      _loadPromotions();
    } else {
      _loadDepartments(facultyId);
    }
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ce champ est obligatoire.';
    }

    return null;
  }

  void _submit() {
    if (_hasLoadingError) return;

    if (!_formKey.currentState!.validate()) return;

    final selectedFaculty = _faculties.where(
      (faculty) => faculty['id']?.toString() == _facultyId,
    );

    if (selectedFaculty.isEmpty) return;

    if (_isCommonCore && _selectedDepartmentIds.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Sélectionnez au moins deux départements pour un cours '
            'tronc-commun.',
          ),
        ),
      );
      return;
    }

    if (!_isCommonCore &&
        !_isFacultyCourse &&
        _selectedDepartmentIds.length != 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sélectionnez un département.'),
        ),
      );
      return;
    }

    if (_promotion == null) return;

    final creditsText = _creditsController.text.trim();
    final credits = creditsText.isEmpty ? null : int.tryParse(creditsText);

    if (creditsText.isNotEmpty && credits == null) {
      return;
    }

    final selectedDepartmentNames = _departments
        .where(
          (department) => _selectedDepartmentIds.contains(
            department['id']?.toString(),
          ),
        )
        .map((department) => department['name'].toString())
        .toList();

    Navigator.of(context).pop(
      CourseFormData(
        code: _codeController.text.trim().toUpperCase(),
        name: _nameController.text.trim(),
        faculty: selectedFaculty.first['name'].toString(),
        department: _isFacultyCourse
            ? ''
            : _isCommonCore
                ? 'Tronc-commun'
                : selectedDepartmentNames.first,
        promotion: _promotion!,
        credits: credits,
        courseType: _courseType,
        departmentIds: _selectedDepartmentIds.toList(),
      ),
    );
  }

  InputDecoration _decoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(14),
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    if (!_hasLoadingError) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.error_outline, color: AppColors.error, size: 19),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Impossible de charger les données académiques.',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          if (_loadingError != null) ...[
            const SizedBox(height: 6),
            Text(
              _loadingError!,
              style: const TextStyle(fontSize: 12, height: 1.4),
            ),
          ],
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _loadFaculties,
            icon: const Icon(Icons.refresh, size: 17),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: _courseType,
          isExpanded: true,
          decoration: _decoration(
            label: 'Type de cours',
            icon: Icons.category_outlined,
          ),
          items: const [
            DropdownMenuItem(
              value: 'faculty',
              child: Text('Cours de faculté (sans département)'),
            ),
            DropdownMenuItem(
              value: 'departmental',
              child: Text('Cours départemental'),
            ),
            DropdownMenuItem(
              value: 'common_core',
              child: Text('Cours tronc-commun'),
            ),
          ],
          onChanged: _isEditing
              ? null
              : (value) {
                  if (value == null) return;

                  setState(() {
                    _courseType = value;
                    _promotion = null;
                    _promotions = [];
                    _selectedDepartmentIds.clear();
                    _departmentId = null;
                    _departments = [];
                    _minimumPromotionRank = null;
                  });

                  if (value == 'faculty') {
                    _loadPromotions();
                  } else if (_facultyId != null) {
                    _loadDepartments(_facultyId!);
                  }
                },
        ),
        const SizedBox(height: 7),
        Text(
          _isCommonCore
              ? 'Ce cours sera enregistré une seule fois et partagé '
                  'entre plusieurs départements de la même faculté.'
              : _isFacultyCourse
                  ? 'Ce cours concerne toute la faculté et ne dépend d’aucun département.'
                  : 'Ce cours sera rattaché à un seul département.',
          style: TextStyle(
            fontSize: 11,
            height: 1.4,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildDepartmentSelector() {
    if (_isFacultyCourse) {
      return const SizedBox.shrink();
    }

    if (_isLoadingDepartments) {
      return _buildLoadingIndicator();
    }

    if (_departments.isEmpty) {
      return Text(
        'Aucun département actif disponible pour cette faculté.',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 12,
        ),
      );
    }

    if (!_isCommonCore) {
      return DropdownButtonFormField<String>(
        key: ValueKey('department_$_facultyId'),
        initialValue: _departmentId,
        isExpanded: true,
        decoration: _decoration(
          label: 'Département',
          icon: Icons.school_outlined,
        ),
        hint: const Text('Sélectionner un département'),
        items: _departments.map((department) {
          return DropdownMenuItem<String>(
            value: department['id'].toString(),
            child: Text(
              department['name'].toString(),
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            _selectDepartment(value);
          }
        },
        validator: (value) {
          if (!_isCommonCore && (value == null || value.isEmpty)) {
            return 'Sélectionnez un département.';
          }
          return null;
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Départements concernés',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Sélectionnez au moins deux départements.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).dividerColor,
            ),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Column(
            children: _departments.map((department) {
              final id = department['id'].toString();
              final isSelected = _selectedDepartmentIds.contains(id);

              return CheckboxListTile(
                value: isSelected,
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: AppColors.primary,
                title: Text(
                  department['name'].toString(),
                  style: const TextStyle(fontSize: 13),
                ),
                subtitle: Text(
                  'Rang minimum : '
                  '${department['minimum_promotion_rank'] ?? 'Non défini'}',
                  style: const TextStyle(fontSize: 10),
                ),
                onChanged: (value) {
                  _toggleCommonDepartment(id, value == true);
                },
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          '${_selectedDepartmentIds.length} département(s) sélectionné(s)',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        if (_selectedDepartmentIds.length == 1)
          Padding(
            padding: EdgeInsets.only(top: 5),
            child: Text(
              'Ajoutez encore au moins un département.',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.primary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPromotionSelector() {
    if (_isLoadingPromotions) {
      return _buildLoadingIndicator();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          key: ValueKey(
            'promotion_${_courseType}_${_facultyId}_${_selectedDepartmentIds.join('_')}',
          ),
          initialValue: _promotion,
          isExpanded: true,
          decoration: _decoration(
            label: 'Promotion',
            icon: Icons.groups_outlined,
          ),
          hint: Text(
            !_isFacultyCourse && _selectedDepartmentIds.isEmpty
                ? 'Sélectionnez d’abord un département'
                : _promotions.isEmpty
                    ? 'Aucune promotion disponible pour cette faculté'
                    : 'Sélectionner une promotion',
          ),
          items: _promotions.map((promotion) {
            return DropdownMenuItem<String>(
              value: promotion['code'].toString(),
              child: Text(promotion['code'].toString()),
            );
          }).toList(),
          onChanged: _promotions.isEmpty
              ? null
              : (value) {
                  setState(() => _promotion = value);
                },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Sélectionnez une promotion.';
            }
            return null;
          },
        ),
        if (!_isFacultyCourse && _minimumPromotionRank != null) ...[
          const SizedBox(height: 7),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Rang minimum requis pour tous les départements : '
              '$_minimumPromotionRank.',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAcademicFields() {
    if (_isLoadingFaculties) {
      return _buildLoadingIndicator();
    }

    if (_hasLoadingError) {
      return _buildErrorMessage();
    }

    return Column(
      children: [
        _buildCourseTypeSelector(),
        const SizedBox(height: 14),
        if (_isCentralAdmin)
          DropdownButtonFormField<String>(
            initialValue: _facultyId,
            isExpanded: true,
            decoration: _decoration(
              label: 'Faculté',
              icon: Icons.account_balance_outlined,
            ),
            hint: const Text('Sélectionner une faculté'),
            items: _faculties.map((faculty) {
              return DropdownMenuItem<String>(
                value: faculty['id'].toString(),
                child: Text(
                  faculty['name'].toString(),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: _onFacultyChanged,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Sélectionnez une faculté.';
              }
              return null;
            },
          )
        else
          InputDecorator(
            decoration: _decoration(
              label: 'Faculté attribuée',
              icon: Icons.account_balance_outlined,
            ),
            child: Text(
              _faculties.isEmpty
                  ? 'Faculté non disponible'
                  : _faculties.first['name'].toString(),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        const SizedBox(height: 14),
        if (!_isFacultyCourse) ...[
          _buildDepartmentSelector(),
          const SizedBox(height: 14),
        ],
        _buildPromotionSelector(),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool required = true,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: keyboardType == TextInputType.text
          ? TextCapitalization.sentences
          : TextCapitalization.none,
      decoration: _decoration(
        label: label,
        hint: hint,
        icon: icon,
      ),
      validator: validator ?? (required ? _requiredValidator : null),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

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
            _isEditing ? Icons.edit_note : Icons.add_circle_outline,
            color: AppColors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _isEditing ? 'Modifier le cours' : 'Nouveau cours',
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 450,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildField(
                  controller: _codeController,
                  label: 'Code du cours',
                  hint: 'Ex. GIN301',
                  icon: Icons.tag,
                ),
                const SizedBox(height: 14),
                _buildField(
                  controller: _nameController,
                  label: 'Intitulé du cours',
                  hint: 'Ex. Projet de Fin de Cycle',
                  icon: Icons.menu_book_outlined,
                ),
                const SizedBox(height: 14),
                _buildAcademicFields(),
                const SizedBox(height: 14),
                _buildField(
                  controller: _creditsController,
                  label: 'Crédits (facultatif)',
                  hint: 'Ex. 6',
                  icon: Icons.stars_outlined,
                  keyboardType: TextInputType.number,
                  required: false,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return null;

                    final parsed = int.tryParse(value.trim());

                    if (parsed == null || parsed <= 0) {
                      return 'Entrez un nombre entier positif.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest.withValues(
                      alpha: 0.45,
                    ),
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
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          _isCommonCore
                              ? 'Le cours sera créé une seule fois. '
                                  'Les départements sélectionnés seront '
                                  'associés au même cours. La promotion '
                                  'doit respecter le rang minimum de '
                                  'chacun d’eux.'
                              : _isFacultyCourse
                                  ? 'Ce cours est destiné à toute la faculté, '
                                      'sans département associé. La liste des '
                                      'promotions dépend des affectations '
                                      'enregistrées pour cette faculté.'
                                  : _isCentralAdmin
                                  ? 'La faculté, les départements et les '
                                      'promotions proviennent des données '
                                      'académiques. Les crédits restent '
                                      'facultatifs.'
                                  : 'Votre faculté est attribuée automatiquement '
                                      'depuis votre compte administrateur. '
                                      'Les départements et promotions sont '
                                      'chargés pour cette faculté. '
                                      'Les crédits restent facultatifs.',
                          style: const TextStyle(
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
          onPressed: _isLoadingFaculties ||
                  _isLoadingDepartments ||
                  _isLoadingPromotions ||
                  _hasLoadingError
              ? null
              : _submit,
          icon: Icon(_isEditing ? Icons.save_outlined : Icons.add),
          label: Text(_isEditing ? 'Enregistrer' : 'Créer le cours'),
        ),
      ],
    );
  }
}