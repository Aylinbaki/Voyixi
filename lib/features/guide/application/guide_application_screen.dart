// lib/features/guide/application/guide_application_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/guide_application_model.dart';
import 'guide_application_service.dart';

class GuideApplicationScreen extends StatefulWidget {
  const GuideApplicationScreen({super.key});

  @override
  State<GuideApplicationScreen> createState() => _GuideApplicationScreenState();
}

class _GuideApplicationScreenState extends State<GuideApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _aboutCtrl = TextEditingController();
  final _tourIdeasCtrl = TextEditingController();

  final List<String> _allLanguages = [
    'Turkish', 'English', 'German', 'French',
    'Spanish', 'Arabic', 'Russian', 'Japanese', 'Chinese',
  ];
  final List<String> _selectedLanguages = ['Turkish'];
  bool _saving = false;
  bool _alreadyApplied = false;
  bool _checking = true;

  static const _teal = Color(0xFF00BFA5);
  static const _tealDark = Color(0xFF00897B);
  static const _bg = Color(0xFFF0FAFA);
  static const _textDark = Color(0xFF1A2E2E);
  static const _textMid = Color(0xFF4A6060);
  static const _divider = Color(0xFFE0F0EF);

  @override
  void initState() {
    super.initState();
    _checkExisting();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _emailCtrl.text = user.email ?? '';
      _nameCtrl.text = user.displayName ?? '';
    }
  }

  @override
  void dispose() {
    for (final c in [_nameCtrl, _emailCtrl, _phoneCtrl, _cityCtrl,
      _ageCtrl, _aboutCtrl, _tourIdeasCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _checkExisting() async {
    final has = await GuideApplicationService().hasApplied();
    setState(() { _alreadyApplied = has; _checking = false; });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLanguages.isEmpty) {
      _snack('Please select at least one language', error: true);
      return;
    }

    setState(() => _saving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final ref = FirebaseFirestore.instance
          .collection('guide_applications')
          .doc();

      final app = GuideApplication(
        id: ref.id,
        userId: uid,
        fullName: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim().replaceAll(RegExp(r'\s+'), ''),
        city: _cityCtrl.text.trim(),
        age: int.tryParse(_ageCtrl.text.trim()) ?? 0,
        languages: _selectedLanguages,
        about: _aboutCtrl.text.trim(),
        tourIdeas: _tourIdeasCtrl.text.trim(),
        createdAt: DateTime.now(),
      );

      await GuideApplicationService().submitApplication(app);
      if (mounted) {
        setState(() => _alreadyApplied = true);
        _snack('Application submitted! You will be notified after review 🎉');
      }
    } catch (e) {
      _snack('Error: $e', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.red : _teal,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(),
      body: _checking
          ? const Center(child: CircularProgressIndicator(color: _teal))
          : _alreadyApplied
          ? _buildAlreadyApplied()
          : _buildForm(),
    );
  }

  // ── FIX: AppBar Logo Sorunu Çözüldü ────────────────────────────────────
  AppBar _buildAppBar() => AppBar(
    backgroundColor: _bg,
    elevation: 0,
    centerTitle: true,
    leading: GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _teal.withOpacity(0.12),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.arrow_back_ios_new_rounded,
            color: _teal, size: 18),
      ),
    ),
    title: const Text('Guide Application',
        style: TextStyle(
            color: _textDark,
            fontWeight: FontWeight.w700,
            fontSize: 17)),
    actions: [
      Padding(
        padding: const EdgeInsets.only(right: 16),
        child: SizedBox(
          width: 80, // Sıkışmayı önleyen genişlik kısıtlaması
          child: Image.asset(
            'assets/images/app_logo_plan.png',
            fit: BoxFit.contain, // Orantılı sığdırma modu
            errorBuilder: (_, __, ___) => const Icon(
                Icons.explore_rounded,
                color: _teal),
          ),
        ),
      ),
    ],
  );

  Widget _buildAlreadyApplied() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: _teal.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outline_rounded,
                color: _teal, size: 40),
          ),
          const SizedBox(height: 20),
          const Text('Application Received!',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _textDark)),
          const SizedBox(height: 10),
          const Text(
            'Your application is being reviewed by the admin.\nYou will gain access to the guide panel once approved.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: _textMid, fontSize: 14, height: 1.6),
          ),
        ],
      ),
    ),
  );

  Widget _buildForm() => Form(
    key: _formKey,
    child: ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF00BFA5), Color(0xFF00897B)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(children: [
            Icon(Icons.info_outline_rounded,
                color: Colors.white, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'As a guide, you can create tours on VOYIXI and guide tourists around.',
                style: TextStyle(
                    color: Colors.white, fontSize: 13, height: 1.4),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 20),

        _sectionTitle('Personal Information'),
        _field(_nameCtrl, 'Full Name', Icons.person_outline_rounded, required: true),
        _field(_emailCtrl, 'Email', Icons.mail_outline_rounded,
            required: true, keyboardType: TextInputType.emailAddress),

        _field(
          _phoneCtrl,
          'Phone',
          Icons.phone_outlined,
          required: true,
          keyboardType: TextInputType.phone,
          customValidator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Phone number is required';
            }
            final cleanPhone = value.trim().replaceAll(RegExp(r'\s+'), '');
            if (!RegExp(r'^\d{11}$').hasMatch(cleanPhone)) {
              return 'Phone must be an 11-digit number sequence (e.g., 05xxxxxxxxx)';
            }
            return null;
          },
        ),

        _field(
          _ageCtrl,
          'Age',
          Icons.cake_outlined,
          keyboardType: TextInputType.number,
          customValidator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Age is required';
            }
            final age = int.tryParse(value.trim());
            if (age == null) {
              return 'Please enter a valid age';
            }
            if (age < 18) {
              return 'You must be at least 18 years old to become a guide';
            }
            return null;
          },
        ),
        _field(_cityCtrl, 'The City You Guide In', Icons.location_on_outlined, required: true),

        const SizedBox(height: 20),
        _sectionTitle('Languages You Speak'),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: _allLanguages.map((lang) {
            final sel = _selectedLanguages.contains(lang);
            return GestureDetector(
              onTap: () => setState(() {
                sel ? _selectedLanguages.remove(lang) : _selectedLanguages.add(lang);
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: sel ? _teal : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: sel ? _teal : _divider),
                ),
                child: Text(lang,
                    style: TextStyle(
                        color: sel ? Colors.white : _textMid,
                        fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                        fontSize: 13)),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        _sectionTitle('About You'),
        _multilineField(
          _aboutCtrl,
          'Tell us about yourself and your experience...',
          hint: 'How many years have you been guiding? What are your specialties?',
          minLines: 4,
        ),
        const SizedBox(height: 16),

        _sectionTitle('Your Tour Ideas'),
        _multilineField(
          _tourIdeasCtrl,
          'Describe the tours you want to conduct...',
          hint: 'Which routes and what kind of tours are you planning to organize?',
          minLines: 3,
        ),
        const SizedBox(height: 28),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saving ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: _teal,
              disabledBackgroundColor: _divider,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: _saving
                ? const SizedBox(
                width: 22, height: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : const Text('Submit Application',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 20),
      ],
    ),
  );

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(title.toUpperCase(),
        style: const TextStyle(
            color: _tealDark,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2)),
  );

  Widget _field(
      TextEditingController ctrl,
      String label,
      IconData icon, {
        bool required = false,
        TextInputType keyboardType = TextInputType.text,
        String? Function(String?)? customValidator,
      }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: ctrl,
          keyboardType: keyboardType,
          validator: customValidator ?? (required
              ? (v) => (v == null || v.trim().isEmpty) ? '$label is required' : null
              : null),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: _textMid, fontSize: 14),
            prefixIcon: Icon(icon, color: _teal, size: 20),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _divider)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _divider)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _teal, width: 1.5)),
          ),
        ),
      );

  Widget _multilineField(
      TextEditingController ctrl,
      String label, {
        String? hint,
        int minLines = 3,
      }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: ctrl,
          maxLines: null,
          minLines: minLines,
          validator: (v) => (v == null || v.trim().isEmpty) ? '$label is required' : null,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            alignLabelWithHint: true,
            labelStyle: const TextStyle(color: _textMid, fontSize: 14),
            hintStyle: const TextStyle(color: Color(0xFF8AABAB), fontSize: 12),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _divider)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _divider)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _teal, width: 1.5)),
          ),
        ),
      );
}