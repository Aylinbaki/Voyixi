// lib/features/guide/application/guide_application_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/guide_application_model.dart';
import 'guide_application_service.dart';

class GuideApplicationScreen extends StatefulWidget {
  const GuideApplicationScreen({super.key});

  @override
  State<GuideApplicationScreen> createState() =>
      _GuideApplicationScreenState();
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
    'Türkçe', 'İngilizce', 'Almanca', 'Fransızca',
    'İspanyolca', 'Arapça', 'Rusça', 'Japonca', 'Çince',
  ];
  final List<String> _selectedLanguages = ['Türkçe'];
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
      _snack('En az bir dil seçin', error: true);
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
        phone: _phoneCtrl.text.trim().replaceAll(RegExp(r'\s+'), ''), // Boşlukları temizleyerek kaydet
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
        _snack('Başvurunuz alındı! İnceleme sonucu size bildirilecek 🎉');
      }
    } catch (e) {
      _snack('Hata: $e', error: true);
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
        title: const Text('Rehber Başvurusu',
            style: TextStyle(
                color: _textDark,
                fontWeight: FontWeight.w700,
                fontSize: 17)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Image.asset('assets/images/app_logo_plan.png',
                height: 30,
                errorBuilder: (_, __, ___) => const Icon(
                    Icons.explore_rounded,
                    color: _teal)),
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
              const Text('Başvurunuz Alındı!',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _textDark)),
              const SizedBox(height: 10),
              const Text(
                'Başvurunuz admin tarafından inceleniyor.\nOnaylandığında rehber paneline erişim sağlayacaksınız.',
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
                    'Rehber olarak VOYIXI\'da tur oluşturabilir ve turistlere rehberlik yapabilirsiniz.',
                    style: TextStyle(
                        color: Colors.white, fontSize: 13, height: 1.4),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 20),

            _sectionTitle('Kişisel Bilgiler'),
            _field(_nameCtrl, 'Ad Soyad', Icons.person_outline_rounded,
                required: true),
            _field(_emailCtrl, 'E-posta', Icons.mail_outline_rounded,
                required: true, keyboardType: TextInputType.emailAddress),
            
            // --- GÜNCELLEME: Telefon Alanı Doğrulaması ---
            _field(
              _phoneCtrl, 
              'Telefon', 
              Icons.phone_outlined,
              required: true, 
              keyboardType: TextInputType.phone,
              customValidator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Telefon gerekli';
                }
                // Kullanıcı boşluk bıraktıysa onları temizleyip kontrol ediyoruz
                final cleanPhone = value.trim().replaceAll(RegExp(r'\s+'), '');
                // Sadece rakamlardan oluşan tam 11 haneli RegExp kontrolü
                if (!RegExp(r'^\d{11}$').hasMatch(cleanPhone)) {
                  return 'Telefon 11 haneli bir sayı dizisi olmalıdır (örn: 05xxxxxxxxx)';
                }
                return null;
              },
            ),
            
            _field(
  _ageCtrl, 
  'Yaş', 
  Icons.cake_outlined,
  keyboardType: TextInputType.number,
  customValidator: (value) {
    if (value == null || value.trim().isEmpty) {
      return 'Yaş gerekli';
    }
    
    // Girilen metni sayıya çevirmeyi deniyoruz
    final age = int.tryParse(value.trim());
    
    if (age == null) {
      return 'Geçerli bir yaş giriniz';
    }
    
    // 18 yaş kontrolü
    if (age < 18) {
      return 'Rehber olabilmek için en az 18 yaşında olmalısınız';
    }
    
    return null; // Her şey yolundaysa hata döndürme
  },
),
            _field(_cityCtrl, 'Rehberlik Yaptığınız Şehir',
                Icons.location_on_outlined, required: true),

            const SizedBox(height: 20),
            _sectionTitle('Konuştuğunuz Diller'),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _allLanguages.map((lang) {
                final sel = _selectedLanguages.contains(lang);
                return GestureDetector(
                  onTap: () => setState(() {
                    sel
                        ? _selectedLanguages.remove(lang)
                        : _selectedLanguages.add(lang);
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? _teal : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: sel ? _teal : _divider),
                    ),
                    child: Text(lang,
                        style: TextStyle(
                            color: sel ? Colors.white : _textMid,
                            fontWeight: sel
                                ? FontWeight.w600
                                : FontWeight.w400,
                            fontSize: 13)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            _sectionTitle('Hakkınızda'),
            _multilineField(
              _aboutCtrl,
              'Kendinizi ve deneyimlerinizi anlatın...',
              hint: 'Kaç yıldır rehberlik yapıyorsunuz? Uzmanlık alanlarınız neler?',
              minLines: 4,
            ),
            const SizedBox(height: 16),

            _sectionTitle('Tur Fikirleriniz'),
            _multilineField(
              _tourIdeasCtrl,
              'Yapmak istediğiniz turları anlatın...',
              hint: 'Hangi rotaları, ne tür turları planlamak istiyorsunuz?',
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
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : const Text('Başvuruyu Gönder',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
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

  // --- GÜNCELLEME: customValidator parametresi eklendi ---
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
          // Eğer dışarıdan özel validator verildiyse onu kullan, yoksa default boş kontrolünü yap
          validator: customValidator ?? (required
              ? (v) => (v == null || v.trim().isEmpty) ? '$label gerekli' : null
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
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? '$label gerekli' : null,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            alignLabelWithHint: true,
            labelStyle: const TextStyle(color: _textMid, fontSize: 14),
            hintStyle:
                const TextStyle(color: Color(0xFF8AABAB), fontSize: 12),
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