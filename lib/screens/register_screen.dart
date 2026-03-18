import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _isObscured = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity, //!!!! renk alta kadar gitmiyor koymazsak
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
              // Geri Dön Butonu
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF00838F)),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(height: 20),
              const Text('VOYIXI', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Color(0xFF00838F), letterSpacing: 2)),
              // Name Girişi (Yeni eklendi)
              _buildTextField(label: 'Name', icon: Icons.person_outline),
              const SizedBox(height: 20),
              // Surname Girişi (Yeni eklendi)
              _buildTextField(label: 'Surname', icon: Icons.person_add_alt_1_outlined),
              const SizedBox(height: 20),
              // Email Girişi
              _buildTextField(label: 'Email', icon: Icons.email_outlined),
              const SizedBox(height: 20),
              _buildTextField(
                label: 'Password',
                icon: Icons.lock_outline,
                isPassword: true,
                onSuffixIconPressed: () => setState(() => _isObscured = !_isObscured),
              ),
              const SizedBox(height: 40),
              _buildRegisterButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({required String label, required IconData icon, bool isPassword = false, VoidCallback? onSuffixIconPressed}) {
    return TextField(
      obscureText: isPassword ? _isObscured : false,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF00838F)),
        suffixIcon: isPassword ? IconButton(icon: Icon(_isObscured ? Icons.visibility_off : Icons.visibility), onPressed: onSuffixIconPressed) : null,
        labelText: label,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.9),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF263238),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        onPressed: () {},
        child: const Text("Register", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}