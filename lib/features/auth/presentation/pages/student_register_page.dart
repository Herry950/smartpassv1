import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:myprojectflut/core/services/auth_service.dart';

class StudentRegisterPage extends StatefulWidget {
  const StudentRegisterPage({super.key});

  @override
  State<StudentRegisterPage> createState() =>
      _StudentRegisterPageState();
}

class _StudentRegisterPageState extends State<StudentRegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _matriculeController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _loadingCatalog = true;
  bool _submitting = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  List<Map<String, dynamic>> _faculties = [];
  List<Map<String, dynamic>> _promotions = [];
  List<Map<String, dynamic>> _departments = [];

  String? _selectedFacultyId;
  String? _selectedFaculty;
  String? _selectedPromotion;
  String? _selectedDepartment;

  SupabaseClient get _client => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadFaculties();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _matriculeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadFaculties() async {
    try {
      final data = await _client
          .from('academic_faculties')
          .select('id, name')
          .eq('is_active', true)
          .order('name');

      if (!mounted) return;

      setState(() {
        _faculties = List<Map<String, dynamic>>.from(data);
        _loadingCatalog = false;
      });
    } /*catch (e) {
      if (!mounted) return;

      setState(() => _loadingCatalog = false);
      _showMessage(
        'Impossible de charger les facultés. Vérifiez votre connexion.',
        error: true,
      );
    }*/ catch (e, stackTrace) {
  debugPrint('ERREUR CHARGEMENT FACULTÉS : $e');
  debugPrint('DÉTAILS : $stackTrace');

  if (!mounted) return;

  setState(() => _loadingCatalog = false);

  _showMessage(
    'Impossible de charger les facultés. Vérifiez votre connexion.',
    error: true,
  );
}
  }

  Future<void> _loadPromotions(String facultyId) async {
    setState(() {
      _promotions = [];
      _departments = [];
      _selectedPromotion = null;
      _selectedDepartment = null;
    });

    try {
      final mappings = await _client
          .from('faculty_promotions')
          .select('promotion_code')
          .eq('faculty_id', facultyId);

      final codes = mappings
          .map((item) => item['promotion_code'] as String)
          .toList();

      if (codes.isEmpty) return;

      final data = await _client
          .from('academic_promotions')
          .select('code, rank')
          .inFilter('code', codes)
          .order('rank');

      if (!mounted) return;

      setState(() {
        _promotions = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      _showMessage(
        'Impossible de charger les promotions.',
        error: true,
      );
    }
  }

  Future<void> _loadDepartments(
    String facultyId,
    int promotionRank,
  ) async {
    setState(() {
      _departments = [];
      _selectedDepartment = null;
    });

    try {
      final data = await _client
          .from('academic_departments')
          .select('id, name, minimum_promotion_rank')
          .eq('faculty_id', facultyId)
          .eq('is_active', true)
          .lte('minimum_promotion_rank', promotionRank)
          .order('name');

      if (!mounted) return;

      setState(() {
        _departments = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      _showMessage(
        'Impossible de charger les départements.',
        error: true,
      );
    }
  }

  Future<void> _selectFaculty(String? facultyId) async {
    if (facultyId == null) return;

    final faculty = _faculties.firstWhere(
      (item) => item['id'] == facultyId,
    );

    setState(() {
      _selectedFacultyId = facultyId;
      _selectedFaculty = faculty['name'] as String;
      _selectedPromotion = null;
      _selectedDepartment = null;
      _promotions = [];
      _departments = [];
    });

    await _loadPromotions(facultyId);
  }

  Future<void> _selectPromotion(String? promotion) async {
    if (promotion == null || _selectedFacultyId == null) return;

    final selected = _promotions.firstWhere(
      (item) => item['code'] == promotion,
    );

    setState(() {
      _selectedPromotion = promotion;
      _selectedDepartment = null;
      _departments = [];
    });

    await _loadDepartments(
      _selectedFacultyId!,
      selected['rank'] as int,
    );
  }

  Future<void> _submitRegistration() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    if (_selectedFaculty == null ||
        _selectedPromotion == null) {
      _showMessage(
        'Veuillez sélectionner votre faculté et votre promotion.',
        error: true,
      );
      return;
    }

    if (_departments.isNotEmpty &&
        _selectedDepartment == null) {
      _showMessage(
        'Veuillez sélectionner votre département ou filière.',
        error: true,
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final response = await AuthService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        matricule: _matriculeController.text.trim(),
        fullName: _nameController.text.trim(),
        faculty: _selectedFaculty!,
        promotion: _selectedPromotion!,
        department: _selectedDepartment ?? '',
      );

      if (!mounted) return;

      if (response.user == null) {
        _showMessage(
          'La création du compte n’a pas abouti.',
          error: true,
        );
        return;
      }

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(
            Icons.mark_email_read_outlined,
            color: Color(0xFF556B2F),
            size: 42,
          ),
          title: const Text('Inscription enregistrée'),
          content: Text(
            response.session == null
                ? 'Votre compte a été créé. Consultez votre boîte e-mail pour confirmer votre adresse avant de vous connecter.'
                : 'Votre compte a été créé. Vous pouvez maintenant vous connecter à SmartPass.',
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Continuer'),
            ),
          ],
        ),
      );

      if (!mounted) return;
      context.go('/login');
    } on AuthException catch (e) {
      if (!mounted) return;
      _showMessage(e.message, error: true);
    } catch (e) {
      if (!mounted) return;
      _showMessage(
        'Une erreur est survenue pendant l’inscription : $e',
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  void _showMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red.shade700 : null,
      ),
    );
  }

  InputDecoration _decoration(
    String label,
    IconData icon,
  ) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ce champ est obligatoire.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inscription étudiant'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: _loadingCatalog
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : _buildForm(theme),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(ThemeData theme) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.school_rounded,
            size: 58,
            color: Color(0xFF556B2F),
          ),
          const SizedBox(height: 12),
          Text(
            'Rejoignez SmartPass',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Créez votre compte étudiant pour accéder à vos services académiques.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 28),

          Text(
            'Informations personnelles',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: _decoration(
              'Nom complet',
              Icons.person_outline,
            ),
            validator: _requiredValidator,
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _matriculeController,
            decoration: _decoration(
              'Matricule étudiant',
              Icons.badge_outlined,
            ),
            validator: _requiredValidator,
          ),
          const SizedBox(height: 26),

          Text(
            'Informations académiques',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            initialValue: _selectedFacultyId,
            isExpanded: true,
            decoration: _decoration(
              'Faculté',
              Icons.account_balance_outlined,
            ),
            hint: const Text('Choisir une faculté'),
            items: _faculties.map((faculty) {
              return DropdownMenuItem<String>(
                value: faculty['id'] as String,
                child: Text(faculty['name'] as String),
              );
            }).toList(),
            onChanged: _selectFaculty,
            validator: (value) =>
                value == null ? 'Choisissez une faculté.' : null,
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            initialValue: _selectedPromotion,
            isExpanded: true,
            decoration: _decoration(
              'Promotion',
              Icons.school_outlined,
            ),
            hint: const Text('Choisir une promotion'),
            items: _promotions.map((promotion) {
              return DropdownMenuItem<String>(
                value: promotion['code'] as String,
                child: Text(promotion['code'] as String),
              );
            }).toList(),
            onChanged: _promotions.isEmpty
                ? null
                : _selectPromotion,
            validator: (value) =>
                value == null ? 'Choisissez une promotion.' : null,
          ),

          if (_departments.isNotEmpty) ...[
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedDepartment,
              isExpanded: true,
              decoration: _decoration(
                'Département / Filière',
                Icons.account_tree_outlined,
              ),
              hint: const Text('Choisir un département'),
              items: _departments.map((department) {
                return DropdownMenuItem<String>(
                  value: department['name'] as String,
                  child: Text(department['name'] as String),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedDepartment = value);
              },
              validator: (value) =>
                  value == null ? 'Ce choix est obligatoire.' : null,
            ),
          ],

          const SizedBox(height: 26),

          Text(
            'Identifiants de connexion',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            decoration: _decoration(
              'Adresse e-mail',
              Icons.email_outlined,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Veuillez saisir votre adresse e-mail.';
              }
              if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                  .hasMatch(value.trim())) {
                return 'Adresse e-mail invalide.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: _decoration(
              'Mot de passe',
              Icons.lock_outline,
            ).copyWith(
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez saisir un mot de passe.';
              }
              if (value.length < 8) {
                return 'Minimum 8 caractères.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            decoration: _decoration(
              'Confirmer le mot de passe',
              Icons.lock_reset_outlined,
            ).copyWith(
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword =
                        !_obscureConfirmPassword;
                  });
                },
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Confirmez votre mot de passe.';
              }
              if (value != _passwordController.text) {
                return 'Les mots de passe ne correspondent pas.';
              }
              return null;
            },
          ),

          const SizedBox(height: 28),

          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _submitting ? null : _submitRegistration,
              child: _submitting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Créer mon compte étudiant'),
            ),
          ),

          const SizedBox(height: 18),

          TextButton(
            onPressed: _submitting
                ? null
                : () => context.go('/login'),
            child: const Text(
              'Déjà un compte ? Se connecter',
            ),
          ),
        ],
      ),
    );
  }
}