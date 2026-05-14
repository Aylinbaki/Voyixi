import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile_screen.dart';
import 'save_screen.dart';
import '../features/trip_planner/trip_planner_entry.dart';
import '../services/favorites_service.dart';
import '../services/user_service.dart';
import '../services/tour_service.dart';
import '../features/routes/routes_service.dart'; // Rotalar için
import '../features/active_trip/active_trip_screen.dart';
import '../features/routes/routes_screen.dart';
import '../features/routes/routes_model.dart';
import '../widgets/navigation_bar.dart';
import '../widgets/settings_button.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../features/guide/panel/guide_panel.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  // kullanıcı rolü öğrenme için
  final AuthService _authService = AuthService();
  UserModel? _userModel;

  // 1. Arama sorgusu için değişken
  String _searchQuery = "";
  String _selectedBudget = "Hepsi";

  User? get _currentUser => FirebaseAuth.instance.currentUser;

  String get _userName {
    final user = _currentUser;
    if (user == null) return 'Voyixi';
    if (user.displayName != null && user.displayName!.trim().isNotEmpty) {
      return user.displayName!;
    }
    if (user.email != null && user.email!.isNotEmpty) {
      return user.email!.split('@').first;
    }
    return 'Voyixi';
  }

  String? get _userPhotoUrl => _currentUser?.photoURL;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    // 2. Arama çubuğunu dinlemeye başladık
    _searchCtrl.addListener(() {
      setState(() {
        _searchQuery = _searchCtrl.text.toLowerCase();
      });
    });
  }
  Future<void> _loadUserData() async {
    if (_currentUser != null) {
      final data = await _authService.getUserData(_currentUser!.uid);
      if (mounted) { // Widget hala ekrandaysa durumu güncelle
        setState(() {
          _userModel = data;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: Stack(
        children: [
          // Arkaplan Gradient
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0DA3A3), Color(0xFFB8F0F0)],
              ),
            ),
          ),

          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 20),
                _buildPopularTours(),
                const SizedBox(height: 24),
                _buildTourPlans(),
                const SizedBox(height: 24),
                _buildNearbySection(),
                SizedBox(height: 100 + bottomPadding),
              ],
            ),
          ),
          // Navigasyon Bar
          const Positioned(
              bottom: 0, left: 0, right: 0,
              child: bottomNav(selectedIndex: 0)
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final user = _userModel;

    return ShaderMask(
      shaderCallback: (rect) => const LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Colors.black, Colors.transparent],
        stops: [0.7, 1.0],
      ).createShader(rect),
      blendMode: BlendMode.dstIn,
      child: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: NetworkImage('https://images.unsplash.com/photo-1764702946401-337324daa1e0?q=80&w=1170&auto=format&fit=crop'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Colors.black.withOpacity(0.55), Colors.black.withOpacity(0.22)],
            ),
          ),
          padding: EdgeInsets.fromLTRB(20, topPad + 14, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _buildAvatar(),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Merhaba, $_userName!',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                          const Text('Tekrar hoş geldin', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  const SettingsButton(),
                ],
                
              ),
              const Divider(color: Colors.white24, height: 32),
              if (user != null) ...[
      if (user.isAdmin)
        _buildRoleTile(
          title: "Admin Paneli",
          icon: Icons.admin_panel_settings,
          color: Colors.redAccent,
          onTap: () => Navigator.pushNamed(context, '/adminPanel'),
        ),
      if (user.isGuide)
  _buildRoleTile(
    title: "Rehber Paneli",
    icon: Icons.explore,
    color: const Color(0xFF00BFA5),
    onTap: () => showGuidePanel(context), 
  ),
      if (!user.isAdmin && !user.isGuide)
        user.isPending 
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text("Başvurunuz Değerlendiriliyor...", style: TextStyle(color: Colors.white60)),
            )
          : _buildRoleTile(
              title: "Rehber Ol",
              icon: Icons.directions_walk,
              color: const Color(0xFF00BFA5),
              onTap: () => Navigator.pushNamed(context, '/guideApply'),
            ),
    ],
              const SizedBox(height: 16),
              const Text('Bir Sonraki\nMaceraya Hazır mısın?',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, height: 1.3)),
              const SizedBox(height: 16),
              // Arama Çubuğu
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Tur ara...',
                          prefixIcon: Icon(Icons.search, color: Color(0xFF9E9E9E), size: 20),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _filterButton(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 3. Filtreleme Butonu
  Widget _filterButton() {
    return GestureDetector(
      onTap: () => _showFilterOptions(),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFF4CAF50),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF4CAF50).withOpacity(0.4),
                blurRadius: 10,
                offset: const Offset(0, 4)
            )
          ],
        ),
        child: const Icon(Icons.tune, color: Colors.white, size: 22),
      ),
    );
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder( // Menü içinde anlık seçim değişimi için
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Bütçeye Göre Filtrele', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Divider(),
                  ...['Hepsi', 'Düşük', 'Orta', 'Yüksek'].map((budget) => ListTile(
                    title: Text(budget),
                    leading: Icon(Icons.payments_outlined, color: _selectedBudget == budget ? Colors.green : Colors.grey),
                    trailing: _selectedBudget == budget ? const Icon(Icons.check, color: Colors.green) : null,
                    onTap: () {
                      setState(() => _selectedBudget = budget); // Ana ekranı yenile
                      Navigator.pop(context);
                    },
                  )),
                ],
              ),
            );
          },
        );
      },
    );
  }
  Widget _buildAvatar() {
    return Container(
      width: 44, height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        color: Colors.white24,
      ),
      child: ClipOval(
        child: _userPhotoUrl != null
            ? Image.network(_userPhotoUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const _DefaultAvatarIcon())
            : const _DefaultAvatarIcon(),
      ),
    );
  }

  // 1. POPÜLER TURLAR (Firebase) (Aramaya Göre Filtrelenmiş)
  Widget _buildPopularTours() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text('Popüler Turlar', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 165,
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: TourService().getPopularTours(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.white));
              }
              final tours = snapshot.data ?? [];

              // Arama kutusuna yazılan metne göre şehirleri filtreliyoruz
              final filteredTours = tours.where((tour) {
                final cityMatch = (tour['city'] ?? '').toString().toLowerCase().contains(_searchQuery);
                final budgetMatch = _selectedBudget == "Hepsi" || (tour['budget'] ?? 'Orta') == _selectedBudget;
                return cityMatch && budgetMatch;
              }).toList();

              if (filteredTours.isEmpty) {
                return const Center(child: Text('Eşleşen tur bulunamadı.', style: TextStyle(color: Colors.white70)));
              }

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 20),
                physics: const BouncingScrollPhysics(),
                itemCount: filteredTours.length,
                itemBuilder: (context, index) => _buildTourCard(filteredTours[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTourCard(Map<String, dynamic> tour) {
    return Container(
      width: 128,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.13),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Resim ve Tıklanma Alanı
            GestureDetector(
              onTap: () {
                // Gelecekte buraya detay sayfası yönlendirmesi eklenebilir
                print("${tour['city']} detayına gidiliyor...");
              },
              child: Image.network(
                tour['image'] ?? '',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: Colors.grey[300]),
              ),
            ),

            // 2. Gradyan Karartma (Metinlerin okunabilmesi için alt kısmı koyulaştırır)
            IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.8), // Alt kısmı daha koyu yapar
                    ],
                  ),
                ),
              ),
            ),

            // 3. Gün Sayısı Etiketi (Sağ Üst)
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  tour['days'] ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            // 4. Favori Butonu
            Positioned(
              top: 10,
              left: 10,
              child: FavoriteButton(tour: tour),
            ),

            // 5. Şehir İsmi (Alt Orta)
            Positioned(
              bottom: 12,
              left: 10,
              right: 10,
              child: Text(
                tour['city'] ?? '', // Firebase'deki 'city'
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 2. TUR PLANLARIM (Kullanıcın Rotaları)
  Widget _buildTourPlans() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tur Planlarım', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
              GestureDetector(
                // Bu buton Rotalar (Index 1) sayfasına yönlendirir
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StartedRoutesScreen())),
                child: const Text('Tümünü Gör', style: TextStyle(color: Color(0xFFB7F1B9), fontWeight: FontWeight.w600, fontSize: 13)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        StreamBuilder<List<SavedTrip>>(
          stream: RoutesService().getTrips(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox();
            final trips = snapshot.data ?? [];
            if (trips.isEmpty) return const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text('Henüz plan yok.', style: TextStyle(color: Colors.white70)));

            // .take(2) ile sadece ilk iki planı alıyoruz
            final displayTrips = trips.take(2).toList();

            return Column(
              children: displayTrips.map((trip) => Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                child: GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ActiveTripScreen(savedTrip: trip, tripResult: trip.toTripResult()))),
                  child: _buildTourPlanCard({
                    'title': trip.title,
                    'days': '${trip.days} Gün',
                    'image': trip.imageUrl ?? 'https://images.unsplash.com/photo-1496442226666-8d4d0e62e6e9?w=600',
                  }),
                ),
              )).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTourPlanCard(Map<String, dynamic> plan) {
    return Container(
      height: 185,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(plan['image'] ?? '', fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.grey[400])),
            Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withOpacity(0.05), Colors.black.withOpacity(0.65)]))),
            Positioned(
              bottom: 16, left: 16, right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(plan['title'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFF4CAF50), borderRadius: BorderRadius.circular(20)),
                        child: Text(plan['days'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                      ),
                    ],
                  ),
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                    child: const Icon(Icons.north_east, color: Colors.white, size: 20),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 3. CİVARINI KEŞFET (Firebase)
  Widget _buildNearbySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text('Civarını Keşfet!', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
              SizedBox(width: 8),
              Text('İstanbul', style: TextStyle(fontSize: 14, color: Colors.white70)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: TourService().getNearbyPlaces(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.white));
            }
            final places = snapshot.data ?? [];
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: 1.05
              ),
              itemCount: places.length,
              itemBuilder: (context, index) => _buildNearbyCard(places[index]),
            );
          },
        ),
      ],
    );
  }

  Widget _buildNearbyCard(Map<String, dynamic> place) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(place['image'] ?? '', fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.grey[300])),
            Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.70)]))),
            Positioned(
              bottom: 10, left: 10, right: 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(place['name'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.ellipsis)),
                  Row(
                    children: [
                      const Icon(Icons.near_me, color: Color(0xFF81C784), size: 11),
                      const SizedBox(width: 3),
                      Text(place['distance'] ?? '', style: const TextStyle(color: Color(0xFF81C784), fontSize: 11, fontWeight: FontWeight.w600)),
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
  Widget _buildRoleTile({
  required String title,
  required IconData icon,
  required Color color,
  required VoidCallback onTap,
}) {
  return ListTile(
    onTap: onTap,
    leading: Icon(icon, color: color),
    title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    trailing: const Icon(Icons.chevron_right, color: Colors.white54),
    contentPadding: EdgeInsets.zero,
  );
}

Widget _buildStatusTile(String message) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Text(
      message,
      style: const TextStyle(color: Colors.white60, fontStyle: FontStyle.italic),
    ),
  );
}
}




class _DefaultAvatarIcon extends StatelessWidget {
  const _DefaultAvatarIcon();
  @override
  Widget build(BuildContext context) {
    return Container(color: Colors.white24, child: const Icon(Icons.person, color: Colors.white, size: 26));
  }
}

class FavoriteButton extends StatefulWidget {
  final Map<String, dynamic> tour; // Turun tüm bilgilerini alıyoruz
  const FavoriteButton({super.key, required this.tour});

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
  bool isFav = false;

  @override
  void initState() {
    super.initState();
    _checkInitialStatus();
  }

  // Sayfa açıldığında favori durumunu Firestore'dan kontrol et
  Future<void> _checkInitialStatus() async {
    final status = await FavoritesService.isRouteFavorited(widget.tour['id'] ?? '');
    if (mounted) setState(() => isFav = status);
  }

  Future<void> _toggleFavorite() async {
    final tourId = widget.tour['id'] ?? '';
    setState(() => isFav = !isFav); // UI'da anında geri bildirim

    if (isFav) {
      // Favoriye Ekle
      await FavoritesService.addFavoriteRoute(FavoriteRoute(
        routeId: tourId,
        title: widget.tour['city'] ?? 'Voyixi Turu',
        city: widget.tour['city'] ?? '',
        days: int.tryParse(widget.tour['days']?.toString().split(' ').first ?? '1') ?? 1,
        budget: 'Orta', // Varsayılan veya Firestore'dan gelen bütçe
        imageUrl: widget.tour['image'],
        summary: '${widget.tour['city']} bölgesinde harika bir popüler tur.',
      ));
    } else {
      // Favoriden Çıkar
      final docId = await FavoritesService.getFavoriteRouteDocId(tourId);
      if (docId != null) {
        await FavoritesService.removeFavoriteRoute(docId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleFavorite,
      child: Container(
        width: 32, height: 32,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(
          isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          color: isFav ? Colors.redAccent : Colors.grey,
          size: 17,
        ),
      ),
    );
  }
  
}