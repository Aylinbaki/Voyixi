import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import '../features/trip_planner/trip_planner_entry.dart';
import '../services/saved_trip_service.dart';

class _T {
  static const gradientStart = Color(0xFF0DA3A3);
  static const gradientEnd   = Color(0xFFB8F0F0);
  static const accent        = Color(0xFF4CAF50);
  static const navBar        = Color(0xFF5E8BD8);
  static const textDark      = Color(0xFF1A3A3A);
}

class SaveScreen extends StatefulWidget {
  const SaveScreen({super.key});

  @override
  State<SaveScreen> createState() => _SaveScreenState();
}

class _SaveScreenState extends State<SaveScreen> {
  String _selectedCity = 'Tümü';
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<String> _cityFilters(List<SavedTrip> trips) {
    final cities = trips.map((t) => t.city).toSet().toList();
    return ['Tümü', ...cities];
  }

  List<SavedTrip> _filtered(List<SavedTrip> trips) {
    return trips.where((t) {
      final matchCity   = _selectedCity == 'Tümü' || t.city == _selectedCity;
      final matchSearch = _searchQuery.isEmpty ||
          t.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          t.city.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchCity && matchSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    final topPad    = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 1. Arkaplan
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0DA3A3), Color(0xFF4DD0D0)],
              ),
            ),
          ),

          // 2. İçerik — Firestore stream'den okur
          StreamBuilder<List<SavedTrip>>(
            stream: SavedTripService.savedTripsStream(),
            builder: (context, snapshot) {
              final allTrips = snapshot.data ?? [];
              final filters  = _cityFilters(allTrips);
              final filtered = _filtered(allTrips);

              return Column(
                children: [
                  SizedBox(height: topPad),
                  _buildAppBar(context),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildSearchBar(),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: filters.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) => _buildChip(filters[i]),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: snapshot.connectionState == ConnectionState.waiting
                        ? const Center(child: CircularProgressIndicator(color: Colors.white))
                        : filtered.isEmpty
                        ? _buildEmpty()
                        : ListView.separated(
                      padding: EdgeInsets.fromLTRB(20, 0, 20, 80 + bottomPad),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (_, i) => _buildTripCard(filtered[i]),
                    ),
                  ),
                ],
              );
            },
          ),

          // 3. Bottom Nav
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _buildBottomNavBar(context),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.22),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
          const Text(
            'FAVORİLER',
            style: TextStyle(
              color: Colors.white, fontSize: 20,
              fontWeight: FontWeight.bold, letterSpacing: 1.2,
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.28),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.40)),
      ),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _searchQuery = v),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Gezi ara...',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.75)),
          prefixIcon: Icon(Icons.search_rounded, color: Colors.white.withOpacity(0.80)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          suffixIcon: _searchQuery.isNotEmpty
              ? GestureDetector(
            onTap: () { _searchCtrl.clear(); setState(() => _searchQuery = ''); },
            child: Icon(Icons.close_rounded, color: Colors.white.withOpacity(0.80)),
          )
              : null,
        ),
      ),
    );
  }

  Widget _buildChip(String city) {
    final selected = _selectedCity == city;
    return GestureDetector(
      onTap: () => setState(() => _selectedCity = city),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.white.withOpacity(0.90) : Colors.white.withOpacity(0.22),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Colors.transparent : Colors.white.withOpacity(0.40),
          ),
        ),
        child: Text(
          city,
          style: TextStyle(
            color: selected ? _T.gradientStart : Colors.white,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildTripCard(SavedTrip trip) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 16, offset: const Offset(0, 5)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Image.network(
                  trip.imageUrl,
                  height: 180, width: double.infinity, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 180, color: _T.gradientEnd,
                    child: const Icon(Icons.image_not_supported_outlined,
                        color: _T.gradientStart, size: 40),
                  ),
                ),
                // Kalp — Firestore'dan sil
                Positioned(
                  top: 12, right: 12,
                  child: GestureDetector(
                    onTap: () {
                      if (trip.id != null) {
                        SavedTripService.removeTrip(trip.id!);
                      }
                    },
                    child: Container(
                      width: 40, height: 40,
                      decoration: const BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))],
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(trip.title,
                      style: const TextStyle(color: _T.textDark, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(trip.dateRange,
                          style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 14, color: _T.gradientStart),
                          const SizedBox(width: 3),
                          Text('${trip.pointCount} Nokta',
                              style: const TextStyle(color: _T.gradientStart,
                                  fontWeight: FontWeight.w600, fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bookmark_border_rounded, size: 64, color: Colors.white.withOpacity(0.60)),
          const SizedBox(height: 16),
          Text('Henüz favori gezin yok',
              style: TextStyle(color: Colors.white.withOpacity(0.80),
                  fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('Gezileri favorilere ekleyerek\nburada görebilirsin.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _T.navBar.withOpacity(0.88),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 20, offset: const Offset(0, -4))],
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
                  _navItem(context, Icons.home_rounded, 'Ana Sayfa', false,
                          () => Navigator.pushAndRemoveUntil(context,
                          MaterialPageRoute(builder: (_) => const HomeScreen()), (r) => false)),
                  _navItem(context, Icons.map_outlined, 'Rotalar', false, () {}),
                  const Expanded(child: SizedBox()),
                  _navItem(context, Icons.favorite_rounded, 'Favoriler', true, () {}),
                  _navItem(context, Icons.person_outline, 'Profil', false,
                          () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const ProfileScreen()))),
                ],
              ),
              Positioned(
                top: -26,
                child: GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const TripPlannerEntry())),
                  child: Container(
                    width: 58, height: 58,
                    decoration: BoxDecoration(
                      color: _T.accent, shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [BoxShadow(color: _T.accent.withOpacity(0.45), blurRadius: 14, offset: const Offset(0, 4))],
                    ),
                    child: const Icon(Icons.add_location_alt_rounded, color: Colors.white, size: 26),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(BuildContext context, IconData icon, String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: selected ? _T.accent : const Color(0xFFBDBDBD)),
            const SizedBox(height: 3),
            Text(label, style: TextStyle(fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                color: selected ? _T.accent : const Color(0xFFBDBDBD))),
          ],
        ),
      ),
    );
  }
}