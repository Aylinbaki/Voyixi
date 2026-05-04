import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import '../features/routes/routes_screen.dart';
import '../features/trip_planner/trip_planner_entry.dart';
import '../services/favorites_service.dart';
import '../widgets/navigation_bar.dart';

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

class _SaveScreenState extends State<SaveScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
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
          // 2. İçerik
          Column(
            children: [
              SizedBox(height: topPad),
              _buildAppBar(context),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildSearchBar(),
              ),
              const SizedBox(height: 12),
              _buildTabBar(),
              const SizedBox(height: 8),
              Expanded(
                child: TabBarView(
                  controller: _tabCtrl,
                  children: [
                    _buildRoutesTab(bottomPad),
                    _buildPlacesTab(bottomPad),
                  ],
                ),
              ),
            ],
          ),
          // 3. Bottom Nav
          Positioned(bottom: 0, left: 0, right: 0, child: bottomNav(selectedIndex: 2),
          ),
        ],
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────
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
          const Text('FAVORİLER',
              style: TextStyle(color: Colors.white, fontSize: 20,
                  fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  // ── Search Bar ────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      height: 48,
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
          hintText: 'Ara...',
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

  // ── Tab Bar ───────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: TabBar(
            controller: _tabCtrl,
            indicator: BoxDecoration(
              color: _T.accent,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(color: _T.accent.withOpacity(0.38), blurRadius: 10, offset: const Offset(0, 3)),
              ],
            ),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            dividerColor: Colors.transparent,
            indicatorSize: TabBarIndicatorSize.tab,
            padding: const EdgeInsets.all(4),
            tabs: const [Tab(text: 'Rotalar'), Tab(text: 'Mekanlar')],
          ),
        ),
      ),
    );
  }

  // ── Rotalar Sekmesi ───────────────────────────────────────────────────────
  Widget _buildRoutesTab(double bottomPad) {
    return StreamBuilder<List<FavoriteRoute>>(
      stream: FavoritesService.favoriteRoutesStream(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }
        final routes = (snap.data ?? []).where((r) =>
        _searchQuery.isEmpty ||
            r.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            r.city.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

        if (routes.isEmpty) return _buildEmpty('Henüz favori rotanız yok', 'Rotaları favorilere ekleyerek burada görebilirsiniz.');

        return ListView.separated(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 80 + bottomPad),
          itemCount: routes.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (_, i) => _buildRouteCard(routes[i]),
        );
      },
    );
  }

  // ── Mekanlar Sekmesi ──────────────────────────────────────────────────────
  Widget _buildPlacesTab(double bottomPad) {
    return StreamBuilder<List<FavoritePlace>>(
      stream: FavoritesService.favoritePlacesStream(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }
        final places = (snap.data ?? []).where((p) =>
        _searchQuery.isEmpty ||
            p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            p.city.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

        if (places.isEmpty) return _buildEmpty('Henüz favori mekanınız yok', 'Mekanları favorilere ekleyerek burada görebilirsiniz.');

        return ListView.separated(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 80 + bottomPad),
          itemCount: places.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) => _buildPlaceCard(places[i]),
        );
      },
    );
  }

  // ── Rota Kartı ────────────────────────────────────────────────────────────
  Widget _buildRouteCard(FavoriteRoute route) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const StartedRoutesScreen())),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 16, offset: const Offset(0, 5))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  route.imageUrl != null
                      ? Image.network(route.imageUrl!,
                      height: 160, width: double.infinity, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imagePlaceholder())
                      : _imagePlaceholder(),
                  Positioned(
                    top: 12, right: 12,
                    child: GestureDetector(
                      onTap: () async {
                        if (route.id != null) await FavoritesService.removeFavoriteRoute(route.id!);
                      },
                      child: Container(
                        width: 40, height: 40,
                        decoration: const BoxDecoration(
                          color: Colors.white, shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))],
                        ),
                        child: const Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 20),
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
                    Text(route.title,
                        style: const TextStyle(color: _T.textDark, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(route.summary, maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 14, color: _T.gradientStart),
                        const SizedBox(width: 3),
                        Text(route.city, style: const TextStyle(color: _T.gradientStart, fontSize: 12)),
                        const SizedBox(width: 12),
                        Icon(Icons.calendar_today_outlined, size: 14, color: _T.gradientStart),
                        const SizedBox(width: 3),
                        Text('${route.days} Gün • ${route.budget}',
                            style: const TextStyle(color: _T.gradientStart, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Mekan Kartı ───────────────────────────────────────────────────────────
  Widget _buildPlaceCard(FavoritePlace place) {
    return GestureDetector(
      onTap: () async {
        if (place.lat != null && place.lng != null) {
          final url = Uri.parse(
            'https://www.google.com/maps/search/?api=1'
                '&query=${place.lat},${place.lng}',
          );
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          }
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              child: place.photoUrl != null
                  ? Image.network(place.photoUrl!,
                  width: 90, height: 90, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _smallPlaceholder())
                  : _smallPlaceholder(),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(place.name,
                        style: const TextStyle(color: _T.textDark, fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(place.description, maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 12, color: _T.gradientStart),
                        const SizedBox(width: 3),
                        Text(place.city, style: const TextStyle(color: _T.gradientStart, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            GestureDetector(
              onTap: () async {
                if (place.id != null) await FavoritesService.removeFavoritePlace(place.id!);
              },
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() => Container(
    height: 160, width: double.infinity,
    color: _T.gradientEnd,
    child: const Icon(Icons.image_not_supported_outlined, color: _T.gradientStart, size: 40),
  );

  Widget _smallPlaceholder() => Container(
    width: 90, height: 90,
    color: _T.gradientEnd,
    child: const Icon(Icons.place, color: _T.gradientStart, size: 30),
  );

  Widget _buildEmpty(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border_rounded, size: 64, color: Colors.white.withOpacity(0.60)),
          const SizedBox(height: 16),
          Text(title, style: TextStyle(color: Colors.white.withOpacity(0.80),
              fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(subtitle, textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 13)),
        ],
      ),
    );
  }
}