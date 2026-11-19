import 'package:myprojectflut/shared/widgets/home_button.dart';
import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/models/student.dart';
import '../../../../core/services/central_admin_service.dart';
import '../../../../core/services/student_card_pdf_service.dart';
import '../../../student/presentation/widgets/student_identity_card.dart';

/// Consultation globale des étudiants et impression de leurs cartes
/// (lecture autorisée à l'administrateur central par RLS).
class CentralStudentsPage extends StatefulWidget {
  const CentralStudentsPage({super.key});

  @override
  State<CentralStudentsPage> createState() => _CentralStudentsPageState();
}

class _CentralStudentsPageState extends State<CentralStudentsPage> {
  static const int _pageLimit = 100;

  final CentralAdminService _service = CentralAdminService();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  bool _loading = true;
  bool _printing = false;
  String? _error;
  String? _faculty;
  List<String> _facultyNames = [];
  List<Map<String, dynamic>> _students = [];
  Map<String, DateTime> _yearEnds = {};
  Map<String, Map<String, dynamic>> _cards = {};

  @override
  void initState() {
    super.initState();
    _loadFaculties();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFaculties() async {
    try {
      final faculties = await _service.loadFaculties();
      if (!mounted) return;
      setState(() {
        _facultyNames =
            faculties.map((f) => f['name'].toString()).toList();
      });
    } catch (_) {
      // Le filtre reste simplement indisponible.
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final students = await _service.searchStudents(
        query: _searchController.text,
        faculty: _faculty,
        limit: _pageLimit,
      );
      final yearEnds = await _service.academicYearEndDates();
      Map<String, Map<String, dynamic>> cards = {};
      try {
        cards = await _service.loadCards(
          students.map((s) => s['id'].toString()).toList(),
        );
      } catch (_) {
        // Lecture des cartes indisponible : la liste reste affichée.
      }

      if (!mounted) return;

      setState(() {
        _students = students;
        _yearEnds = yearEnds;
        _cards = cards;
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

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _load);
  }

  Student _toStudent(Map<String, dynamic> row) {
    return Student(
      id: row['id'] as String,
      authUserId: row['auth_user_id'] as String?,
      fullName: (row['full_name'] ?? '').toString(),
      matricule: (row['matricule'] ?? '').toString(),
      faculty: (row['faculty'] ?? '').toString(),
      department: (row['department'] ?? '').toString(),
      promotion: (row['promotion'] ?? '').toString(),
      academicYear: (row['academic_year'] ?? '').toString(),
      photoUrl: row['photo_url'] as String?,
      // Validité = fin de l'année académique de l'étudiant.
      expiryDate: _yearEnds[(row['academic_year'] ?? '').toString()],
    );
  }

  Future<void> _print(List<Student> students, {bool download = false}) async {
    if (students.isEmpty || _printing) return;

    setState(() => _printing = true);

    try {
      if (download) {
        await StudentCardPdfService.downloadCards(students);
      } else {
        await StudentCardPdfService.printCards(students);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impression impossible : $e')),
      );
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  Future<void> _toggleCard(Map<String, dynamic> card) async {
    final active = card['is_active'] == true;
    try {
      await _service.setCardActive(card['id'].toString(), !active);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          content: Text(active ? 'Carte désactivée.' : 'Carte activée.'),
        ),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  String _cardLabel(String studentId) {
    final card = _cards[studentId];
    if (card == null) return 'Carte : non disponible';
    return card['is_active'] == true ? 'Carte active' : 'Carte désactivée';
  }

  void _showCard(Student student) {
    final card = _cards[student.id];

    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                StudentIdentityCard(
                  student: student,
                  showAccessStatus: false,
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    FilledButton.icon(
                      onPressed: () => _print([student]),
                      icon: const Icon(Icons.print_rounded),
                      label: const Text('Imprimer'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _print([student], download: true),
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('PDF'),
                    ),
                    if (card != null)
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          _toggleCard(card);
                        },
                        icon: Icon(
                          card['is_active'] == true
                              ? Icons.block_rounded
                              : Icons.check_circle_outline_rounded,
                        ),
                        label: Text(
                          card['is_active'] == true
                              ? 'Désactiver la carte'
                              : 'Activer la carte',
                        ),
                      ),
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Fermer'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
          'Étudiants et cartes',
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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 360,
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        decoration: const InputDecoration(
                          labelText: 'Rechercher (nom ou matricule)',
                          prefixIcon: Icon(Icons.search_rounded),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 260,
                      child: DropdownButtonFormField<String?>(
                        initialValue: _faculty,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Faculté',
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Toutes les facultés'),
                          ),
                          ..._facultyNames.map(
                            (name) => DropdownMenuItem<String?>(
                              value: name,
                              child: Text(
                                name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() => _faculty = value);
                          _load();
                        },
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: _loading || _printing || _students.isEmpty
                          ? null
                          : () => _print(_students.map(_toStudent).toList()),
                      icon: _printing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.print_rounded),
                      label: Text(
                        'Imprimer les cartes (${_students.length})',
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: _buildList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
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

    if (_students.isEmpty) {
      return Center(
        child: Text(
          'Aucun étudiant trouvé.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
        itemCount: _students.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          if (index == _students.length) {
            return _students.length >= _pageLimit
                ? Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'Affichage limité à $_pageLimit étudiants : '
                      'affinez la recherche.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : const SizedBox.shrink();
          }

          final row = _students[index];
          final student = _toStudent(row);

          return Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: ListTile(
              onTap: () => _showCard(student),
              leading: CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: .12),
                child: Icon(Icons.person_rounded, color: AppColors.primary),
              ),
              title: Text(
                student.fullName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                [
                  student.matricule,
                  student.faculty,
                  if (student.department.isNotEmpty) student.department,
                  student.promotion,
                  student.academicYear,
                  _cardLabel(student.id),
                ].join(' • '),
              ),
              trailing: IconButton(
                tooltip: 'Imprimer la carte',
                onPressed: _printing ? null : () => _print([student]),
                icon: const Icon(Icons.print_outlined),
              ),
            ),
          );
        },
      ),
    );
  }
}
