import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:myprojectflut/app/theme/app_colors.dart';
import 'package:myprojectflut/core/services/auth_service.dart';

/// Réinitialisation du mot de passe oublié.
///
/// 1. Sans lien de récupération : formulaire de demande par e-mail.
/// 2. Avec le lien reçu par e-mail (?code=… en flux PKCE) :
///    échange du code, saisie du nouveau mot de passe,
///    puis déconnexion et retour à la page de connexion.
///
/// Le code n'est échangeable que dans le navigateur qui a fait
/// la demande (vérificateur PKCE conservé localement).
class ResetPasswordPage extends StatefulWidget {
  final Uri callbackUri;

  const ResetPasswordPage({
    super.key,
    required this.callbackUri,
  });

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

enum _ResetStep { request, requestSent, checkingLink, newPassword, error }

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  _ResetStep _step = _ResetStep.request;
  bool _loading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    final uri = widget.callbackUri;
    final parameters = _readUrlParameters(uri);
    final isCallback = uri.path == AuthService.passwordResetPath &&
        (parameters.containsKey('code') ||
            parameters.containsKey('error') ||
            parameters.containsKey('error_code'));

    if (isCallback) {
      _step = _ResetStep.checkingLink;
      _recoverSession(parameters);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Map<String, String> _readUrlParameters(Uri uri) {
    final parameters = <String, String>{...uri.queryParameters};

    if (uri.fragment.isNotEmpty) {
      try {
        parameters.addAll(Uri.splitQueryString(uri.fragment));
      } catch (_) {
        // Paramètres vérifiés ensuite.
      }
    }

    return parameters;
  }

  Future<void> _recoverSession(Map<String, String> parameters) async {
    if (parameters.containsKey('error') ||
        parameters.containsKey('error_code')) {
      _setError(
        'Ce lien de réinitialisation est invalide ou a expiré. '
        'Veuillez demander un nouveau lien.',
      );
      return;
    }

    try {
      await Supabase.instance.client.auth.getSessionFromUrl(
        widget.callbackUri,
      );

      if (!mounted) return;
      setState(() => _step = _ResetStep.newPassword);
    } on AuthException catch (e) {
      debugPrint('RESET PASSWORD: ${e.message}');
      _setError(
        'Impossible de vérifier ce lien. Ouvrez-le dans le même '
        'navigateur que celui utilisé pour la demande, ou demandez '
        'un nouveau lien.',
      );
    } catch (e) {
      debugPrint('RESET PASSWORD: $e');
      _setError(
        'Ce lien de réinitialisation est invalide ou a expiré.',
      );
    }
  }

  void _setError(String message) {
    if (!mounted) return;
    setState(() {
      _errorMessage = message;
      _step = _ResetStep.error;
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _sendLink() async {
    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim();

    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      _showMessage('Veuillez saisir une adresse e-mail valide.');
      return;
    }

    setState(() => _loading = true);

    try {
      await AuthService.sendPasswordResetEmail(email);

      if (!mounted) return;
      setState(() => _step = _ResetStep.requestSent);
    } on AuthException catch (e) {
      if (!mounted) return;
      _showMessage(
        e.statusCode == '429'
            ? 'Trop de demandes. Veuillez patienter quelques minutes.'
            : 'Envoi impossible : ${e.message}',
      );
    } catch (_) {
      if (!mounted) return;
      _showMessage("Envoi impossible. Vérifiez votre connexion.");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _savePassword() async {
    FocusScope.of(context).unfocus();

    final password = _passwordController.text;

    if (password.length < 8 || password.length > 128) {
      _showMessage(
        'Le mot de passe doit contenir entre 8 et 128 caractères.',
      );
      return;
    }

    if (password != _confirmController.text) {
      _showMessage('Les deux mots de passe ne correspondent pas.');
      return;
    }

    setState(() => _loading = true);

    try {
      final client = Supabase.instance.client;

      await client.auth.updateUser(UserAttributes(password: password));

      // L'utilisateur se reconnecte avec son nouveau mot de passe ;
      // la garde de navigation déterminera alors son espace.
      await AuthService.signOut();

      if (!mounted) return;
      _showMessage(
        'Votre mot de passe a été modifié. '
        'Connectez-vous avec votre nouveau mot de passe.',
      );
      context.go('/login');
    } on AuthException catch (e) {
      if (!mounted) return;
      _showMessage('Modification impossible : ${e.message}');
    } catch (_) {
      if (!mounted) return;
      _showMessage('Modification impossible. Veuillez réessayer.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _header(ThemeData theme, IconData icon, String title, String text) {
    return Column(
      children: [
        Icon(icon, size: 64, color: AppColors.primary),
        const SizedBox(height: 20),
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 10),
        Text(text, textAlign: TextAlign.center),
      ],
    );
  }

  Widget _primaryButton(String label, VoidCallback? onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _loading ? null : onPressed,
        child: _loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(label),
      ),
    );
  }

  Widget _backToLogin() {
    return TextButton(
      onPressed: _loading ? null : () => context.go('/login'),
      child: const Text('Retour à la connexion'),
    );
  }

  Widget _buildContent(ThemeData theme) {
    switch (_step) {
      case _ResetStep.checkingLink:
        return const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text(
              'Vérification du lien de réinitialisation...',
              textAlign: TextAlign.center,
            ),
          ],
        );

      case _ResetStep.error:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _header(
              theme,
              Icons.link_off_rounded,
              'Lien indisponible',
              _errorMessage ?? 'Une erreur est survenue.',
            ),
            const SizedBox(height: 28),
            _primaryButton(
              'Demander un nouveau lien',
              () => setState(() {
                _errorMessage = null;
                _step = _ResetStep.request;
              }),
            ),
            const SizedBox(height: 8),
            _backToLogin(),
          ],
        );

      case _ResetStep.requestSent:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _header(
              theme,
              Icons.mark_email_read_rounded,
              'Vérifiez votre boîte e-mail',
              'Si un compte SmartPass est associé à cette adresse, '
                  'un lien de réinitialisation vient de vous être envoyé. '
                  'Ouvrez-le dans ce même navigateur. '
                  'Pensez à vérifier le dossier « Spam ».',
            ),
            const SizedBox(height: 24),
            _backToLogin(),
          ],
        );

      case _ResetStep.newPassword:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _header(
              theme,
              Icons.lock_reset_rounded,
              'Nouveau mot de passe',
              'Choisissez votre nouveau mot de passe SmartPass.',
            ),
            const SizedBox(height: 28),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              enabled: !_loading,
              decoration: InputDecoration(
                labelText: 'Nouveau mot de passe',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  onPressed: () => setState(
                    () => _obscurePassword = !_obscurePassword,
                  ),
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
              controller: _confirmController,
              obscureText: _obscurePassword,
              enabled: !_loading,
              onSubmitted: (_) {
                if (!_loading) _savePassword();
              },
              decoration: const InputDecoration(
                labelText: 'Confirmer le mot de passe',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Minimum : 8 caractères. Maximum : 128 caractères.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 28),
            _primaryButton('Enregistrer le mot de passe', _savePassword),
          ],
        );

      case _ResetStep.request:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _header(
              theme,
              Icons.lock_reset_rounded,
              'Mot de passe oublié',
              'Saisissez l’adresse e-mail de votre compte SmartPass. '
                  'Vous recevrez un lien pour définir un nouveau mot de passe.',
            ),
            const SizedBox(height: 28),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              enabled: !_loading,
              onSubmitted: (_) {
                if (!_loading) _sendLink();
              },
              decoration: const InputDecoration(
                labelText: 'Adresse e-mail',
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 28),
            _primaryButton('Envoyer le lien', _sendLink),
            const SizedBox(height: 8),
            _backToLogin(),
          ],
        );
    }
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
                child: _buildContent(theme),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
