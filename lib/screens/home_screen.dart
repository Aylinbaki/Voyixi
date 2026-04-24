import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'settings_screen.dart';
import 'profile_screen.dart';
import '../features/trip_planner/trip_planner_entry.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedNavIndex = 0;
  User? get _currentUser => FirebaseAuth.instance.currentUser;
  String get _userName {
    final user = _currentUser;

    if (user == null) return 'Voyixi';
    // 1. Önce İsim (displayName) kontrolü
    if (user.displayName != null && user.displayName!.trim().isNotEmpty) {
      return user.displayName!;
    }
    // 2. İsim yoksa Email parçala
    if (user.email != null && user.email!.isNotEmpty) {
      return user.email!.split('@').first;
    }
    // 3. Hiçbiri yoksa (Fallback)
    return 'Voyixi';
  }

  String? get _userPhotoUrl => _currentUser?.photoURL;

  final List<Map<String, dynamic>> _popularTours = [
    {
      'city': 'Paris',
      'country': 'Fransa',
      'days': '5 Gün',
      'image':
          'https://images.unsplash.com/photo-1499856871958-5b9627545d1a?w=500',
    },
    {
      'city': 'Moskova',
      'country': 'Rusya',
      'days': '4 Gün',
      'image':
          'https://images.unsplash.com/photo-1513326738677-b964603b136d?w=500',
    },
    {
      'city': 'İstanbul',
      'country': 'Türkiye',
      'days': '3 Gün',
      'image':
          'https://images.unsplash.com/photo-1524231757912-21f4fe3a7200?w=500',
    },
  ];

  final List<Map<String, dynamic>> _tourPlans = [
    {
      'title': 'New York',
      'days': '6 Gün',
      'image':
          'https://images.unsplash.com/photo-1496442226666-8d4d0e62e6e9?w=600',
    },
  ];

  final List<Map<String, dynamic>> _nearbyPlaces = [
    {
      'name': 'Sultan Ahmet',
      'distance': '1.2 km',
      'image':
          'https://images.unsplash.com/photo-1541432901042-2d8bd64b4a9b?w=400',
    },
    {
      'name': 'Kapalıçarşı',
      'distance': '700 m',
      'image':
          'https://images.unsplash.com/photo-1662633272401-9703bff75f3b?q=80&w=687',
    },
    {
      'name': 'Topkapı Sarayı',
      'distance': '2.3 km',
      'image':
          'https://images.unsplash.com/photo-1696711156435-5872e329edd4?q=80&w=687',
    },
    {
      'name': 'Galata Kulesi',
      'distance': '3.1 km',
      'image':
          'https://images.unsplash.com/photo-1695239510462-a63b0a0c0089?q=80&w=687',
    },
  ];

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color.fromARGB(255, 13, 163, 163), Color.fromARGB(255, 184, 240, 240)],
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
                // Alt barın içeriği kapatmaması için boşluk
                SizedBox(height: 100 + bottomPadding),
              ],
            ),
          ),

          Positioned(bottom: 0, left: 0, right: 0, child: _buildBottomNavBar()),
        ],
      ),
    );
  }

  // header
 Widget _buildHeader(BuildContext context) {
  final topPad = MediaQuery.of(context).padding.top;
  
  return ShaderMask(
    shaderCallback: (rect) {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        // Siyah (Opaque) olan yerler görünür, Transparent olan yerler erir.
        colors: [Colors.black, Colors.transparent],
        // Resmin %70'ine kadar net kalsın, son %30'luk dilimde erisin.
        stops: [0.7, 1.0], 
      ).createShader(rect);
    },
    blendMode: BlendMode.dstIn,
    child: Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(
            'https://images.unsplash.com/photo-1764702946401-337324daa1e0?q=80&w=1170&auto=format&fit=crop',
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.55),
              Colors.black.withOpacity(0.22),
            ],
          ),
        ),
        padding: EdgeInsets.fromLTRB(20, topPad + 14, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Profil ve Ayarlar Butonu
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
                        Text(
                          'Merhaba, $_userName!',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const Text(
                          'Tekrar hoş geldin',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.settings_outlined,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Bir Sonraki\nMaceraya Hazır mısın?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      children: [
                        SizedBox(width: 14),
                        Icon(Icons.search, color: Color(0xFF9E9E9E), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Tur ara...',
                          style: TextStyle(
                            color: Color(0xFF9E9E9E),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4CAF50).withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.tune, color: Colors.white, size: 22),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
  Widget _buildAvatar() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        color: Colors.white24,
      ),
      child: ClipOval(
        child: _userPhotoUrl != null
            ? Image.network(
                _userPhotoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const _DefaultAvatarIcon(),
              )
            : const _DefaultAvatarIcon(),
      ),
    );
  }

  // populer tur
  Widget _buildPopularTours() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Popüler Turlar',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: const Text(
                  'Tümünü Gör',
                  style: TextStyle(
                    color: Color.fromARGB(255, 183, 241, 185),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 165,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 20),
            physics: const BouncingScrollPhysics(),
            itemCount: _popularTours.length,
            itemBuilder: (context, index) =>
                _buildTourCard(_popularTours[index]),
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
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              tour['image'] as String,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: Colors.grey[300]),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.72)],
                ),
              ),
            ),
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
                  tour['days'] as String,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 12,
              left: 10,
              right: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tour['city'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tour['country'] as String,
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // tur planları
  Widget _buildTourPlans() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Tur Planlarım',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 14),
        ..._tourPlans.map(
          (plan) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildTourPlanCard(plan),
          ),
        ),
      ],
    );
  }

  Widget _buildTourPlanCard(Map<String, dynamic> plan) {
    return Container(
      height: 185,
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              plan['image'] as String,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: Colors.grey[400]),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.05),
                    Colors.black.withOpacity(0.65),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan['title'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          plan['days'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.north_east,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // civarı keşfet
  Widget _buildNearbySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Civarını Keşfet!',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(bottom: 1),
                child: Text(
                  'İstanbul',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color.fromARGB(255, 199, 198, 198),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.05,
          ),
          itemCount: _nearbyPlaces.length,
          itemBuilder: (context, index) =>
              _buildNearbyCard(_nearbyPlaces[index]),
        ),
      ],
    );
  }

  Widget _buildNearbyCard(Map<String, dynamic> place) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              place['image'] as String,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: Colors.grey[300]),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.70)],
                ),
              ),
            ),
            Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      place['name'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.near_me,
                        color: Color(0xFF81C784),
                        size: 11,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        place['distance'] as String,
                        style: const TextStyle(
                          color: Color(0xFF81C784),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
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

  Widget _buildBottomNavBar() {
    // Gerçek sıralama: 0=Home, 1=Rotalar, [FAB], 2=Favoriler, 3=Profil
    const leftItems = [
      {'icon': Icons.home_rounded, 'label': 'Ana Sayfa'},
      {'icon': Icons.map_outlined, 'label': 'Rotalar'},
    ];
    const rightItems = [
      {'icon': Icons.favorite_border, 'label': 'Favoriler'},
      {'icon': Icons.person_outline, 'label': 'Profil'},
    ];

    Widget navItem(Map item, int navIndex) {
      final isSelected = _selectedNavIndex == navIndex;
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if(navIndex==0){
              // home
            }
            else if(navIndex==1){
              // rotalar
            }
            else if(navIndex==2){
              //favoriler
            }
            else if (navIndex == 3) {
              // Profile olcak
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
              return;
            }
            setState(() => _selectedNavIndex = navIndex);
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                item['icon'] as IconData,
                size: 24,
                color: isSelected
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFFBDBDBD),
              ),
              const SizedBox(height: 3),
              Text(
                item['label'] as String,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                  color: isSelected
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFBDBDBD),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 94, 139, 216).withOpacity(0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
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
                  navItem(leftItems[0], 0),
                  navItem(leftItems[1], 1),
                  // FAB için boşluk
                  const Expanded(child: SizedBox()),
                  navItem(rightItems[0], 2),
                  navItem(rightItems[1], 3),
                ],
              ),
              Positioned(
                top: -26,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TripPlannerEntry(),
                      ),
                    );
                  },
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4CAF50).withOpacity(0.45),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add_location_alt_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DefaultAvatarIcon extends StatelessWidget {
  const _DefaultAvatarIcon();
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white24,
      child: const Icon(Icons.person, color: Colors.white, size: 26),
    );
  }
}
