import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glassmorphism/glassmorphism.dart';
import '../../providers/auth_provider.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'reader';

  @override
  Widget build(BuildContext context) {
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
              'Join Srishty',
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: 1.5),
            ),
            const SizedBox(height: 10),
            const Text('Start your creative journey.', style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 50),
            _buildTextField(_usernameController, 'Username', Icons.person_outline),
            const SizedBox(height: 20),
            _buildTextField(_emailController, 'Email', Icons.email_outlined),
            const SizedBox(height: 20),
            _buildTextField(_passwordController, 'Password', Icons.lock_outline, isPassword: true),
            const SizedBox(height: 20),
            _buildRoleDropdown(),
            const SizedBox(height: 40),
            if (ref.watch(authProvider).status == AuthStatus.loading)
              const CircularProgressIndicator()
            else
              _buildSignupButton(),
            if (ref.watch(authProvider).errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(ref.watch(authProvider).errorMessage!, style: const TextStyle(color: Colors.redAccent)),
              ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Already have an account? Login', style: TextStyle(color: Color(0xFF6C63FF))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedRole,
          dropdownColor: const Color(0xFF1E1E2E),
          style: const TextStyle(color: Colors.white),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white54),
          isExpanded: true,
          onChanged: (String? newValue) {
            setState(() {
              _selectedRole = newValue!;
            });
          },
          items: <String>['reader', 'author']
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value.toUpperCase()),
            );
          }).toList(),
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

  Widget _buildSignupButton() {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 60,
      borderRadius: 20,
      blur: 20,
      alignment: Alignment.center,
      border: 1,
      linearGradient: const LinearGradient(colors: [Color(0xFF00D2FF), Color(0xFF6C63FF)]),
      borderGradient: LinearGradient(colors: [Colors.white.withValues(alpha: 0.5), Colors.white.withValues(alpha: 0.2)]),
      child: InkWell(
        onTap: () async {
          final success = await ref.read(authProvider.notifier).register(
            _usernameController.text,
            _emailController.text,
            _passwordController.text,
            _selectedRole,
          );
          if (success) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Signup successful! Please login.')),
              );
              Navigator.pop(context);
            }
          }
        },
        child: const Center(
          child: Text('Create Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ),
    );
  }
}
