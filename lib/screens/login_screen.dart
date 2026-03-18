import 'package:flutter/material.dart';
import 'package:voyixi/screens/register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isObscured = true; // Şifre gizleme kontrolü
  bool _termsAccepted = false; // Şartların kabulü

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Arka planın klavye açıldığında bozulmaması için false yapıyoruz
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            // Gradyanın tüm ekrana yayılması için renkleri netleştiriyoruz
            colors: [Color(0xFFB2EBF2), Colors.white],
            stops: [0.0, 1.0],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 60),
                        const Text(
                          'VOYIXI',
                          style: TextStyle(
                            fontSize: 60,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00838F),
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 60),
                        // Email
                        _buildTextField(
                          label: 'Email',
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 20),
                        // Şifre
                        _buildTextField(
                          label: 'Password',
                          icon: Icons.lock_outline,
                          isPassword: true,
                          onSuffixIconPressed: () =>
                              setState(() => _isObscured = !_isObscured),
                        ),
                        const SizedBox(height: 10),
                        _buildActionRow(),
                        const SizedBox(height: 30),
                        _buildLoginButton(),
                        const Spacer(), // İçeriği yukarı iter, alt kısmı sabit tutar
                        const SizedBox(height: 20),
                        _buildSignUpPrompt(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    bool isPassword = false,
    VoidCallback? onSuffixIconPressed,
  }) {
    return TextField(
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
        labelStyle: const TextStyle(color: Colors.blueGrey),
        filled: true,
        fillColor: Colors.white.withAlpha(230), // Güncel kullanım
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildActionRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Checkbox(
              value: _termsAccepted,
              onChanged: (v) => setState(() => _termsAccepted = v!),
              activeColor: const Color(0xFF00838F),
            ),
            const Text("I have read the terms", style: TextStyle(fontSize: 12)),
          ],
        ),
        TextButton(
          onPressed: () {},
          child: const Text("Forget Password",
              style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF263238),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 5,
        ),
        onPressed: () {},
        child: const Text("Login",
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSignUpPrompt() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Don't you have an account? ",
            style: TextStyle(fontSize: 13)),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RegisterScreen()),
            );
          },
          child: const Text("Sign up",
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00838F))),
        ),
      ],
    );
  }
}