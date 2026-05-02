import 'package:flutter/material.dart';
import '../screens/settings_screen.dart';

class SettingsButton extends StatelessWidget {
  const SettingsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const SettingsScreen(),
          ),
        );
      },

      child: Container(
        width:40,height:40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.2),
          shape: BoxShape.circle,
        ),

        child: const Icon(
          Icons.settings_outlined,color: Colors.white,size:22,
        ),
      ),
    );
  }
}