import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Çıkış yapma fonksiyonu
  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    // Çıkış yaptıktan sonra login ekranına geri dön ve arkadaki tüm sayfaları temizle
    Navigator.pushReplacementNamed(context, '/'); 
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Voyixi - Ana Sayfa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context), // Çıkış butonu
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.travel_explore, size: 100, color: Colors.blue),
            const SizedBox(height: 20),
            Text(
              'Welcome, ${user?.email ?? "Gezgin"}!',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text('Voyixi ile yeni maceralara hazır mısın?'),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => _logout(context),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text('Güvenli Çıkış Yap', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}