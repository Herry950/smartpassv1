import 'package:myprojectflut/app/theme/app_colors.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AssistantInvitationPage extends StatefulWidget {
  final Uri callbackUri;

  const AssistantInvitationPage({
    super.key,
    required this.callbackUri,
  });
  @override
  State<AssistantInvitationPage> createState() =>
      _AssistantInvitationPageState();
}

class _AssistantInvitationPageState
    extends State<AssistantInvitationPage> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  Session? _invitationSession;

  bool _checkingInvitation = true;
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;

  String? _invitationError;

  @override
  void initState() {
    super.initState();
    _recoverInvitationSession();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Récupère les paramètres présents dans la query
  // et dans le fragment de l'URL.
  Map<String, String> _readUrlParameters(Uri uri) {
    final parameters = <String, String>{
      ...uri.queryParameters,
    };

    if (uri.fragment.isNotEmpty) {
      var fragment = uri.fragment;

      // Certains liens peuvent contenir un chemin
      // avant les paramètres du fragment.
      if (fragment.contains('?')) {
        fragment = fragment.substring(
          fragment.indexOf('?') + 1,
        );
      }

      try {
        parameters.addAll(
          Uri.splitQueryString(fragment),
        );
      } catch (_) {
        // Les paramètres seront vérifiés ensuite.
      }
    }

    return parameters;
  }

  // Récupération isolée de la session d'invitation.
  // IMPORTANT : cette session ne doit jamais remplacer
  // la session persistante de l'Admin.
  Future<void> _recoverInvitationSession() async {
    try {
      final client = Supabase.instance.client;
      final uri = widget.callbackUri;

      final parameters = _readUrlParameters(uri);

      //diagnostic

      debugPrint('SUPABASE ERROR CODE : ${parameters['error_code']}');
debugPrint('SUPABASE ERROR DESCRIPTION : ${parameters['error_description']}');
debugPrint('HAS SB PARAMETER : ${parameters.containsKey('sb')}');

      debugPrint('========== DIAGNOSTIC INVITATION ==========');
debugPrint('PATH : ${uri.path}');
debugPrint('QUERY KEYS : ${uri.queryParameters.keys.toList()}');

final fragmentParameters = uri.fragment.contains('?')
    ? Uri.splitQueryString(
        uri.fragment.substring(uri.fragment.indexOf('?') + 1),
      )
    : Uri.splitQueryString(uri.fragment);

debugPrint('FRAGMENT KEYS : ${fragmentParameters.keys.toList()}');
debugPrint('TYPE : ${parameters['type']}');
debugPrint('HAS CODE : ${parameters.containsKey('code')}');
debugPrint('HAS ACCESS TOKEN : ${parameters.containsKey('access_token')}');
debugPrint('HAS REFRESH TOKEN : ${parameters.containsKey('refresh_token')}');
debugPrint('==========================================');

      final errorCode = parameters['error_code'];
      final errorDescription =
          parameters['error_description'];
      final urlError = parameters['error'];

      if (errorCode != null || urlError != null) {
        throw Exception(
          errorDescription ??
              errorCode ??
              'Le lien d’invitation est invalide ou expiré.',
        );
      }

      // Une invitation Supabase classique doit retourner
      // le type invite et les deux jetons de session.
      final invitationType =
          parameters['type']?.toLowerCase();

      if (invitationType != 'invite') {
        throw Exception(
          'Ce lien ne correspond pas à une invitation SmartPass.',
        );
      }

      if (parameters['access_token'] == null ||
          parameters['refresh_token'] == null) {
        throw Exception(
          'Les informations de votre invitation sont incomplètes. '
          'Veuillez demander un nouveau lien.',
        );
      }

      // storeSession:false est essentiel :
      // le jeton récupéré n'est pas enregistré dans
      // le stockage partagé de l'application.
      final result = await client.auth.getSessionFromUrl(
        uri,
        storeSession: false,
      );

      final invitationSession = result.session;

      if (invitationSession.user.email == null ||
          invitationSession.user.id.isEmpty) {
        throw Exception(
          'Impossible de vérifier l’identité de l’invité.',
        );
      }

      if (!mounted) return;

      setState(() {
        _invitationSession = invitationSession;
        _checkingInvitation = false;
      });

      debugPrint('========== INVITATION SMARTPASS ==========');
      debugPrint('TYPE : INVITE');
      debugPrint('EMAIL : ${invitationSession.user.email}');
      debugPrint('USER ID : ${invitationSession.user.id}');
      debugPrint('SESSION : RECOVERED WITHOUT PERSISTENCE');
      debugPrint('==========================================');
    } on AuthException catch (e) {
      _setInvitationError(
        'Impossible de vérifier votre invitation : ${e.message}',
      );
    } catch (e) {
      _setInvitationError(
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void _setInvitationError(String message) {
    if (!mounted) return;

    setState(() {
      _invitationError = message;
      _checkingInvitation = false;
      _invitationSession = null;
    });

    debugPrint('INVITATION ERROR: $message');
  }

  Future<void> _setPassword() async {
    FocusScope.of(context).unfocus();

    final password = _passwordController.text;
    final confirmation = _confirmPasswordController.text;

    if (_invitationSession == null) {
      _showMessage(
        'Votre invitation est invalide ou expirée.',
      );
      return;
    }

    if (password.length < 8 || password.length > 128) {
      _showMessage(
        'Le mot de passe doit contenir entre 8 et 128 caractères.',
      );
      return;
    }

    if (password != confirmation) {
      _showMessage(
        'Les deux mots de passe ne correspondent pas.',
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final client = Supabase.instance.client;

      // On utilise exclusivement le JWT de l'invitation.
      // On ne touche jamais à la session Admin.
      final response = await client.functions.invoke(
        'activate-assistant',
        headers: {
          'Authorization':
              'Bearer ${_invitationSession!.accessToken}',
        },
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

      // IMPORTANT :
      // Aucun signOut() ici.
      // La session d'invitation n'a jamais été persistée.
      // La session principale reste donc intacte.

      _passwordController.clear();
      _confirmPasswordController.clear();

      setState(() {
        _invitationSession = null;
      });

      _showMessage(
        data['message']?.toString() ??
            'Votre compte est activé avec succès.',
      );

      context.go('/login');
    } on FunctionException catch (e) {
      if (mounted) {
        final details = e.details;

        final message = details is Map
            ? details['message']?.toString()
            : null;

        _showMessage(
          message ??
              'Invitation invalide, expirée ou déjà utilisée.',
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

  // Libellé d'affichage uniquement (métadonnées de l'invitation) ;
  // les droits réels sont déterminés côté serveur.
  String get _roleLabel {
    final role = _invitationSession?.user.userMetadata?['role'];
    return role == 'faculty_admin'
        ? 'Administrateur facultaire'
        : 'Assistant';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildLoading() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(
          color: AppColors.primary,
        ),
        SizedBox(height: 20),
        Text(
          'Vérification de votre invitation...',
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildError(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.error_outline_rounded,
          color: Colors.redAccent,
          size: 64,
        ),
        const SizedBox(height: 20),
        Text(
          'Invitation indisponible',
          style: theme.textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          _invitationError ??
              'Une erreur est survenue.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () => context.go('/login'),
            child: const Text('Retour à la connexion'),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordForm(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.verified_user_rounded,
          size: 68,
          color: AppColors.primary,
        ),
        const SizedBox(height: 20),
        Text(
          'Bienvenue dans SmartPass',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 10),
        Text(
          'Votre invitation a été vérifiée. '
          'Définissez maintenant votre mot de passe '
          'pour accéder à votre espace $_roleLabel.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          _invitationSession?.user.email ?? '',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
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
            constraints: const BoxConstraints(
              maxWidth: 440,
            ),
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: _checkingInvitation
                    ? _buildLoading()
                    : _invitationError != null
                        ? _buildError(theme)
                        : _buildPasswordForm(theme),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
