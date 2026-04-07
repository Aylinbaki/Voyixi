import 'package:flutter/material.dart';
import 'package:voyixi/services/auth_service.dart';
import 'package:voyixi/services/user_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}
class _RegisterScreenState extends State<RegisterScreen> {
  bool _isObscured = true;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final authService = AuthService();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFB2EBF2), Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            children: [
              const SizedBox(height: 60),
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF00838F)),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'VOYIXI',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00838F),
                  letterSpacing: 2,
                ),
              ),
              _buildTextField(
                label: 'Name',
                icon: Icons.person_outline,
                controller: _nameController,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                label: 'Surname',
                icon: Icons.person_add_alt_1_outlined,
                controller: _surnameController,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                label: 'Email',
                icon: Icons.email_outlined,
                controller: _emailController,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                label: 'Password',
                icon: Icons.lock_outline,
                isPassword: true,
                controller: _passwordController,
                onSuffixIconPressed: () =>
                    setState(() => _isObscured = !_isObscured),
              ),

              const SizedBox(height: 40),

              _buildRegisterButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    bool isPassword = false,
    VoidCallback? onSuffixIconPressed,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? _isObscured : false,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF00838F)),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                    _isObscured ? Icons.visibility_off : Icons.visibility),
                onPressed: onSuffixIconPressed)
            : null,
        labelText: label,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
  // register mantığı
  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF263238),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        onPressed: () async {
          if (_nameController.text.isEmpty ||
              _surnameController.text.isEmpty ||
              _emailController.text.isEmpty ||
              _passwordController.text.isEmpty) {
            _showMessage("Please fill all fields");
            return;
          }
          var user = await authService.signUp(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );
          if (user != null) {
            try {
              await user.updateDisplayName(
                "${_nameController.text} ${_surnameController.text}",
              );
              await user.reload(); 
              // fierstore kaydı
              await UserService().saveUser(user);
            } catch (e) {
              print(e);
              _showMessage("Kayıt tamamlandı ama kullanıcı verisi kaydedilemedi.");
              return;
            }
            _showMessage("Registration successful");
            Navigator.pushReplacementNamed(context, "/home");
          } else {
            _showMessage("Registration failed");
          }
        },
        child: const Text(
          "Register",
          style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}