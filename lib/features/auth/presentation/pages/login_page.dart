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

  final role = await AuthService.getUserRole();

  print("Rôle détecté : $role");

  if (!mounted) return;

  if (role == "student") {
    context.go("/student");
  } else if (role == "assistant") {
    context.go("/assistant");
  } else if (role == "admin") {
    context.go("/admin");
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
const Icon(
Icons.school_rounded,
size: 70,
color: Colors.green,
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
const SizedBox(height: 30),
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