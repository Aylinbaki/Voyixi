import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'settings_screen.dart';
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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  // 1. Arama sorgusu için değişken
  String _searchQuery = "";
  String _selectedBudget = "Hepsi";
  late Future<List<Map<String, dynamic>>> _nearbyFuture;

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
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.toLowerCase());
    });
    _nearbyFuture = TourService().getNearbyPlaces();
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
                  const SettingsButton()
                ],
              ),
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

  // 1. POPÜLER TURLAR (Firebase)
  //Rehber/admin Firebase console'dan bu collection'a tur ekler.
  Widget _buildPopularTours() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text('Popüler Turlar',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 185,
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: TourService().getPopularTours(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: Colors.white));
              }
              final tours = snapshot.data ?? [];

              final filteredTours = tours.where((tour) {
                final cityMatch = _searchQuery.isEmpty ||
                    (tour['city'] ?? '')
                        .toString()
                        .toLowerCase()
                        .contains(_searchQuery) ||
                    (tour['title'] ?? '')
                        .toString()
                        .toLowerCase()
                        .contains(_searchQuery);
                final filterMatch = _selectedBudget == 'Hepsi' ||
                    (tour['city'] ?? '')
                        .toString()
                        .toLowerCase() ==
                        _selectedBudget.toLowerCase();
                return cityMatch && filterMatch;
              }).toList();

              if (filteredTours.isEmpty) {
                return const Center(
                    child: Text('Eşleşen tur bulunamadı.',
                        style: TextStyle(color: Colors.white70)));
              }

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 20),
                physics: const BouncingScrollPhysics(),
                itemCount: filteredTours.length,
                itemBuilder: (context, index) =>
                    _buildTourCard(filteredTours[index]),
              );
            },
          ),
        ),
      ],
    );
  }
  // Guide tour kartı — title, city, price, guideName, tourDate gösterir
  Widget _buildTourCard(Map<String, dynamic> tour) {
    String? dateStr;
    final rawDate = tour['tourDate'];
    if (rawDate != null) {
      try {
        final dt = DateTime.parse(rawDate.toString());
        dateStr = DateFormat('d MMM', 'tr_TR').format(dt);
      } catch (_) {}
    }

    final price = tour['price'];
    final priceStr = price != null ? '₺$price' : null;

    return Container(
      width: 128,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.13),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Arkaplan resmi
            Image.network(
              tour['imageUrl'] ?? '',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: const Color(0xFF0DA3A3).withOpacity(0.4),
                child: const Icon(Icons.tour_outlined,
                    color: Colors.white54, size: 40),
              ),
            ),
            // Karartma
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.85),
                  ],
                ),
              ),
            ),
            // Rehber adı (sol üst)
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person_outline,
                        color: Colors.white, size: 11),
                    const SizedBox(width: 3),
                    Text(
                      (tour['guideName'] ?? 'Rehber').toString().trim(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            // Fiyat (sağ üst)
            if (priceStr != null)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    priceStr,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            // Alt bilgi: başlık + şehir + tarih
            Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tour['title'] ?? tour['city'] ?? '',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          color: Colors.white70, size: 11),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          tour['city'] ?? '',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 10),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (dateStr != null) ...[
                        const SizedBox(width: 4),
                        Text(
                          dateStr,
                          style: const TextStyle(
                              color: Color(0xFFB7F1B9),
                              fontSize: 10,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
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

  // 2. TUR PLANLARIM (Kullanıcın Rotaları)
  //1 plan gösteriyoruz: aktif olan veya en yakın
  Widget _buildTourPlans() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tur Planlarım',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const StartedRoutesScreen())),
                child: const Text('Tümünü Gör',
                    style: TextStyle(
                        color: Color(0xFFB7F1B9),
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        StreamBuilder<SavedTrip?>(
          stream: RoutesService().getUpcomingTrip(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 60,
                child: Center(
                    child: CircularProgressIndicator(color: Colors.white)),
              );
            }

            final trip = snapshot.data;

            if (trip == null) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildEmptyPlanCard(),
              );
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ActiveTripScreen(
                      savedTrip: trip,
                      tripResult: trip.toTripResult(),
                    ),
                  ),
                ),
                child: _buildUpcomingTripCard(trip),
              ),
            );
          },
        ),
      ],
    );
  }

  // Aktif veya yaklaşan plan kartı — başlama tarihi + bitirme oranı gösterir
  Widget _buildUpcomingTripCard(SavedTrip trip) {
    // Tarih formatı: "15 Mayıs 2026"
    final dateFormat = DateFormat('d MMMM yyyy', 'tr_TR');
    final startStr = trip.startDate != null
        ? dateFormat.format(trip.startDate!)
        : null;
    final endStr = trip.endDate != null
        ? dateFormat.format(trip.endDate!)
        : null;

    // Durum etiketi: Aktif mi, Yaklaşıyor mu?
    final String statusLabel;
    final Color statusColor;
    if (trip.isActive) {
      statusLabel = 'Devam Ediyor';
      statusColor = const Color(0xFF4CAF50);
    } else if (trip.isUpcoming) {
      statusLabel = 'Yaklaşıyor';
      statusColor = const Color(0xFFFFA726);
    } else {
      statusLabel = '${trip.days} Gün';
      statusColor = const Color(0xFF4CAF50);
    }

    final int completedCount = (trip.completionRate * trip.days).round();

    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 14,
              offset: const Offset(0, 6))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Arkaplan resmi
            Image.network(
              trip.imageUrl ??
                  'https://images.unsplash.com/photo-1496442226666-8d4d0e62e6e9?w=600',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: Colors.grey[400]),
            ),
            // Karartma
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.05),
                    Colors.black.withOpacity(0.75),
                  ],
                ),
              ),
            ),
            // İçerik
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Şehir adı
                        Expanded(
                          child: Text(
                            trip.title,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Durum etiketi
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(statusLabel,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11)),
                        ),
                      ],
                    ),
                    // Tarih satırı
                    if (startStr != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined,
                              color: Colors.white70, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            endStr != null
                                ? '$startStr – $endStr'
                                : startStr,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 10),
                    // Tamamlanma oranı
                    // Neden LinearProgressIndicator?
                    // Kullanıcı "Devam Ediyor" planında kaç yeri işaretlediğini
                    // görsel olarak anlasın. completionRate 0.0–1.0 arası float.
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: trip.completionRate,
                              backgroundColor: Colors.white24,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  statusColor),
                              minHeight: 5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '$completedCount/${trip.days} Gün',
                          style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Sağ üst ok ikonu
            Positioned(
              top: 14,
              right: 14,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.north_east,
                    color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Plan yoksa boş durum kartı
  Widget _buildEmptyPlanCard() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TripPlannerEntry()),
      ),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white30, width: 1.5),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_circle_outline, color: Colors.white70, size: 32),
              SizedBox(height: 8),
              Text('Yeni Tur Planla',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15)),
              SizedBox(height: 4),
              Text('Henüz aktif planın yok',
                  style: TextStyle(color: Colors.white60, fontSize: 12)),
            ],
          ),
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
          child: Text('Civarını Keşfet!',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
        ),
        const SizedBox(height: 14),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _nearbyFuture,
          builder: (context, snapshot) {
            // Yükleniyor
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 180,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 12),
                      Text('Çevrendeki yerler aranıyor...',
                          style:
                          TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
              );
            }

            // Hata — türüne göre farklı mesaj
            if (snapshot.hasError) {
              return _buildNearbyError(snapshot.error);
            }

            // Başarılı ama boş
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildNearbyInfoCard(
                icon: Icons.search_off_rounded,
                message: 'Çevrenizde önerilecek yer bulunamadı.',
                showRetry: true,
                onRetry: () {
                  setState(() {
                    _nearbyFuture = TourService().getNearbyPlaces();
                  });
                },
              );
            }

            final places = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.0,
                ),
                itemCount: places.length > 4 ? 4 : places.length,
                itemBuilder: (context, index) =>
                    _buildNearbyCard(places[index]),
              ),
            );
          },
        ),
      ],
    );
  }

  // Hata tipine göre doğru mesajı seç
  Widget _buildNearbyError(Object? error) {
    if (error is LocationPermissionDeniedException) {
      return _buildNearbyInfoCard(
        icon: Icons.location_off_rounded,
        message: 'Konum izni verilmedi.\nYakın yerleri görmek için izin ver.',
        showRetry: true,
        // İzin tekrar istemek için butona tıklayınca future'ı yenile
        onRetry: () {
          setState(() {
            _nearbyFuture = TourService().getNearbyPlaces();
          });
        },
      );
    }

    if (error is LocationPermissionPermanentlyDeniedException) {
      return _buildNearbyInfoCard(
        icon: Icons.location_disabled_rounded,
        message:
        'Konum izni kalıcı olarak reddedildi.\nTelefon ayarlarından izin ver.',
        showRetry: false,
        // Ayarlar sayfasını aç
        onRetry: () => Geolocator.openAppSettings(),
        retryLabel: 'Ayarları Aç',
      );
    }

    // Genel hata (internet yok, API hatası vs.)
    return _buildNearbyInfoCard(
      icon: Icons.wifi_off_rounded,
      message: 'Yerler yüklenemedi.\nİnternet bağlantını kontrol et.',
      showRetry: true,
      onRetry: () {
        setState(() {
          _nearbyFuture = TourService().getNearbyPlaces();
        });
      },
    );
  }

  Widget _buildNearbyInfoCard({
    required IconData icon,
    required String message,
    required bool showRetry,
    VoidCallback? onRetry,
    String retryLabel = 'Tekrar Dene',
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white24, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white70, size: 36),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white, fontSize: 13, height: 1.5),
            ),
            if (showRetry && onRetry != null) ...[
              const SizedBox(height: 16),
              GestureDetector(
                onTap: onRetry,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(retryLabel,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNearbyCard(Map<String, dynamic> place) {
    final rating = (place['rating'] as num?)?.toDouble() ?? 0.0;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              place['image'] ?? '',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey[300],
                child: const Icon(Icons.image_not_supported,
                    color: Colors.grey, size: 40),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.72)
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    place['name'] ?? '',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (rating > 0) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: Color(0xFFFFC107), size: 12),
                        const SizedBox(width: 3),
                        Text(
                          rating.toStringAsFixed(1),
                          style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
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