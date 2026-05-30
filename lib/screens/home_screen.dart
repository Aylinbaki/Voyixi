import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'tour_detail_screen.dart';
import '../features/trip_planner/trip_planner_entry.dart';
import '../services/favorites_service.dart';
import '../services/tour_service.dart';
import '../features/routes/routes_service.dart'; 
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
  final AuthService _authService = AuthService();
  UserModel? _userModel;
  String _searchQuery = "";
  String _selectedBudget = "All";
  bool _isSearching = false; 
  
  final List<String> _travelFacts = [
  "Did you know? Paris has only one single stop sign in the entire city.",
  "The Great Wall of China is not completely continuous; it consists of multiple walls built over centuries.",
  "With over 800 languages spoken, Papua New Guinea is the most linguistically diverse country on Earth.",
  "Venice has 118 small islands connected by over 400 bridges.",
  "Japan has over 6,800 islands, and is one of the world's most mountainous countries.",
  "The world's longest commercial flight takes nearly 19 hours, traveling from Singapore to New York.",
  "Iceland grows about 5 centimeters wider each year because of its moving tectonic plates."
];

String _currentFact = "";

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
  // init---------------------------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    _nearbyFuture = TourService().getNearbyPlaces();
    _loadUserData();
   _searchCtrl.addListener(() {
  setState(() {
    _searchQuery = _searchCtrl.text.toLowerCase();
    _isSearching = _searchCtrl.text.isNotEmpty;
  });
});
    _refreshNearbyPlaces();
    if (_travelFacts.isNotEmpty) {
    _currentFact = _travelFacts[DateTime.now().microsecondsSinceEpoch % _travelFacts.length];
  }
  }

  void _refreshNearbyPlaces() {
    setState(() {
      _nearbyFuture = TourService().getNearbyPlaces();
    });
  }
  Future<void> _loadUserData() async {
    if (_currentUser != null) {
      final data = await _authService.getUserData(_currentUser!.uid);
      if (mounted) { 
        setState(() {
          _userModel = data;
        });
      }
    }
  }
//dispose------------------------------------------------------------------------------------
  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }
//----------------------!!BUILD!!------------------------------------------------------------------
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
                if (_isSearching) ...[
                  _buildSearchResults(),
                  const SizedBox(height: 24),
                ] else ...[
                  _buildPopularTours(),
                  const SizedBox(height: 24),
                  _buildTourPlans(),
                  const SizedBox(height: 24),
                  _buildNearbySection(),
                  _buildTravelTrivia(_currentFact),
                ],
                SizedBox(height: 100 + bottomPadding),
              ],
            ),
          ),
          const Positioned( bottom: 0,left: 0,right: 0,child: bottomNav(selectedIndex: 0),),
        ],
      ),
    );
  }
// Build parts header------------------------------------------------------------------------
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
                          Text('Hello, $_userName!',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                          const Text('Welcome again!', style: TextStyle(color: Colors.white70, fontSize: 12)),
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
                    title: "Admin Panel",
                    icon: Icons.admin_panel_settings,
                    color: Colors.redAccent,
                    onTap: () => Navigator.pushNamed(context, '/adminPanel'),
                  ),
                if (user.isGuide)
                  _buildRoleTile(
                    title: "Guide Panel",
                    icon: Icons.explore,
                    color: const Color(0xFF00BFA5),
                    onTap: () => showGuidePanel(context),
                  ),
                if (!user.isAdmin && !user.isGuide)
                  user.isPending
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            "Your application is being reviewed...",
                            style: TextStyle(color: Colors.white60),
                          ),
                        )
                      : _buildRoleTile(
                          title: "Become a Guide",
                          icon: Icons.directions_walk,
                          color: const Color(0xFF00BFA5),
                          onTap: () =>
                              Navigator.pushNamed(context, '/guideApply'),
                        ),
              ],
              const SizedBox(height: 16),
              const Text('Are you ready\n For the next adventure?',
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
                          hintText: 'Tour search...',
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

  // 3. Filter Butonu
  Widget _filterButton() {
    return GestureDetector(
      onTap: () => _showFilterOptions(),
      child: Container(
        width: 48,height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFF4CAF50),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF4CAF50).withOpacity(0.4),blurRadius: 10,offset: const Offset(0, 4)
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
        return SafeArea(
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Budget Filter',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    ...['All', 'Free'].map(
                      (budget) => ListTile(
                        title: Text(budget),
                        leading: Icon(
                          budget == 'Free'
                              ? Icons.money_off_rounded
                              : Icons.payments_outlined,
                          color: _selectedBudget == budget
                              ? const Color(0xFF00BFA5)
                              : Colors.grey,
                        ),
                        trailing: _selectedBudget == budget
                            ? const Icon(Icons.check, color: Color(0xFF00BFA5))
                            : null,
                        onTap: () {
                          setState(() => _selectedBudget = budget);
                          
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 44,height: 44,
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


  Widget _buildPopularTours() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text('Guided Tours',
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
                final cityMatch =
                    _searchQuery.isEmpty ||
                    (tour['city'] ?? '').toString().toLowerCase().contains(_searchQuery,)
                     ||
                    (tour['title'] ?? '').toString().toLowerCase().contains(_searchQuery,);
                final filterMatch = _selectedBudget == 'All' ||
                    (tour['budget'] ?? '').toString().toLowerCase() == _selectedBudget.toLowerCase();

                return cityMatch && filterMatch; 
              }).toList();

              if (filteredTours.isEmpty) {
                return const Center(
                    child: Text('No matching rounds were found.',
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

  Widget _buildTourCard(Map<String, dynamic> tour) {
    final title = (tour['title'] as String? ?? '').trim();
    final city  = (tour['city']  as String? ?? '').trim();

    final showCity = city.isNotEmpty &&
        !title.toLowerCase().contains(city.toLowerCase());

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TourDetailScreen(tour: tour),
        ),
      ),
      child: Container(
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
                      Colors.black.withOpacity(0.80),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 10,left: 10,right: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title.isNotEmpty ? title : (city.isNotEmpty ? city : 'Tur'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (showCity) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              color: Colors.white70, size: 11),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              city,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 10),
                              overflow: TextOverflow.ellipsis,
                            ),
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
      ),
    );
  }
  Widget _buildTourPlans() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('My Tour Plans',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const StartedRoutesScreen())),
                child: const Text('See all',
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

  Widget _buildUpcomingTripCard(SavedTrip trip) {
    final dateFormat = DateFormat('d MMMM yyyy', 'tr_TR');
    final startStr = trip.startDate != null
        ? dateFormat.format(trip.startDate!)
        : null;
    final endStr = trip.endDate != null
        ? dateFormat.format(trip.endDate!)
        : null;
    final String statusLabel;
    final Color statusColor;
    if (trip.isActive) {
      statusLabel = 'Ongoing';
      statusColor = const Color(0xFF4CAF50);
    } else if (trip.isUpcoming) {
      statusLabel = 'Approaching';
      statusColor = const Color(0xFFFFA726);
    } else {
      statusLabel = '${trip.days} Day';
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
//------------Arkaplan resmi
            Image.network(
              trip.imageUrl ??
                  'https://images.unsplash.com/photo-1496442226666-8d4d0e62e6e9?w=600',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: Colors.grey[400]),
            ),
//-------------- Karartma
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
//--------------- İçerik
            Positioned(
              bottom: 0,left: 0,right: 0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
//-------------------------- Şehir adı
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
//------------------------ Durum etiketi
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
//--------------------- Tarih satırı
                    if (startStr != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined,
                              color: Colors.white70, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            endStr != null ? '$startStr – $endStr': startStr,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 10),
//-------------------- completion rate
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
                          '$completedCount/${trip.days} Day',
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
              top: 14,right: 14,
              child: Container(
                width: 34,height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.north_east,color: Colors.white, size: 18),
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
              Text('Plan a New Tour',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15)),
              SizedBox(height: 4),
              Text("You don't have an active plan yet.",
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
          child: Text('Explore your surroundings!',
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
                      Text('Finding places near you...',
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
                message: 'No places to recommend were found in your area.',
                showRetry: true,
                onRetry: _refreshNearbyPlaces,
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
        message: 'Location permission denied.\nGive permission to view nearby locations.',
        showRetry: true,
        // İzin tekrar istemek için butona tıklayınca future'ı yenile
        onRetry: _refreshNearbyPlaces,
      );
    }

    if (error is LocationPermissionPermanentlyDeniedException) {
      return _buildNearbyInfoCard(
        icon: Icons.location_disabled_rounded,
        message:
        'Location permission has been permanently denied.\nAllow it through phone settings.',
        showRetry: true,
        onRetry: () => Geolocator.openAppSettings(),
        retryLabel: 'Open Settings',
      );
    }

    if (error is LocationServiceDisabledException) {
      return _buildNearbyInfoCard(
        icon: Icons.gps_off_rounded,
        message:
        'Location services are turned off.\nEnable GPS to discover nearby places.',
        showRetry: true,
        onRetry: () => Geolocator.openLocationSettings(),
        retryLabel: 'Open Location Settings',
      );
    }

    if (error is NearbyPlacesFetchException) {
      return _buildNearbyInfoCard(
        icon: Icons.cloud_off_rounded,
        message: error.message,
        showRetry: true,
        onRetry: _refreshNearbyPlaces,
      );
    }

    // Ağ / DNS hataları
    final errText = error.toString().toLowerCase();
    if (errText.contains('socket') ||
        errText.contains('host') ||
        errText.contains('network')) {
      return _buildNearbyInfoCard(
        icon: Icons.wifi_off_rounded,
        message:
        'Network error while loading nearby places.\n'
        'Check Wi‑Fi/mobile data, then tap Try again.',
        showRetry: true,
        onRetry: _refreshNearbyPlaces,
      );
    }

    // Bilinmeyen hata
    return _buildNearbyInfoCard(
      icon: Icons.error_outline_rounded,
      message: 'Could not load nearby places.\n$error',
      showRetry: true,
      onRetry: _refreshNearbyPlaces,
    );
  }

  Widget _buildNearbyInfoCard({
    required IconData icon,
    required String message,
    required bool showRetry,
    VoidCallback? onRetry,
    String retryLabel = 'Try again',
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

    // 🎯 MÜHENDİSLİK DOKUNUŞU: Kartın tamamını tıklanabilir yapmak için GestureDetector ile sarmaladık
    return GestureDetector(
      onTap: () {
        final id = place['placeId'] as String? ?? '';
        if (id.isNotEmpty) {
          debugPrint('🗺️ [UI] Launching Google Maps for placeId: $id');
          TourService.launchGoogleMaps(id);
        } else {
          debugPrint('⚠️ [UI] Cannot launch Google Maps: placeId is empty');
        }
      },
      child: Container(
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
                bottom: 10, left: 10, right: 10,
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
      title: Text(title,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white54),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildSearchResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          key: ValueKey('search_header_$_searchQuery'),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Results for "$_searchQuery"',
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white70),
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: TourService().getPopularTours(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: Colors.white));
            }

            final tours = snapshot.data ?? [];
            final results = tours.where((tour) {
              final matchesSearch =
                  (tour['title'] ?? '').toString().toLowerCase().contains(
                        _searchQuery,
                      ) ||
                  (tour['city'] ?? '').toString().toLowerCase().contains(
                        _searchQuery,
                      );
              final matchesBudget = _selectedBudget == 'All' ||
                  (tour['budget'] ?? '').toString().toLowerCase() ==
                      _selectedBudget.toLowerCase();
              return matchesSearch && matchesBudget;
            }).toList();
            if (results.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text('No matching tours found with these filters.',
                    style: TextStyle(color: Colors.white60)),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: results.length,
              itemBuilder: (_, i) => _buildSearchResultTile(results[i]),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSearchResultTile(Map<String, dynamic> tour) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TourDetailScreen(tour: tour)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 60,
              height: 60,
              child: Image.network(
                tour['imageUrl'] ?? '',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFF0DA3A3).withOpacity(0.4),
                  child: const Icon(Icons.tour_outlined,
                      color: Colors.white54, size: 24),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tour['title'] ?? tour['city'] ?? 'Tur',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
                const SizedBox(height: 3),
                Text(tour['city'] ?? '',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded,
              color: Colors.white54, size: 14),
        ]),
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
        title: widget.tour['city'] ?? 'Voyixi Tour',
        city: widget.tour['city'] ?? '',
        days: int.tryParse(widget.tour['days']?.toString().split(' ').first ?? '1') ?? 1,
        budget: 'Medium', // Varsayılan veya Firestore'dan gelen bütçe
        imageUrl: widget.tour['image'],
        summary: 'A great and popular tour in the ${widget.tour['city']} region.',
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

//  Fonksiyonun içine dışarıdan bilgiyi paslamak için (String fact) ekledik
Widget _buildTravelTrivia(String fact) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
    child: CustomPaint(
      painter: _LCornerPainter(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome_outlined, color: Colors.white70, size: 20),
            const SizedBox(height: 10),
            Text(
              fact.isNotEmpty ? fact : "Discover the world with Voyixi!",
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.5,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _LCornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    const double length = 14.0;
    canvas.drawPath(Path()..moveTo(0, length)..lineTo(0, 0)..lineTo(length, 0), paint);
    canvas.drawPath(Path()..moveTo(size.width - length, 0)..lineTo(size.width, 0)..lineTo(size.width, length), paint);
    canvas.drawPath(Path()..moveTo(0, size.height - length)..lineTo(0, size.height)..lineTo(length, size.height), paint);
    canvas.drawPath(Path()..moveTo(size.width - length, size.height)..lineTo(size.width, size.height)..lineTo(size.width, size.height - length), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}