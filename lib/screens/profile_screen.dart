import 'dart:io'; // Dosya işlemleri için gerekli
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // flutter pub add intl yapmış olmalısın
import 'package:image_picker/image_picker.dart';
import 'home_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isSavedTripsSelected = true;
  final user = FirebaseAuth.instance.currentUser;
  final ImagePicker _picker = ImagePicker();

  // Notları tutacak liste
  final List<Map<String, dynamic>> _myNotes = [
    {
      'title': 'Galata Kulesi',
      'note': 'Sabah erkenden kalkıp Galata Kulesine gittik, muhteşemdi...',
      'date': '15.04.2026',
      'image': 'https://images.unsplash.com/photo-1524231757912-21f4fe3a7200?w=600',
      'isLocal': false, // Ağdan mı yoksa cihazdan mı geldiğini anlamak için
    }
  ];

  // Yeni not ekleme & resim seçme
void _showAddNoteSheet() {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController noteController = TextEditingController();
  XFile? selectedImage; // Seçilen resmi tutacak değişken

  String formattedDate = DateFormat('dd.MM.yyyy').format(DateTime.now());

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
    ),
    builder: (context) => StatefulBuilder( // Modal içindeki resmi anlık göstermek için
      builder: (context, setModalState) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Yeni Anı Ekle",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF133671),
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () async {
                final XFile? image =
                await _picker.pickImage(source: ImageSource.gallery);
                if (image != null) {
                  setModalState(() => selectedImage = image);
                }
              },
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: selectedImage == null
                    ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo, color: Colors.grey, size: 40),
                    SizedBox(height: 8),
                    Text("Fotoğraf Ekle",
                        style: TextStyle(color: Colors.grey)),
                  ],
                )
                    : ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(File(selectedImage!.path),
                      fit: BoxFit.cover),
                ),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                hintText: "Başlık (Örn: Ayasofya Gezisi)",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Neler yaşadın?",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text("Tarih: $formattedDate",
                    style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  setState(() {
                    _myNotes.add({
                      'title': titleController.text,
                      'note': noteController.text,
                      'date': formattedDate,
                      'image': selectedImage?.path ?? 'https://via.placeholder.com/600',  // Şimdilik placeholder
                      'isLocal': selectedImage != null,
                    });
                  });
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF133671),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Notu Kaydet",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    ),
  );
}

// Notlar listesinde resmi düzgün göstermek için yardımcı fonksiyon
  Widget _buildNoteImage(String imagePath, bool isLocal) {
   if (isLocal) {
      return Image.file(File(imagePath), height: 150, width: double.infinity, fit: BoxFit.cover);
   }
   return Image.network(imagePath, height: 150, width: double.infinity, fit: BoxFit.cover);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
        actions: [IconButton(onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SettingsScreen(),
              ),
          );
        },
            icon: const Icon(Icons.settings, color: Colors.black))],
      ),
      body: Column(
        children: [
          _buildUserInfo(),
          const SizedBox(height: 20),
          _buildStatGrid(),
          const SizedBox(height: 25),
          _buildToggleButtons(),
          const SizedBox(height: 10),
          Expanded(
            child: isSavedTripsSelected ? _buildSavedTripsList() : _buildNotesSection(),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo() {
    return Column(
      children: [
        CircleAvatar(
          radius: 45,
          backgroundColor: Colors.white,
          child: CircleAvatar(
            radius: 42,
            backgroundImage: NetworkImage(user?.photoURL ?? 'https://via.placeholder.com/150'),
          ),
        ),
        const SizedBox(height: 10),
        // Firebase'den isim alıyor, yoksa "Gezgin" yazıyor
        Text(
          user?.displayName ?? "Gezgin Voyixi",
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF133671)),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_on, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text("Türkiye", style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatBox("4", "City", Icons.location_on_outlined),
          _buildStatBox("12", "Museum", Icons.account_balance_outlined),
          _buildStatBox("847", "Total km", Icons.near_me_outlined),
          _buildStatBox("1", "Country", Icons.map_outlined),
        ],
      ),
    );
  }

  Widget _buildStatBox(String value, String label, IconData icon) {
    return Container(
      width: 80,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF133671).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF133671)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildToggleButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 45,
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(25)),
        child: Row(
          children: [
            _buildToggleItem("Saved Trips", isSavedTripsSelected, () => setState(() => isSavedTripsSelected = true)),
            _buildToggleItem("Notes", !isSavedTripsSelected, () => setState(() => isSavedTripsSelected = false)),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleItem(String title, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF133671) : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Text(title, style: TextStyle(color: isSelected ? Colors.white : Colors.black54, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildSavedTripsList() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: 1,
            itemBuilder: (context, index) => Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: const ListTile(
                leading: Icon(Icons.map, color: Colors.blue),
                title: Text("İstanbul Gezisi"),
                subtitle: Text("3 Gün"),
                trailing: Icon(Icons.arrow_forward_ios, size: 14),
              ),
            ),
          ),
        ),
        _buildActionButton("Yeni Rota Ekle", Icons.add, () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
                (route) => false,
          );
        }),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _myNotes.length,
            itemBuilder: (context, index) {
              final note = _myNotes[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                      child: _buildNoteImage(note['image'], note['isLocal'] ?? false),                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(note['title']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text(note['date']!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(note['note']!, style: const TextStyle(color: Colors.black87)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        _buildActionButton("Not Ekle", Icons.note_add, _showAddNoteSheet),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF133671),
          minimumSize: const Size(double.infinity, 55),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
      ),
    );
  }
}
