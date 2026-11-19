import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/exam_schedule_management_service.dart';

String _timeToString(TimeOfDay time) {
  return '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}';
}

String _formatExamDate(DateTime date) {
  const months = [
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

  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

Widget _formSectionTitle(String title, IconData icon) {
  return Row(
    children: [
      Icon(
        icon,
        color: AppColors.primary,
        size: 19,
      ),
      const SizedBox(width: 9),
      Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    ],
  );
}

Future<bool> showExamScheduleFormDialog({
  required BuildContext context,
  required ExamScheduleManagementService service,
  required String sessionId,
  required List<Map<String, dynamic>> courses,
  required List<Map<String, dynamic>> rooms,
  required DateTime examDay,
}) async {
  if (courses.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Aucun cours disponible pour cette session.',
        ),
      ),
    );

    return false;
  }

  if (rooms.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Aucune salle active disponible.',
        ),
      ),
    );

    return false;
  }

  String? selectedCourseId;
  final List<String> selectedRoomIds = [];

  TimeOfDay startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay endTime = const TimeOfDay(hour: 10, minute: 0);

  bool isSaving = false;
  String? dialogError;

  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> selectStartTime() async {
            final selected = await showTimePicker(
              context: context,
              initialTime: startTime,
              helpText: 'Heure de début de l’examen',
            );

            if (!context.mounted) return;

            if (selected != null) {
              setDialogState(() {
                startTime = selected;
                dialogError = null;
              });
            }
          }

          Future<void> selectEndTime() async {
            final selected = await showTimePicker(
              context: context,
              initialTime: endTime,
              helpText: 'Heure de fin de l’examen',
            );

            if (!context.mounted) return;

            if (selected != null) {
              setDialogState(() {
                endTime = selected;
                dialogError = null;
              });
            }
          }

          Future<void> saveExam() async {
            if (selectedCourseId == null) {
              setDialogState(() {
                dialogError = 'Veuillez sélectionner un cours.';
              });

              return;
            }

            if (selectedRoomIds.isEmpty) {
              setDialogState(() {
                dialogError =
                    'Veuillez sélectionner au moins une salle.';
              });

              return;
            }

            final startMinutes =
                startTime.hour * 60 + startTime.minute;

            final endMinutes =
                endTime.hour * 60 + endTime.minute;

            if (endMinutes <= startMinutes) {
              setDialogState(() {
                dialogError =
                    'L’heure de fin doit être après l’heure de début.';
              });

              return;
            }

            setDialogState(() {
              isSaving = true;
              dialogError = null;
            });

            try {
              await service.createExamSchedule(
                sessionId: sessionId,
                courseId: selectedCourseId!,
                examDate: examDay,
                startTime: _timeToString(startTime),
                endTime: _timeToString(endTime),
                roomIds: List<String>.from(selectedRoomIds),
              );

              if (!dialogContext.mounted) return;

              Navigator.of(dialogContext).pop(true);
            } catch (e) {
              if (!dialogContext.mounted) return;

              setDialogState(() {
                isSaving = false;
                dialogError =
                    e.toString().replaceFirst('Exception: ', '');
              });
            }
          }

          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Programmer un examen',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 19,
              ),
            ),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // DATE
                    _formSectionTitle(
                      'Date de l’examen',
                      Icons.calendar_today_outlined,
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(
                          alpha: 0.08,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withValues(
                            alpha: 0.25,
                          ),
                        ),
                      ),
                      child: Text(
                        _formatExamDate(examDay),
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    // COURS
                    _formSectionTitle(
                      'Cours',
                      Icons.menu_book_outlined,
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCourseId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Sélectionner un cours',
                        border: OutlineInputBorder(),
                      ),
                      items: courses.map((course) {
                        final id = course['id'].toString();
                        final code =
                            course['code']?.toString() ?? '';
                        final name =
                            course['name']?.toString() ?? '';
                        final promotion =
                            course['promotion']?.toString() ?? '';

                        return DropdownMenuItem<String>(
                          value: id,
                          child: Text(
                            '$code — $name ($promotion)',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: isSaving
                          ? null
                          : (value) {
                              setDialogState(() {
                                selectedCourseId = value;
                                dialogError = null;
                              });
                            },
                    ),

                    const SizedBox(height: 22),

                    // HORAIRES
                    _formSectionTitle(
                      'Horaires',
                      Icons.access_time_rounded,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed:
                                isSaving ? null : selectStartTime,
                            icon: const Icon(
                              Icons.login_rounded,
                              size: 17,
                            ),
                            label: Text(
                              'Début : ${startTime.format(context)}',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed:
                                isSaving ? null : selectEndTime,
                            icon: const Icon(
                              Icons.logout_rounded,
                              size: 17,
                            ),
                            label: Text(
                              'Fin : ${endTime.format(context)}',
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    // SALLES
                    _formSectionTitle(
                      'Salles d’examen',
                      Icons.meeting_room_outlined,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Vous pouvez sélectionner plusieurs salles.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Container(
                      constraints: const BoxConstraints(
                        maxHeight: 220,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.border,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: rooms.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final room = rooms[index];

                          final id = room['id'].toString();
                          final code =
                              room['code']?.toString() ?? '';
                          final name =
                              room['name']?.toString() ?? '';
                          final capacity =
                              room['capacity']?.toString();

                          final isSelected =
                              selectedRoomIds.contains(id);

                          return CheckboxListTile(
                            value: isSelected,
                            activeColor: AppColors.primary,
                            dense: true,
                            title: Text(
                              '$code — $name',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            subtitle: capacity == null
                                ? null
                                : Text(
                                    'Capacité : $capacity places',
                                    style: const TextStyle(
                                      fontSize: 11,
                                    ),
                                  ),
                            onChanged: isSaving
                                ? null
                                : (checked) {
                                    setDialogState(() {
                                      if (checked == true) {
                                        selectedRoomIds.add(id);
                                      } else {
                                        selectedRoomIds.remove(id);
                                      }

                                      dialogError = null;
                                    });
                                  },
                          );
                        },
                      ),
                    ),

                    if (selectedRoomIds.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${selectedRoomIds.length} salle(s) sélectionnée(s)',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],

                    if (dialogError != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(
                            alpha: 0.08,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          dialogError!,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving
                    ? null
                    : () => Navigator.of(dialogContext).pop(false),
                child: const Text('Annuler'),
              ),
              FilledButton.icon(
                onPressed: isSaving ? null : saveExam,
                icon: isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(
                  isSaving ? 'Enregistrement...' : 'Programmer',
                ),
              ),
            ],
          );
        },
      );
    },
  );

  return result ?? false;
}