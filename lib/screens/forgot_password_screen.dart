import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:firebase_auth/firebase_auth.dart';


class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  static const _bgColor     = Color(0xFF0A1628);
  static const _primaryBlue = Color(0xFF1E88E5);
  static const _accentBlue  = Color(0xFF42A5F5);
  static const _fieldBg     = Color(0xFF112244);
  static const _fieldBorder = Color(0xFF1E3A5F);
  static const _white       = Color(0xFFFFFFFF);
  static const _muted       = Color(0x99FFFFFF);
  static const _hint        = Color(0x55FFFFFF);
  static const _errorRed    = Color(0xFFE24B4A);
  static const _successGreen= Color(0xFF43A047);

  // ── State ─────────────────────────────────────────────────────────────────
  final _formKey    = GlobalKey<FormState>();
  final _emailCtrl  = TextEditingController();
  bool  _isLoading  = false;
  bool  _emailSent  = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 48),
                _logo(),
                const SizedBox(height: 28),
                _divider(),
                const SizedBox(height: 32),
                _emailSent ? _successView() : _formView(),
                const SizedBox(height: 40),
              ],
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

  // ── FORM GÖRÜNÜMÜ ─────────────────────────────────────────────────────────
  Widget _formView() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _primaryBlue.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: _primaryBlue.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.lock_reset_rounded,
              color: _accentBlue,
              size: 34,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Reset password',
            style: TextStyle(
              color: _white,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Enter your email address and we'll\nsend you a reset link.",
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, fontSize: 13, height: 1.6),
          ),
          const SizedBox(height: 28),
          _emailField(),
          const SizedBox(height: 24),
          _sendBtn(),
          const SizedBox(height: 28),
          _backToLoginRow(),
        ],
      ),
    );
  }

  // ── BAŞARI GÖRÜNÜMÜ ───────────────────────────────────────────────────────
  Widget _successView() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: _successGreen.withOpacity(0.12),
            shape: BoxShape.circle,
            border: Border.all(
              color: _successGreen.withOpacity(0.4),
              width: 1,
            ),
          ),
          child: const Icon(
            Icons.mark_email_read_outlined,
            color: _successGreen,
            size: 38,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Email sent!',
          style: TextStyle(
            color: _white,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'We sent a reset link to\n${_emailCtrl.text.trim()}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: _muted, fontSize: 13, height: 1.6),
        ),
        const SizedBox(height: 8),
        const Text(
          "Check your spam folder if you don't see it.",
          textAlign: TextAlign.center,
          style: TextStyle(color: _muted, fontSize: 12),
        ),
        const SizedBox(height: 32),
        // Tekrar gönder butonu
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            onPressed: () => setState(() => _emailSent = false),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: _fieldBorder, width: 0.5),
              backgroundColor: _fieldBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'RESEND EMAIL',
              style: TextStyle(
                color: _accentBlue,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _backToLoginRow(),
      ],
    );
  }

  // ── EMAIL ALANI ───────────────────────────────────────────────────────────
  Widget _emailField() {
    return TextFormField(
      controller: _emailCtrl,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _sendResetLink(),
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

  // ── DECORATION HELPER ─────────────────────────────────────────────────────
  InputDecoration _decoration({
    required String hint,
    required IconData icon,
  }) {
    OutlineInputBorder border(Color c, double w) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: c, width: w),
    );

    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _hint, fontSize: 13),
      prefixIcon: Icon(icon, color: _muted, size: 20),
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

  // ── SEND BUTONU ───────────────────────────────────────────────────────────
  Widget _sendBtn() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _sendResetLink,
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
          'SEND RESET LINK',
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

  // ── GERİ DÖN SATIRI ───────────────────────────────────────────────────────
  Widget _backToLoginRow() {
    return RichText(
      text: TextSpan(
        text: 'Remember it?  ',
        style: const TextStyle(color: _muted, fontSize: 13),
        children: [
          TextSpan(
            text: 'Back to login',
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

  // ── RESET LINK İŞLEMİ ────────────────────────────────────────────────────
  // NEDEN setState(() => _emailSent = true):
  //   Firebase email gönderince hata fırlatmaz, sadece işlemi tamamlar.
  //   Başarılı olunca _emailSent = true yaparak başarı ekranını gösteriyoruz.
  Future<void> _sendResetLink() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
          email: _emailCtrl.text.trim(),
      );
      await Future.delayed(const Duration(seconds: 2)); // geçici simülasyon

      if (mounted) setState(() => _emailSent = true); //mounted -> memory leak önler
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