import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final user = FirebaseAuth.instance.currentUser;
  late TextEditingController _nameController;
  late TextEditingController _countryController;

  @override
  void initState() {
    super.initState();
    // Kullanıcının mevcut ismini TextField'a yazdırıyoruz
    _nameController = TextEditingController(text: user?.displayName ?? "");
    _countryController = TextEditingController(text: "Türkiye"); // Varsayılan olarak Türkiye
  }

  @override
  void dispose() {
    _nameController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
            "Profili Düzenle",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Profil Fotoğrafı Düzenleme Alanı
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: const Color(0xFF133671),
                    child: CircleAvatar(
                      radius: 57,
                      backgroundImage: NetworkImage(
                          user?.photoURL ?? 'https://via.placeholder.com/150'
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () {
                        // Fotoğraf seçme işlemi buraya gelecek
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFF4CAF50),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            // Giriş Alanları
            _buildEditField("İsim Soyisim", _nameController),
            const SizedBox(height: 20),
            _buildEditField("E-posta", TextEditingController(text: user?.email ?? ""), enabled: false),
            const SizedBox(height: 20),
            _buildEditField("Ülke", _countryController),

            const SizedBox(height: 50),
            // Güncelle Butonu
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    // 1. Firebase üzerindeki displayName'i TextField'daki veriyle güncelle
                    await user?.updateDisplayName(_nameController.text);
                    // 2. Güncel veriyi yerel kullanıcı objesine çekmek için reload et
                    await user?.reload();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Profil başarıyla güncellendi!"),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                    // 3. Profil sayfasına geri dön
                    Navigator.pop(context);
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Hata oluştu: $e")),
                      );
                    }
                  }
                },

                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF133671),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  "Güncelle",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditField(String label, TextEditingController controller, {bool enabled = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          style: TextStyle(color: enabled ? Colors.black : Colors.grey),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}
