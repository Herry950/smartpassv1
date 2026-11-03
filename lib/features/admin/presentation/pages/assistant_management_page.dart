import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/assistant_management_service.dart';

class AssistantManagementPage extends StatefulWidget {
  const AssistantManagementPage({super.key});

  @override
  State<AssistantManagementPage> createState() =>
      _AssistantManagementPageState();
}

class _AssistantManagementPageState
    extends State<AssistantManagementPage> {
  final _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _assistants = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAssistants();
  }

  Future<void> _loadAssistants() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final response = await _supabase
          .from('assistants')
          .select(
            'id, full_name, email, employee_number, phone, is_active, created_at',
          )
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        _assistants = List<Map<String, dynamic>>.from(response);
      });
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de chargement : $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showCreateAssistantDialog() async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final numberController = TextEditingController();
    final phoneController = TextEditingController();

    bool isSubmitting = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Nouvel assistant'),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nom complet *',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty) {
                              return 'Le nom complet est obligatoire.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Adresse e-mail *',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (value) {
                            final email = value?.trim() ?? '';
                            if (!RegExp(
                              r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                            ).hasMatch(email)) {
                              return 'Adresse e-mail invalide.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: numberController,
                          decoration: const InputDecoration(
                            labelText: 'Matricule professionnel',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Téléphone',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Un e-mail d’invitation sera envoyé à '
                          'l’adresse indiquée afin que l’assistant '
                          'puisse définir son mot de passe.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Annuler'),
                ),
                FilledButton.icon(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }

                          setDialogState(
                            () => isSubmitting = true,
                          );

                          try {
                            await AssistantManagementService()
                                .createAssistant(
                              fullName: nameController.text,
                              email: emailController.text,
                              employeeNumber:
                                  numberController.text,
                              phone: phoneController.text,
                            );

                            if (!dialogContext.mounted) return;

                            Navigator.pop(dialogContext);

                            if (!mounted) return;

                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              const SnackBar(
                                backgroundColor: Colors.green,
                                content: Text(
                                  'Invitation envoyée et profil créé.',
                                ),
                              ),
                            );

                            await _loadAssistants();
                          } catch (error) {
                            if (!dialogContext.mounted) return;

                            setDialogState(
                              () => isSubmitting = false,
                            );

                            ScaffoldMessenger.of(dialogContext)
                                .showSnackBar(
                              SnackBar(
                                backgroundColor: AppColors.error,
                                content: Text(
                                  'Échec : $error',
                                ),
                              ),
                            );
                          }
                        },
                  icon: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(
                    isSubmitting ? 'Envoi...' : 'Envoyer invitation',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    emailController.dispose();
    numberController.dispose();
    phoneController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Gestion des assistants'),
        backgroundColor: AppColors.surface,
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _loadAssistants,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateAssistantDialog,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Nouvel assistant'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAssistants,
              child: _assistants.isEmpty
                  ? ListView(
                      physics:
                          const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 140),
                        Icon(
                          Icons.support_agent_rounded,
                          size: 58,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(height: 16),
                        Center(
                          child: Text(
                            'Aucun assistant enregistré.',
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        16, 20, 16, 100,
                      ),
                      itemCount: _assistants.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final assistant = _assistants[index];
                        final isActive =
                            assistant['is_active'] == true;

                        return Card(
                          child: ListTile(
                            contentPadding:
                                const EdgeInsets.all(12),
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary
                                  .withValues(alpha: 0.12),
                              child: const Icon(
                                Icons.support_agent_rounded,
                                color: AppColors.primary,
                              ),
                            ),
                            title: Text(
                              assistant['full_name'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Padding(
                              padding:
                                  const EdgeInsets.only(top: 6),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    assistant['email'] ??
                                        'E-mail non renseigné',
                                  ),
                                  if (assistant['employee_number'] !=
                                          null &&
                                      assistant['employee_number']
                                          .toString()
                                          .isNotEmpty)
                                    Text(
                                      'Matricule : '
                                      '${assistant['employee_number']}',
                                    ),
                                  const SizedBox(height: 5),
                                  Text(
                                    isActive ? 'Actif' : 'Inactif',
                                    style: TextStyle(
                                      color: isActive
                                          ? AppColors.primary
                                          : AppColors.error,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}