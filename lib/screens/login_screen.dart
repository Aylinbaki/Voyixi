import 'package:flutter/material.dart';
import 'package:voyixi/screens/register_screen.dart';
import 'package:voyixi/services/auth_service.dart';
import 'package:voyixi/services/user_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isObscured = true;
  bool _termsAccepted = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
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
                        _buildTextField(
                          label: 'Email',
                          icon: Icons.person_outline,
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

                        const SizedBox(height: 10),
                        _buildActionRow(),

                        const SizedBox(height: 30),
                        _buildLoginButton(),

                        const SizedBox(height: 15),
                        _buildGoogleButton(),

                        const Spacer(),
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
        labelStyle: const TextStyle(color: Colors.blueGrey),
        filled: true,
        fillColor: Colors.white.withAlpha(230),
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
        onPressed: () async {
          if (!_termsAccepted) {
            _showMessage("Please accept the terms");
            return;
          }
          var user = await authService.signIn(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );

          if (user != null) {
            try {
              await UserService().saveUser(user);
            } catch (e) {
              print(e);
              _showMessage("Firestore kullanıcı kaydı başarısız.");
              return;
            }

            if (!context.mounted) return;
            Navigator.pushReplacementNamed(context, "/home");
          } else {
            _showMessage("Login failed");
          }
        },
        child: const Text("Login",
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
      ),
    );
  }

  // google login
  Widget _buildGoogleButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: OutlinedButton(
        onPressed: () async {
          var user = await authService.signInWithGoogle();

          if (user != null) {
            try {
              await UserService().saveUser(user);
            } catch (e) {
              print(e);
              _showMessage("Firestore kullanıcı kaydı başarısız.");
              return;
            }

            if (!context.mounted) return;
            Navigator.pushReplacementNamed(context, "/home");
          } else {
            _showMessage("Google sign-in failed");
          }
        },
        child: const Text("Continue with Google"),
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

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}