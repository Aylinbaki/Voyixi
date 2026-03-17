import 'package:flutter/material.dart';
import 'package:voyixi/screens/onboarding_screen.dart'; // Yolun doğruluğundan emin ol
import 'package:voyixi/screens/login_screen.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voyixi',
      debugShowCheckedModeBanner: false, // Sağ üstteki "Debug" yazısını kaldırır
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // Uygulama ilk açıldığında hangi rotadan başlayacak?
      initialRoute: '/onboarding', 
      
      // Rotaların tanımlandığı yer
      routes: {
        "/onboarding": (context) => const OnboardingScreen(),
        "/login": (context) => const LoginScreen(),
      },
    );
  }
}