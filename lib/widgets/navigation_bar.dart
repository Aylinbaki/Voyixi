import 'package:flutter/material.dart';
import '../screens/profile_screen.dart';
import '../screens/home_screen.dart';
import '../screens/save_screen.dart';
import '../features/trip_planner/trip_planner_entry.dart';
import '../features/routes/routes_screen.dart';


class bottomNav extends StatelessWidget {
  final int selectedIndex;
  const bottomNav({super.key, required this.selectedIndex});

  void _handleNavigation(BuildContext context, int index) {
    // detay sayfasında olsa bile Rotalar ana listesine döncek.
    if (index == 1) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const StartedRoutesScreen()),
            (route) => false,
      );
      return; 
    }
    if (index == selectedIndex) return;

    Widget target;
    switch (index) {
      case 0: target = const HomeScreen(); break;
      case 2: target = const SaveScreen(); break;
      case 3: target = const ProfileScreen(); break;
      default: target = const HomeScreen();
    }
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => target),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 94, 139, 216).withOpacity(.85),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.1), blurRadius: 20, offset: const Offset(0, -4))
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Row(
                children: [
                  _navItem(context, Icons.home_rounded, "Home", 0),
                  _navItem(context, Icons.map_outlined, "Routes", 1),
                  const Expanded(child: SizedBox()),
                  _navItem(context, Icons.favorite_border, "Favorites", 2),
                  _navItem(context, Icons.person_outline, "Profile", 3),
                ],
              ),
              Positioned(
                top: -26,
                child: GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TripPlannerEntry())),
                  child: Container(
                    width: 58, height: 58,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: const Icon(Icons.add_location_alt_rounded, color: Colors.white),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(BuildContext context, IconData icon, String label, int index) {
    final bool selected = selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _handleNavigation(context, index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? const Color(0xFF4CAF50) : Colors.grey),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: selected ? FontWeight.bold : FontWeight.normal, color: selected ? const Color(0xFF4CAF50) : Colors.grey)),
          ],
        ),
      ),
    );
  }
}