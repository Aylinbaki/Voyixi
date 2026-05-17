import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../services/user_service.dart';

const _teal     = Color(0xFF00BFA5);
const _tealDark = Color(0xFF00897B);

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final user = FirebaseAuth.instance.currentUser;
  late TextEditingController _nameController;
  late TextEditingController _countryController;
  late TextEditingController _cityController;
  XFile? _pickedImage; // seçilen fotoğrafı tutar
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController    = TextEditingController(text: user?.displayName ?? '');
    _countryController = TextEditingController(text: '');
    _cityController    = TextEditingController(text: '');

    if (user != null) {
      UserService().userStream(user!.uid).first.then((data) {
        if (mounted) {
          setState(() {
            _countryController.text = data['country'] ?? '';
            _cityController.text    = data['city']    ?? '';
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 225, 239, 239),
      appBar: AppBar(
        title: const Text(
          'Profili Düzenle',
          style: TextStyle(color: Color(0xFF1A2E2E), fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 225, 239, 239),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _teal, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Avatar
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: _teal.withOpacity(0.15),
                    child: ClipOval(
                      child: _pickedImage != null
                      // Galeriden seçilen yeni fotoğraf
                          ? Image.file(
                        File(_pickedImage!.path),
                        width: 120, height: 120,
                        fit: BoxFit.cover,
                      )
                          : user?.photoURL != null
                      // Firebase'deki mevcut fotoğraf
                          ? Image.network(
                        user!.photoURL!,
                        width: 120, height: 120,
                        fit: BoxFit.cover,
                      )
                      // Hiç fotoğraf yok
                          : Container(
                        width: 120, height: 120,
                        color: _teal.withOpacity(0.10),
                        child: Icon(Icons.person, color: _teal, size: 52),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () async { //kamera
                        final img = await _picker.pickImage(
                          source: ImageSource.gallery,
                          imageQuality: 80, // dosya boyutunu küçültür
                        );
                        if (img != null) setState(() => _pickedImage = img);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: _teal,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 36),

            // Alan kartı — Settings'deki _card() stili
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: _teal.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildEditField('İsim Soyisim', _nameController),
                  const SizedBox(height: 18),
                  _buildEditField(
                    'E-posta',
                    TextEditingController(text: user?.email ?? ''),
                    enabled: false,
                  ),
                  const SizedBox(height: 18),
                  _buildEditField('Ülke', _countryController),
                  const SizedBox(height: 18),
                  _buildEditField('Şehir', _cityController),
                ],
              ),
            ),

            const SizedBox(height: 36),
            // Güncelle butonu — Settings'deki _actionButton stili
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    // 1. Firebase Auth displayName güncelle
                    await user?.updateDisplayName(_nameController.text);
                    await user?.reload();
                    // 2. Firestore'a city ve country yaz
                    if (user != null) {
                      await UserService().updateProfile(
                        uid:     user!.uid,
                        name:    _nameController.text,
                        city:    _cityController.text,
                        country: _countryController.text,
                      );
                    }
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Profil başarıyla güncellendi!'),
                          backgroundColor: _teal,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      Navigator.pop(context);
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Hata oluştu: $e')),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _teal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text(
                  'Güncelle',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditField(
      String label,
      TextEditingController controller, {
        bool enabled = true,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 11,
            color: _tealDark,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          style: TextStyle(
            color: enabled ? const Color(0xFF1A2E2E) : Colors.grey,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: enabled ? Colors.grey[50] : Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _teal, width: 1.5),
            ),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}