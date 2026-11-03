import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:myprojectflut/core/services/auth_service.dart';

class AssistantInvitationPage extends StatefulWidget {
  const AssistantInvitationPage({super.key});

  @override
  State<AssistantInvitationPage> createState() =>
      _AssistantInvitationPageState();
}

class _AssistantInvitationPageState
    extends State<AssistantInvitationPage> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _setPassword() async {
    FocusScope.of(context).unfocus();

    final password = _passwordController.text;
    final confirmation = _confirmPasswordController.text;

    if (password.length < 8) {
      _showMessage(
        'Le mot de passe doit contenir au moins 8 caractères.',
      );
      return;
    }

    if (password != confirmation) {
      _showMessage('Les deux mots de passe ne correspondent pas.');
      return;
    }

    final user = AuthService.currentUser;

    if (user == null) {
      _showMessage(
        'Votre invitation est invalide ou a expiré. '
        'Veuillez demander une nouvelle invitation.',
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final response = await Supabase.instance.client.functions.invoke(
        'activate-assistant',
        body: {
          'password': password,
        },
      );

      final data = response.data;

      if (response.status != 200 ||
          data is! Map ||
          data['success'] != true) {
        final message = data is Map
            ? data['message']?.toString()
            : null;

        throw Exception(
          message ?? 'Impossible d’activer votre compte.',
        );
      }

      if (!mounted) return;

      // La session d'invitation ne doit pas rester active.
      await Supabase.instance.client.auth.signOut();

      if (!mounted) return;

      _showMessage(
        'Votre compte Assistant est activé. '
        'Connectez-vous avec votre nouveau mot de passe.',
      );

      context.go('/login');
    } on FunctionException catch (e) {
      if (mounted) {
        final details = e.details;
        final message = details is Map
            ? details['message']?.toString()
            : null;

        _showMessage(
          message ?? 'Invitation invalide, expirée ou déjà utilisée.',
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        _showMessage(e.message);
      }
    } catch (e) {
      if (mounted) {
        _showMessage(
          e.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.verified_user_rounded,
                      size: 68,
                      color: Color(0xFF556B2F),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Bienvenue dans SmartPass',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Votre compte Assistant a été créé. '
                      'Définissez maintenant votre mot de passe '
                      'pour accéder à votre espace.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),

                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      enabled: !_loading,
                      decoration: InputDecoration(
                        labelText: 'Nouveau mot de passe',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmation,
                      enabled: !_loading,
                      onSubmitted: (_) {
                        if (!_loading) _setPassword();
                      },
                      decoration: InputDecoration(
                        labelText: 'Confirmer le mot de passe',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscureConfirmation =
                                  !_obscureConfirmation;
                            });
                          },
                          icon: Icon(
                            _obscureConfirmation
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Minimum : 8 caractères.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _setPassword,
                        child: _loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Activer mon compte'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}