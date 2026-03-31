import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'signup_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(30),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F0F1E), Color(0xFF1E1E2E)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Srishty',
              style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold, letterSpacing: 2),
            ),
            const SizedBox(height: 10),
            const Text('Your Stories, Amplified.', style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 60),
            _buildTextField(_usernameController, 'Username', Icons.person_outline),
            const SizedBox(height: 20),
            _buildTextField(_passwordController, 'Password', Icons.lock_outline, isPassword: true),
            const SizedBox(height: 40),
            if (authState.status == AuthStatus.loading)
              const CircularProgressIndicator()
            else
              _buildLoginButton(),
            if (authState.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(authState.errorMessage!, style: const TextStyle(color: Colors.redAccent)),
              ),
            const SizedBox(height: 30),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SignupScreen()),
                );
              },
              child: const Text('Don\'t have an account? Sign Up', style: TextStyle(color: Colors.white54)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.white54),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildLoginButton() {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 60,
      borderRadius: 20,
      blur: 20,
      alignment: Alignment.center,
      border: 1,
      linearGradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF00D2FF)]),
      borderGradient: LinearGradient(colors: [Colors.white.withValues(alpha: 0.5), Colors.white.withValues(alpha: 0.2)]),
      child: InkWell(
        onTap: () {
          ref.read(authProvider.notifier).login(_usernameController.text, _passwordController.text);
        },
        child: const Center(
          child: Text('Login', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ),
    );
  }
}
