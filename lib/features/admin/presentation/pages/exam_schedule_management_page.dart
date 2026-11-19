import 'package:myprojectflut/shared/widgets/home_button.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/exam_schedule_management_service.dart';
import 'exam_schedule_form_dialog.dart';

class ExamScheduleManagementPage extends StatefulWidget {
  const ExamScheduleManagementPage({
    super.key,
    required this.sessionId,
  });

  final String sessionId;

  @override
  State<ExamScheduleManagementPage> createState() =>
      _ExamScheduleManagementPageState();
}

class _ExamScheduleManagementPageState
    extends State<ExamScheduleManagementPage> {
  final ExamScheduleManagementService _service =
      ExamScheduleManagementService();

  bool _isLoading = true;
  String? _error;

  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _rooms = [];
  List<Map<String, dynamic>> _schedule = [];

  late DateTime _weekStart;

  // Aucun jour n'est sélectionné automatiquement.
  DateTime? _selectedDay;

  static const List<String> _weekDays = [
    'Lundi',
    'Mardi',
    'Mercredi',
    'Jeudi',
    'Vendredi',
    'Samedi',
  ];

  static const List<String> _months = [
    'janvier',
    'février',
    'mars',
    'avril',
    'mai',
    'juin',
    'juillet',
    'août',
    'septembre',
    'octobre',
    'novembre',
    'décembre',
  ];

  @override
  void initState() {
    super.initState();

    _weekStart = _mondayOf(DateTime.now());

    _loadData();
  }

  DateTime _mondayOf(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);

    return normalizedDate.subtract(
      Duration(days: normalizedDate.weekday - DateTime.monday),
    );
  }

  DateTime get _weekEnd => _weekStart.add(
        const Duration(days: 5),
      );

  List<Map<String, dynamic>> get _visibleSchedule {
    final firstDate = _dateToString(_weekStart);
    final lastDate = _dateToString(_weekEnd);

    return _schedule.where((item) {
      final examDate = item['exam_date']?.toString() ?? '';

      return examDate.compareTo(firstDate) >= 0 &&
          examDate.compareTo(lastDate) <= 0;
    }).toList();
  }

  String _dateToString(DateTime date) {
    return [
      date.year.toString().padLeft(4, '0'),
      date.month.toString().padLeft(2, '0'),
      date.day.toString().padLeft(2, '0'),
    ].join('-');
  }

  String _formatDate(DateTime date) {
    return '${date.day} ${_months[date.month - 1]} ${date.year}';
  }

  String _formatWeekRange() {
    if (_weekStart.month == _weekEnd.month &&
        _weekStart.year == _weekEnd.year) {
      return '${_weekStart.day} - ${_weekEnd.day} '
          '${_months[_weekStart.month - 1]} ${_weekStart.year}';
    }

    return '${_formatDate(_weekStart)} - ${_formatDate(_weekEnd)}';
  }

  void _changeWeek(int direction) {
    setState(() {
      _weekStart = _weekStart.add(
        Duration(days: direction * 7),
      );

      _selectedDay = null;
    });
  }

  void _goToCurrentWeek() {
    setState(() {
      _weekStart = _mondayOf(DateTime.now());
      _selectedDay = null;
    });
  }

  bool get _isCurrentWeek {
    return _weekStart == _mondayOf(DateTime.now());
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _service.getAvailableCourses(
          sessionId: widget.sessionId,
        ),
        _service.getActiveRooms(),
        _service.getSessionSchedule(
          sessionId: widget.sessionId,
          startDate: DateTime(1900, 1, 1),
          endDate: DateTime(2100, 12, 31),
        ),
      ]);

      if (!mounted) return;

      setState(() {
        _courses = results[0];
        _rooms = results[1];
        _schedule = results[2];
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

  // ============================================================
  // PROGRAMMATION D'UN EXAMEN
  // ============================================================

  Future<void> _showCreateExamDialog(DateTime examDay) async {
    final created = await showExamScheduleFormDialog(
      context: context,
      service: _service,
      sessionId: widget.sessionId,
      courses: _courses,
      rooms: _rooms,
      examDay: examDay,
    );

    if (!mounted) return;

    if (created) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Examen programmé avec succès.'),
        ),
      );

      await _loadData();
    }
  }

  // ============================================================
  // INTERFACE PRINCIPALE
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Programmation des examens',
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
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
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
              Text(
                _error!,
                textAlign: TextAlign.center,
              ),
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
        padding: const EdgeInsets.all(18),
        children: [
          _buildSummaryCard(),
          const SizedBox(height: 24),
          _buildWeekNavigation(),
          const SizedBox(height: 18),
          _buildSectionHeader(
            'Emploi du temps hebdomadaire',
            _visibleSchedule.length,
          ),
          const SizedBox(height: 12),
          ...List.generate(
            6,
            (index) {
              final day = _weekStart.add(
                Duration(days: index),
              );

              return _buildDayCard(day, index);
            },
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(
            'Ressources disponibles',
            _courses.length + _rooms.length,
          ),
          const SizedBox(height: 12),
          _buildResourcesCard(),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.event_note_rounded,
            color: Colors.white70,
            size: 28,
          ),
          const SizedBox(height: 12),
          const Text(
            'GESTION DE L’EMPLOI DU TEMPS',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_schedule.length} examen(s) programmé(s)',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${_visibleSchedule.length} examen(s) cette semaine',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekNavigation() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Semaine précédente',
                onPressed: () => _changeWeek(-1),
                icon: const Icon(Icons.chevron_left_rounded),
                color: AppColors.primary,
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'SEMAINE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _formatWeekRange(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Semaine suivante',
                onPressed: () => _changeWeek(1),
                icon: const Icon(Icons.chevron_right_rounded),
                color: AppColors.primary,
              ),
            ],
          ),
          if (!_isCurrentWeek) ...[
            const Divider(height: 12),
            TextButton.icon(
              onPressed: _goToCurrentWeek,
              icon: const Icon(Icons.today_rounded, size: 17),
              label: const Text('Revenir à la semaine actuelle'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Text(
          '$count',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // CARTE D'UN JOUR
  // ============================================================

  Widget _buildDayCard(DateTime day, int index) {
    final dateString = _dateToString(day);

    final dayExams = _schedule.where((item) {
      return item['exam_date']?.toString() == dateString;
    }).toList();

    final isToday = _dateToString(DateTime.now()) == dateString;

    final isSelected = _selectedDay != null &&
        _dateToString(_selectedDay!) == dateString;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected
              ? AppColors.primary
              : isToday
                  ? AppColors.primary.withValues(alpha: 0.45)
                  : AppColors.border,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                setState(() {
                  _selectedDay = day;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Text(
                        '${day.day}',
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : AppColors.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _weekDays[index],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            _formatDate(day),
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isToday)
                      Text(
                        'AUJOURD’HUI',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    if (isSelected) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ],
                    const SizedBox(width: 8),
                    Text(
                      '${dayExams.length}',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            if (dayExams.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.event_available_outlined,
                      size: 17,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(width: 9),
                    Text(
                      'Aucun examen programmé',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...dayExams.map(_buildScheduleCard),

            if (isSelected) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _showCreateExamDialog(day),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Programmer un examen'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 13,
                    ),
                  ),
                ),
              ),
            ] else
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedDay = day;
                    });
                  },
                  child: const Text('Sélectionner ce jour'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CARTE D'UN EXAMEN PROGRAMMÉ
  // ============================================================

  Widget _buildScheduleCard(Map<String, dynamic> item) {
    final course = item['courses'] as Map<String, dynamic>? ?? {};

    final code = course['code']?.toString() ?? 'Cours';
    final name = course['name']?.toString() ?? '';
    final promotion =
        course['promotion']?.toString() ?? 'Promotion inconnue';

    final startTime = item['start_time']?.toString() ?? '';
    final endTime = item['end_time']?.toString() ?? '';

    final roomAssignments =
        item['exam_schedule_rooms'] as List<dynamic>? ?? [];

    final rooms = roomAssignments.map((assignment) {
      final room = assignment['rooms'] as Map<String, dynamic>?;

      return room?['code']?.toString();
    }).whereType<String>().toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 7),
              Text(
                '${_formatTime(startTime)} - ${_formatTime(endTime)}',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                code,
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 9),
          _scheduleInfo(
            Icons.school_outlined,
            promotion,
          ),
          _scheduleInfo(
            Icons.meeting_room_outlined,
            rooms.isEmpty ? 'Aucune salle' : rooms.join(', '),
          ),
        ],
      ),
    );
  }

  String _formatTime(String time) {
    if (time.length >= 5) {
      return time.substring(0, 5);
    }

    return time;
  }

  Widget _scheduleInfo(IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RESSOURCES DISPONIBLES
  // ============================================================

  Widget _buildResourcesCard() {
    return Card(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _resourceInfo(
              Icons.menu_book_outlined,
              'Cours disponibles',
              _courses.length,
            ),
            const Divider(height: 24),
            _resourceInfo(
              Icons.meeting_room_outlined,
              'Salles actives disponibles',
              _rooms.length,
            ),
          ],
        ),
      ),
    );
  }

  Widget _resourceInfo(
    IconData icon,
    String title,
    int count,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          '$count',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}