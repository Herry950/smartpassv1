import 'package:myprojectflut/shared/widgets/home_button.dart';
import 'package:myprojectflut/app/theme/app_colors.dart';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:myprojectflut/features/student/data/repositories/exam_session_repository.dart';

class StudentExamsPage extends StatefulWidget {
  const StudentExamsPage({super.key});

  @override
  State<StudentExamsPage> createState() => _StudentExamsPageState();
}

class _StudentExamsPageState extends State<StudentExamsPage> {
  late Future<List<Map<String, dynamic>>> _examsFuture;

  @override
  void initState() {
    super.initState();
    _loadExams();
  }

  void _loadExams() {
    _examsFuture = ExamSessionRepository.getStudentExams();
  }

  Future<void> _refreshExams() async {
    setState(_loadExams);
    await _examsFuture;
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return {};
  }

  List<Map<String, dynamic>> _asMapList(dynamic value) {
    if (value is! List) {
      return [];
    }

    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  String _formatDate(dynamic value) {
    if (value == null) return 'Date non disponible';

    final date = DateTime.tryParse(value.toString());

    if (date == null) return value.toString();

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day/$month/$year';
  }

  String _formatTime(dynamic value) {
    if (value == null) return '--:--';

    final parts = value.toString().split(':');

    if (parts.length < 2) return value.toString();

    return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
  }

  String _courseTypeLabel(dynamic value) {
    switch (value?.toString()) {
      case 'faculty':
        return 'Cours facultaire';
      case 'departmental':
        return 'Cours départemental';
      case 'common_core':
        return 'Cours de tronc commun';
      default:
        return 'Cours';
    }
  }

  Widget _buildExamCard(Map<String, dynamic> exam) {
    final course = _asMap(exam['courses']);
    final session = _asMap(exam['exam_sessions']);
    final academicYear = _asMap(session['academic_years']);

    final targets = _asMapList(exam['exam_schedule_targets']);
    final roomsData = _asMapList(exam['exam_schedule_rooms']);

    final rooms = roomsData
        .map((item) => _asMap(item['rooms']))
        .where((room) => room.isNotEmpty)
        .toList();

    final courseCode = course['code']?.toString() ?? 'N/A';
    final courseName = course['name']?.toString() ?? 'Cours sans nom';

    final courseType = _courseTypeLabel(course['course_type']);

    final promotionCodes = targets
        .map((target) => target['promotion_code']?.toString())
        .whereType<String>()
        .toSet()
        .toList();

    final promotionText = promotionCodes.isEmpty
        ? 'Non précisée'
        : promotionCodes.join(', ');

    final sessionName =
        session['session_name']?.toString() ?? 'Session d’examen';

    final semester = session['semester']?.toString();

    final academicYearName =
        academicYear['name']?.toString();

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.menu_book_rounded,
                    color: AppColors.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        courseCode,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        courseName,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            Text(
              courseType,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),

            const Divider(height: 28),

            _buildInfoRow(
              Icons.school_outlined,
              'Promotion',
              promotionText,
            ),

            const SizedBox(height: 12),

            _buildInfoRow(
              Icons.calendar_month_outlined,
              'Date',
              _formatDate(exam['exam_date']),
            ),

            const SizedBox(height: 12),

            _buildInfoRow(
              Icons.access_time_rounded,
              'Horaire',
              '${_formatTime(exam['start_time'])} - '
                  '${_formatTime(exam['end_time'])}',
            ),

            const SizedBox(height: 12),

            _buildInfoRow(
              Icons.event_note_outlined,
              'Session',
              semester == null || semester.isEmpty
                  ? sessionName
                  : '$sessionName - $semester',
            ),

            if (academicYearName != null &&
                academicYearName.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                Icons.calendar_today_outlined,
                'Année académique',
                academicYearName,
              ),
            ],

            const Divider(height: 28),

            const Text(
              'Salles attribuées',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 10),

            if (rooms.isEmpty)
              Text(
                'Aucune salle renseignée.',
                style: TextStyle(color: AppColors.textSecondary),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: rooms.map((room) {
                  final code = room['code']?.toString();
                  final name = room['name']?.toString();
                  final building = room['building']?.toString();

                  final roomName = [
                    if (code != null && code.isNotEmpty) code,
                    if (name != null && name.isNotEmpty) name,
                    if (building != null && building.isNotEmpty)
                      building,
                  ].join(' - ');

                  return Chip(
                    avatar: Icon(
                      Icons.meeting_room_outlined,
                      size: 17,
                      color: AppColors.primary,
                    ),
                    label: Text(
                      roomName.isEmpty ? 'Salle' : roomName,
                    ),
                    backgroundColor:
                        AppColors.primary.withValues(alpha: 0.08),
                    side: BorderSide.none,
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: .08);
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
          size: 19,
          color: AppColors.primary,
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 105,
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes examens'),
        actions: [
          const HomeButton(),
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _refreshExams,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _examsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 45,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Impossible de charger les examens.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _refreshExams,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Réessayer'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final exams = snapshot.data ?? [];

          if (exams.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refreshExams,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: 130),
                  Icon(
                    Icons.event_busy_rounded,
                    size: 65,
                    color: AppColors.primary,
                  ),
                  SizedBox(height: 18),
                  Center(
                    child: Text(
                      'Aucun examen programmé pour votre promotion.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshExams,
            child: SafeArea(
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    '${exams.length} examen(s) programmé(s)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 18),
                  ...exams.map(_buildExamCard),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
