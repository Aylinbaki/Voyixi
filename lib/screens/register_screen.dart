import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:firebase_auth/firebase_auth.dart';


class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const _bgColor     = Color(0xFF0A1628);
  static const _primaryBlue = Color(0xFF1E88E5);
  static const _accentBlue  = Color(0xFF42A5F5);
  static const _fieldBg     = Color(0xFF112244);
  static const _fieldBorder = Color(0xFF1E3A5F);
  static const _white       = Color(0xFFFFFFFF);
  static const _muted       = Color(0x99FFFFFF);
  static const _hint        = Color(0x55FFFFFF);
  static const _errorRed    = Color(0xFFE24B4A);

  final _formKey             = GlobalKey<FormState>();
  final _nameCtrl            = TextEditingController();
  final _emailCtrl           = TextEditingController();
  final _passwordCtrl        = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool  _hidePassword        = true;
  bool  _hideConfirmPassword = true;
  bool  _acceptedTerms       = false;
  bool  _isLoading           = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
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
                  const SizedBox(height: 48),
                  _logo(),
                  const SizedBox(height: 28),
                  _divider(),
                  const SizedBox(height: 24),
                  _header(),
                  const SizedBox(height: 22),
                  _nameField(),
                  const SizedBox(height: 12),
                  _emailField(),
                  const SizedBox(height: 12),
                  _passwordField(),
                  const SizedBox(height: 12),
                  _confirmPasswordField(),
                  const SizedBox(height: 16),
                  _termsRow(),
                  const SizedBox(height: 24),
                  _registerBtn(),
                  const SizedBox(height: 32),
                  _signInRow(),
                  const SizedBox(height: 36),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── LOGO ──────────────────────────────────────────────────────────────────
  Widget _logo() {
    return Column(
      children: [
        Image.asset(
          'assets/images/app_logo_nobg.png',
          width: 72,
          height: 72,
        ),
        const SizedBox(height: 14),
        const Text(
          'VOYIXI',
          style: TextStyle(
            color: _white,
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: 7,
          ),
        ),
        const SizedBox(height: 4),
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
          'Create account',
          style: TextStyle(
            color: _white,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Start your adventure today',
          style: TextStyle(color: _muted, fontSize: 13),
        ),
      ],
    );
  }

  // ── FORM ALANLARI ─────────────────────────────────────────────────────────
  Widget _nameField() {
    return TextFormField(
      controller: _nameCtrl,
      keyboardType: TextInputType.name,
      textInputAction: TextInputAction.next,
      textCapitalization: TextCapitalization.words,
      style: const TextStyle(color: _white, fontSize: 14),
      decoration: _decoration(
        hint: 'Full name',
        icon: Icons.person_outline_rounded,
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Name is required';
        if (v.trim().length < 2) return 'Enter a valid name';
        return null;
      },
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
        icon: Icons.mail_outline_rounded,
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
      textInputAction: TextInputAction.next,
      style: const TextStyle(color: _white, fontSize: 14),
      decoration: _decoration(
        hint: 'Password',
        icon: Icons.lock_outline_rounded,
        suffix: IconButton(
          icon: Icon(
            _hidePassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: _muted,
            size: 20,
          ),
          onPressed: () => setState(() => _hidePassword = !_hidePassword),
        ),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Password is required';
        if (v.length < 6) return 'Minimum 6 characters';
        if (!RegExp(r'^(?=.*[A-Z])(?=.*\d).+$').hasMatch(v)) {
          return 'Must contain uppercase letter and number';
        }
        return null;
      },
    );
  }

  Widget _confirmPasswordField() {
    return TextFormField(
      controller: _confirmPasswordCtrl,
      obscureText: _hideConfirmPassword,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _register(),
      style: const TextStyle(color: _white, fontSize: 14),
      decoration: _decoration(
        hint: 'Confirm password',
        icon: Icons.lock_outline_rounded,
        suffix: IconButton(
          icon: Icon(
            _hideConfirmPassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: _muted,
            size: 20,
          ),
          onPressed: () =>
              setState(() => _hideConfirmPassword = !_hideConfirmPassword),
        ),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Please confirm your password';

        if (v != _passwordCtrl.text) return 'Passwords do not match';
        return null;
      },
    );
  }

  // ── DECORATION HELPER ─────────────────────────────────────────────────────
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
      hintStyle: const TextStyle(color: _hint, fontSize: 13),
      prefixIcon: Icon(icon, color: _muted, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: _fieldBg,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      border:             border(_fieldBorder, 0.5),
      enabledBorder:      border(_fieldBorder, 0.5),
      focusedBorder:      border(_primaryBlue, 1.5),
      errorBorder:        border(_errorRed, 1.0),
      focusedErrorBorder: border(_errorRed, 1.5),
      errorStyle: const TextStyle(color: _errorRed, fontSize: 11),
    );
  }

  // ── TERMS & CONDITIONS ────────────────────────────────────────────────────
  Widget _termsRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: Checkbox(
            value: _acceptedTerms,
            onChanged: (v) => setState(() => _acceptedTerms = v ?? false),
            activeColor: _primaryBlue,
            checkColor: _white,
            side: const BorderSide(color: _fieldBorder),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          //  RichText: "Terms of Service" ve "Privacy Policy" linkleri tıklanabilir olacak
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: _muted, fontSize: 12),
              children: [
                const TextSpan(text: 'I agree to the '),
                TextSpan(
                  text: 'Terms of Service',
                  style: const TextStyle(
                    color: _accentBlue,
                    fontWeight: FontWeight.w500,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      // TODO: terms sayfasına git veya webview aç
                    },
                ),
                const TextSpan(text: ' and '),
                TextSpan(
                  text: 'Privacy Policy',
                  style: const TextStyle(
                    color: _accentBlue,
                    fontWeight: FontWeight.w500,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      // TODO: privacy sayfasına git veya webview aç
                    },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── REGISTER BUTONU ───────────────────────────────────────────────────────
  Widget _registerBtn() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _register,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryBlue,
          disabledBackgroundColor: _primaryBlue.withOpacity(0.45),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            color: _white,
            strokeWidth: 2.5,
          ),
        )
            : const Text(
          'CREATE ACCOUNT',
          style: TextStyle(
            color: _white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  // ── SIGN IN SATIRI ────────────────────────────────────────────────────────
  Widget _signInRow() {
    return RichText(
      text: TextSpan(
        text: 'Already have an account?  ',
        style: const TextStyle(color: _muted, fontSize: 13),
        children: [
          TextSpan(
            text: 'Sign in',
            style: const TextStyle(
              color: _accentBlue,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                Navigator.pop(context);
              },
          ),
        ],
      ),
    );
  }

  // ── REGISTER İŞLEMİ ───────────────────────────────────────────────────────
  Future<void> _register() async {
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Please accept the Terms of Service',
            style: TextStyle(color: _white),
          ),
          backgroundColor: _errorRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
       await FirebaseAuth.instance.createUserWithEmailAndPassword(
         email: _emailCtrl.text.trim(),
         password: _passwordCtrl.text,
       );
      // Kullanıcı profilini güncelle (display name)
       await FirebaseAuth.instance.currentUser?.updateDisplayName(
         _nameCtrl.text.trim(),
       );
       if (mounted) Navigator.pushReplacementNamed(context, '/home');

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString(),
            style: const TextStyle(color: _white),
          ),
          backgroundColor: _errorRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}