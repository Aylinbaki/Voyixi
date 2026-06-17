import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const _bgColor     = Color(0xFF0A1628);
  static const _primaryBlue = Color(0xFF1E88E5);
  static const _accentBlue  = Color(0xFF42A5F5);
  static const _fieldBg     = Color(0xFF112244);
  static const _fieldBorder = Color(0xFF1E3A5F);
  static const _white       = Color(0xFFFFFFFF);
  static const _muted       = Color(0x99FFFFFF);
  static const _errorRed    = Color(0xFFE24B4A);

  // ── State ─────────────────────────────────────────────────────────────────
  final _formKey            = GlobalKey<FormState>();
  final _emailCtrl          = TextEditingController();
  final _passwordCtrl       = TextEditingController();
  
  bool  _hidePassword       = true; // direkt açık gözükür
  bool  _rememberMe         = false;
  bool  _isLoading          = false;
  bool _googleLoading       = false;

  final _auth        = AuthService();
  final _userService = UserService();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 52),
                  _logo(),
                  const SizedBox(height: 32),
                  _divider(),
                  const SizedBox(height: 28),
                  _header(),
                  const SizedBox(height: 24),
                  _emailField(),
                  const SizedBox(height: 12),
                  _passwordField(),
                  const SizedBox(height: 14),
                  _rememberForgotRow(),
                  const SizedBox(height: 26),
                  _loginBtn(),
                  const SizedBox(height: 20),
                  _orDivider(),
                  const SizedBox(height: 20),
                  _googleBtn(),
                  const SizedBox(height: 36),
                  _signUpRow(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _logo() {
    return Column(
      children: [
        Image.asset(
          'assets/images/app_logo_nobg.png',
          width: 80,
          height: 80,
        ),
        const SizedBox(height: 16),
        const Text(
          'VOYIXI',
          style: TextStyle(
            color: _white,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: 7,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'SMART TRAVEL ASSISTANT',
          style: TextStyle(color: _muted, fontSize: 10, letterSpacing: 2.5),
        ),
      ],
    );
  }

  Widget _divider() => Container(height: 0.5, color: _fieldBorder);

  Widget _header() {
    return const Column(
      children: [
        Text(
          'Welcome Back',
          style: TextStyle(color: _white, fontSize: 22, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 7),
        Text(
          'Sign in to continue your journey',
          style: TextStyle(color: _muted, fontSize: 13),
        ),
      ],
    );
  }
  Widget _emailField() {
    return TextFormField(
      controller: _emailCtrl,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autocorrect: false,
      style: const TextStyle(color: _white, fontSize: 14),
      decoration: _decoration(
          hint: 'Email address',
          icon: Icons.mail_outline_rounded
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Email is required';
        if (!RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w]{2,4}$').hasMatch(v.trim())) {
          return 'Enter a valid email';
        }
        return null;
      },
    );
  }

  Widget _passwordField() {
    return TextFormField(
      controller: _passwordCtrl,
      obscureText: _hidePassword,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _login(),
      style: const TextStyle(color: _white, fontSize: 14),
      decoration: _decoration(
        hint: 'Password',
        icon: Icons.lock_outline_rounded,
        suffix: IconButton(
          icon: Icon(
            _hidePassword ? Icons .visibility_off_outlined : Icons.visibility_outlined,
            color: _muted,
            size: 20,
          ),
          onPressed: () => setState(() => _hidePassword = !_hidePassword),
        ),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Password is required';
        if (v.length < 6) return 'Minimum 6 characters';
        return null;
      },
    );
  }

  InputDecoration _decoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    OutlineInputBorder border(Color c, double w) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: c, width: w),
    );

    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0x55FFFFFF), fontSize: 13),
      prefixIcon: Icon(icon, color: _muted, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: _fieldBg,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      border:            border(_fieldBorder, 0.5),
      enabledBorder:     border(_fieldBorder, 0.5),
      focusedBorder:     border(_primaryBlue, 1.5),
      errorBorder:       border(_errorRed, 1.0),
      focusedErrorBorder:border(_errorRed, 1.5),
      errorStyle: const TextStyle(color: _errorRed, fontSize: 11),
    );
  }

  Widget _rememberForgotRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Checkbox(
                value: _rememberMe,
                onChanged: (v) => setState(() => _rememberMe = v ?? false),
                activeColor: _primaryBlue,
                checkColor: _white,
                side: const BorderSide(color: _fieldBorder),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(width: 8),
            const Text('Remember me', style: TextStyle(color: _muted, fontSize: 12)),
          ],
        ),
        GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, '/forgot-password');
          },
          child: const Text(
            'Forgot Password',
            style: TextStyle(color: _accentBlue, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _loginBtn() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryBlue,
          disabledBackgroundColor: _primaryBlue.withOpacity(0.45),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isLoading
            ? const SizedBox(
          width: 22, height: 22,
          child: CircularProgressIndicator(color: _white, strokeWidth: 2.5),
        )
            : const Text(
          'LOGIN',
          style: TextStyle(
            color: _white, fontSize: 15,
            fontWeight: FontWeight.w600, letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _orDivider() {
    return Row(
      children: [
        Expanded(child: Container(height: 0.5, color: _fieldBorder)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'OR',
            style: TextStyle(color: _muted, fontSize: 11, letterSpacing: 1.5),
          ),
        ),
        Expanded(child: Container(height: 0.5, color: _fieldBorder)),
      ],
    );
  }

  Widget _googleBtn() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: _googleLoading ? null : _loginWithGoogle,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: _fieldBorder, width: 0.8),
          backgroundColor: _fieldBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _googleLoading
            ? const SizedBox(
          width: 22, height: 22,
          child: CircularProgressIndicator(color: _white, strokeWidth: 2.5),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/google_logo.png', width: 20, height: 20),
            const SizedBox(width: 10),
            const Text(
              'Continue with Google',
              style: TextStyle(
                color: _white, fontSize: 14, fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _signUpRow() {
    return RichText(
      text: TextSpan(
        text: "Don't have an account?  ",
        style: const TextStyle(color: _muted, fontSize: 13),
        children: [
          TextSpan(
            text: 'Sign up',
            style: const TextStyle(
              color: _accentBlue, fontSize: 13, fontWeight: FontWeight.w600,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                Navigator.pushNamed(context, '/register');
              },
          ),
        ],
      ),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final user = await _auth.signIn(
        _emailCtrl.text.trim(),
        _passwordCtrl.text.trim(),
      );

      if (!mounted) return;

      if (user != null) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        _showError('Invalid email or password. Please try again.');
      }
    } catch (e) {
      if (mounted) _showError('An error occurred. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _googleLoading = true);

    try {
      final user = await _auth.signInWithGoogle();

      if (!mounted) return;

      if (user != null) {
        await _userService.saveUser(user);

        if (mounted) Navigator.pushReplacementNamed(context, '/home');
      } else {
        _showError('Google sign-in cancelled or failed. Please try again.');
      }
    } catch (e) {
      if (mounted) _showError('Google sign-in failed. Please try again.');
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: _white)),
        backgroundColor: _errorRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}