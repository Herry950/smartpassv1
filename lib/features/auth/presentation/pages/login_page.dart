import 'package:myprojectflut/app/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:myprojectflut/core/services/auth_service.dart';

class LoginPage extends StatefulWidget {
const LoginPage({super.key});

@override
State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
final emailController = TextEditingController();
final passwordController = TextEditingController();

bool loading = false;
bool obscurePassword = true;

@override
void dispose() {
emailController.dispose();
passwordController.dispose();
super.dispose();
}

Future<void> signIn() async {
FocusScope.of(context).unfocus();

setState(() {
  loading = true;
});

try {
  print("========== LOGIN ==========");

  final response = await AuthService.signIn(
    email: emailController.text.trim(),
    password: passwordController.text,
  );

  print("Connexion réussie.");
  print("User retourné : ${response.user?.id}");

  print("CurrentUser : ${AuthService.currentUser}");
  print("CurrentUser ID : ${AuthService.currentUser?.id}");
  print("CurrentUser Email : ${AuthService.currentUser?.email}");

  AuthService.clearRoleCache();
  final role = await AuthService.getCachedUserRole();

  print("Rôle détecté : $role");

  if (!mounted) return;

  final home = AuthService.homeRouteForRole(role);

  if (home != null) {
    context.go(home);
  } else if (role == AuthService.roleInactiveAdmin) {
    await AuthService.signOut();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Votre compte administrateur est désactivé. "
          "Veuillez contacter l'administration centrale.",
        ),
      ),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Aucun rôle associé à ce compte."),
      ),
    );
  }
} catch (e) {
  print("ERREUR LOGIN : $e");

  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(e.toString()),
    ),
  );
} finally {
  if (mounted) {
    setState(() {
      loading = false;
    });
  }
}

}

@override
Widget build(BuildContext context) {
return Scaffold(
body: Center(
child: SingleChildScrollView(
padding: const EdgeInsets.all(24),
child: SizedBox(
width: 420,
child: Card(
elevation: 2,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(24),
),
child: Padding(
padding: const EdgeInsets.all(30),
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
Icon(
Icons.school_rounded,
size: 70,
color: AppColors.primary,
),
const SizedBox(height: 20),
Text(
"Connexion SmartPass",
style: Theme.of(context).textTheme.headlineSmall,
),
const SizedBox(height: 8),
const Text(
"Connectez-vous à votre compte",
),
const SizedBox(height: 30),
TextField(
controller: emailController,
keyboardType: TextInputType.emailAddress,
decoration: const InputDecoration(
labelText: "Adresse e-mail",
prefixIcon: Icon(Icons.email),
),
),
const SizedBox(height: 20),
TextField(
controller: passwordController,
obscureText: obscurePassword,
decoration: InputDecoration(
labelText: "Mot de passe",
prefixIcon: const Icon(Icons.lock),
suffixIcon: IconButton(
icon: Icon(
obscurePassword
? Icons.visibility
: Icons.visibility_off,
),
onPressed: () {
setState(() {
obscurePassword = !obscurePassword;
});
},
),
),
onSubmitted: (_) => signIn(),
),
Align(
alignment: Alignment.centerRight,
child: TextButton(
onPressed: loading
? null
: () => context.go('/auth/reset-password'),
child: const Text("Mot de passe oublié ?"),
),
),
const SizedBox(height: 14),
SizedBox(
width: double.infinity,
height: 50,
child: ElevatedButton(
onPressed: loading ? null : signIn,
child: loading
? const SizedBox(
width: 22,
height: 22,
child: CircularProgressIndicator(
strokeWidth: 2,
),
)
: const Text("Se connecter"),
),
),

                const SizedBox(height: 16),

                TextButton(
                  onPressed: loading
                      ? null
                      : () => context.go('/register'),
                  child: const Text(
                    "Pas encore de compte ? S'inscrire",
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