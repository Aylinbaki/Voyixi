import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'home_screen.dart';
import 'settings_screen.dart';
import 'edit_profile_screen.dart';
import 'save_screen.dart';
import '../features/trip_planner/trip_planner_entry.dart';
import '../widgets/navigation_bar.dart';
import '../widgets/settings_button.dart';
import '../features/routes/routes_service.dart';
import '../features/routes/routes_model.dart';
import '../services/user_service.dart';
import '../features/active_trip/active_trip_screen.dart';

class _T {
  static const gradientStart = Color(0xFF0DA3A3);
  static const gradientEnd   = Color(0xFFB8F0F0);
  static const accent  = Color(0xFF4CAF50);
  static const accent2 = Color(0xFF81C784); 
  static const navBar = Color(0xFF5E8BD8);
  static const glassWhite = Colors.white;
  static const textPrimary   = Colors.white;
  static const textSecondary = Colors.white70;
  static const textDark      = Color(0xFF1A3A3A); 
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  bool isSavedTripsSelected = true;
  final user = FirebaseAuth.instance.currentUser;
  final ImagePicker _picker = ImagePicker();
  late AnimationController _fadeCtrl;
  late Animation<double> _fade;
  final List<Map<String, dynamic>> _myNotes = [
    {
      'title': 'Galata Kulesi',
      'note': 'Sabah erkenden kalkıp Galata Kulesine gittik, muhteşemdi...',
      'date': '15.04.2026',
      'image':
      'https://images.unsplash.com/photo-1524231757912-21f4fe3a7200?w=600',
      'isLocal': false,
    }
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }
  String get _userName {
    if (user?.displayName != null && user!.displayName!.trim().isNotEmpty) {
      return user!.displayName!;
    }
    if (user?.email != null && user!.email!.isNotEmpty) {
      return user!.email!.split('@').first;
    }
    return 'Voyixi';
  }

  void _showAddNoteSheet() {
    final titleCtrl = TextEditingController();
    final noteCtrl  = TextEditingController();
    XFile? selectedImage;
    final formattedDate = DateFormat('dd.MM.yyyy').format(DateTime.now());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.92),
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,left: 22,right: 22,top: 16,),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Yeni Anı Ekle',
                    style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold,color: _T.gradientStart,),
                  ),
                  const SizedBox(height: 18),
                  GestureDetector(
                    onTap: () async {
                      final img =
                      await _picker.pickImage(source: ImageSource.gallery);
                      if (img != null) setModal(() => selectedImage = img);
                    },
                    child: Container(
                      height: 140,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: _T.gradientEnd.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: _T.gradientStart.withOpacity(0.35)),
                      ),
                      child: selectedImage == null
                          ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined,
                              color: _T.gradientStart, size: 36),
                          SizedBox(height: 8),
                          Text('Fotoğraf Ekle',
                              style:
                              TextStyle(color: _T.gradientStart)),
                        ],
                      )
                          : ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(File(selectedImage!.path),
                            fit: BoxFit.cover),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _sheetField(titleCtrl, 'Başlık (Örn: Ayasofya Gezisi)'),
                  const SizedBox(height: 10),
                  _sheetField(noteCtrl, 'Neler yaşadın?', maxLines: 3),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 15, color: _T.gradientStart),
                      const SizedBox(width: 6),
                      Text('Tarih: $formattedDate',
                          style: const TextStyle(
                              color: _T.gradientStart, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 18),
                  GestureDetector(
                    onTap: () {
                      if (titleCtrl.text.isNotEmpty) {
                        setState(() {
                          _myNotes.add({
                            'title': titleCtrl.text,
                            'note': noteCtrl.text,
                            'date': formattedDate,
                            'image': selectedImage?.path ?? '',
                            'isLocal': selectedImage != null,
                          });
                        });
                        Navigator.pop(ctx);
                      }
                    },
                    child: Container(
                      width: double.infinity, height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_T.accent, Color(0xFF2E7D32)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: _T.accent.withOpacity(0.38),blurRadius: 14, offset: const Offset(0, 5),),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Notu Kaydet',
                        style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold,fontSize: 15),),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sheetField(TextEditingController ctrl, String hint,
      {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: const TextStyle(color: _T.textDark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[500]),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // ── Resim widget'ı 
  Widget _buildNoteImage(String path, bool isLocal) {
    return isLocal
        ? Image.file(File(path),
        height: 150, width: double.infinity, fit: BoxFit.cover)
        : Image.network(path,
        height: 150, width: double.infinity, fit: BoxFit.cover);
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    final bottomInset  = MediaQuery.of(context).padding.bottom;
    const actionBarH   = 54.0 + 16 + 16;
    const navBarH      = 64.0;
    final scrollBottom = navBarH + bottomInset + actionBarH;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // ── 1. Gradient arkaplan 
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color.fromARGB(255, 13, 163, 163), Color.fromARGB(255, 184, 240, 240)],
              ),
            ),
          ),
          // ── 2. Kaydırılabilir içerik 
          FadeTransition(
            opacity: _fade,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildScrollableUserInfo(context)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                    child: _buildStatRow(),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 22)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildToggle(),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                isSavedTripsSelected ? _buildSavedTripsSliver(): _buildNotesSliver(),
                SliverToBoxAdapter(child: SizedBox(height: scrollBottom + 8)),
              ],
            ),
          ),
          // ── 3. header
          Positioned(top: 0, left: 0, right: 0, child: _buildFixedAppBar(context),
          ),
          // ── 4. SABİT action buton
          Positioned(bottom: navBarH + bottomInset, left: 0, right: 0, child: _buildFixedActionButton(),
          ),
          // ── 5. Nav bar ───────────────────────────
          Positioned(bottom: 0, left: 0, right: 0, child: const bottomNav( selectedIndex:3,),
          ),
        ],
      ),
    );
  }
  // ── SABİT APPBAR 
  Widget _buildFixedAppBar(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.fromLTRB(20, topPad + 10, 20, 12),
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
            'Profil',
            style: TextStyle(
              color: Colors.white, fontSize: 20,
              fontWeight: FontWeight.bold, letterSpacing: 1.2,
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SettingsScreen())),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.22),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.settings_outlined,
                  color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
  // ── SABİT ACTION BUTTON 
  Widget _buildFixedActionButton() {
    final label  = isSavedTripsSelected ? 'Not Ekle'        : 'Not Ekle';
    final icon   = isSavedTripsSelected ? Icons.note_add_outlined : Icons.note_add_outlined;
    final onTap  = isSavedTripsSelected
        ? () => Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
          (r) => false,
    )
        : _showAddNoteSheet;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,end: Alignment.bottomCenter,
          colors: [_T.gradientEnd.withOpacity(0.0), _T.gradientEnd.withOpacity(0.85), ],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: _actionButton(label: label, icon: icon, onPressed: onTap),
    );
  }

  // ── KAYDIRILAN kullanıcı bilgisi (avatar, isim, yer) ─
  // Sabit AppBar'ın altında görünür, kaydırılabilir.
  Widget _buildScrollableUserInfo(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    // AppBar yüksekliği kadar padding bırak (topPad + 10 + içerik + 12)
    final appBarH = topPad + 10 + 44.0 + 12; // 44 = buton yüksekliği + padding

    return Padding(
      padding: EdgeInsets.fromLTRB(20, appBarH + 20, 20, 20),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow( color: Colors.black.withOpacity(0.18),blurRadius: 16,offset: const Offset(0, 6),),
                  ],
                ),
                child: ClipOval(
                  child: user?.photoURL != null ? Image.network(user!.photoURL!,
                    fit: BoxFit.cover, errorBuilder: (_, __, ___) => _defaultAvatar(),
                  )
                      : _defaultAvatar(),
                ),
              ),
              GestureDetector(
                onTap: () async {await Navigator.push(
                    context, MaterialPageRoute(
                      builder: (_) => const EditProfileScreen(),
                    ),
                  );
                  // Geri dönünce ekranı yenile (displayName güncellenmiş olabilir)
                  setState(() {});
                },
                child: Container(
                  width: 26,height: 26,
                  decoration: BoxDecoration(
                    color: _T.accent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.edit, color: Colors.white, size: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _userName,
            style: const TextStyle(color: _T.textPrimary,fontSize: 22,fontWeight: FontWeight.bold,),
          ),
          const SizedBox(height: 4),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_on_outlined, size: 13, color: _T.textSecondary),
              SizedBox(width: 3),
              Text(
                'Türkiye',
                style: TextStyle(color: _T.textSecondary, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.22),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 19),
    ),
  );

  Widget _defaultAvatar() => Container(
    color: _T.gradientStart.withOpacity(0.4),
    child: const Icon(Icons.person, color: Colors.white, size: 44),
  );

  Widget _buildStatRow() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox();

    return StreamBuilder<Map<String, dynamic>>(
      stream: UserService().statsStream(uid),
      builder: (context, snap) {
        final stats   = snap.data ?? {};
        final cityCount = stats['cityCount'] ?? 0;
        final countryCount = stats['countryCount'] ?? 1;
        final museum = stats['museumCount'] ?? 0;
        final km = (stats['totalKm'] as double?) ?? 0.0;

        final kmStr = km >= 1000
            ? '${(km / 1000).toStringAsFixed(1)}k'
            : km.toStringAsFixed(0);

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _statBox(countryCount.toString(), 'Ülke', Icons.location_on_outlined),
            _statBox(museum.toString(),       'Müze', Icons.account_balance_outlined),
            _statBox(kmStr,                   'Toplam km', Icons.near_me_outlined),
            _statBox(cityCount.toString(),    'Şehir', Icons.map_outlined),
          ],
        );
      },
    );
  }

  Widget _statBox(String value, String label, IconData icon) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          width: 80,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.22),
            borderRadius: BorderRadius.circular(18),
            border:
            Border.all(color: Colors.white.withOpacity(0.35), width: 1),
          ),
          child: Column(
            children: [
              Icon(icon, size: 18, color: Colors.white),
              const SizedBox(height: 5),
              Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              const SizedBox(height: 2),
              Text(label,
                  style: const TextStyle(fontSize: 10, color: _T.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Toggle 
  Widget _buildToggle() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              _toggleItem('Biten Geziler', isSavedTripsSelected,
                      () => setState(() => isSavedTripsSelected = true)),
              _toggleItem('Notlar', !isSavedTripsSelected,
                      () => setState(() => isSavedTripsSelected = false)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toggleItem(String title, bool selected, VoidCallback onTap) =>
      Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: selected ? _T.accent : Colors.transparent,
              borderRadius: BorderRadius.circular(26),
              boxShadow: selected
                  ? [
                BoxShadow(
                    color: _T.accent.withOpacity(0.38),
                    blurRadius: 10,
                    offset: const Offset(0, 3))
              ]
                  : [],
            ),
            alignment: Alignment.center,
            child: Text(
              title,
              style: TextStyle(
                color: selected ? Colors.white : _T.textSecondary,
                fontWeight:
                selected ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ),
      );

  // ── Saved Trips Sliver 
  SliverList _buildSavedTripsSliver() {
    return SliverList(
      delegate: SliverChildListDelegate([
        StreamBuilder<List<SavedTrip>>(
          stream: RoutesService().getTrips(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final trips = snap.data ?? [];
            if (trips.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(40),
                child: Center(
                  child: Text('Henüz biten gezin yok',
                      style: TextStyle(color: Colors.white70, fontSize: 14)),
                ),
              );
            }
            return Column(
              children: trips.map((trip) => Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                child: GestureDetector( // Tıklama özelliği eklendi
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ActiveTripScreen(
                          savedTrip: trip,
                          tripResult: trip.toTripResult(),
                        ),
                      ),
                    );
                  },
                  child: _tripCard(
                    city: trip.title,
                    days: '${trip.days} Gün',
                    image: trip.imageUrl ?? 'https://images.unsplash.com/photo-1524231757912-21f4fe3a7200?w=600',
                  ),
                ),
              )).toList(),
            );
          },
        ),
      ]),
    );
  }

  Widget _tripCard( {required String city,required String days, required String image}) {
    return Container(
      height: 130,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.14),
              blurRadius: 14,
              offset: const Offset(0, 5))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(image,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(color: Colors.grey[300])),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.68)],
                ),
              ),
            ),
            Positioned(
              bottom: 14,left: 16,right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(city,
                          style: const TextStyle(color: Colors.white,fontWeight: FontWeight.bold,fontSize: 16)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric( horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: _T.accent,borderRadius: BorderRadius.circular(20),),
                        child: Text(days,style: const TextStyle(color: Colors.white,fontSize: 11,fontWeight: FontWeight.w700)),
                      )
                    ],
                  ),
                  Container(
                    width: 36,height: 36,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2),shape: BoxShape.circle),
                    child: const Icon(Icons.north_east,color: Colors.white, size: 18),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Notes Sliver ─
  SliverList _buildNotesSliver() {
    return SliverList(
      delegate: SliverChildListDelegate([
        ...List.generate(_myNotes.length, (index) {
          final note = _myNotes[index];
          return Padding(
            padding:
            const EdgeInsets.only(left: 20, right: 20, bottom: 14),
            child: Dismissible(
              key: UniqueKey(),
              direction: DismissDirection.endToStart,
              background: Container(
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: const Icon(Icons.delete_outline,
                    color: Colors.white, size: 28),
              ),
              onDismissed: (_) {
                setState(() => _myNotes.removeAt(index));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${note['title']} silindi'),
                    backgroundColor: _T.gradientStart,
                    action: SnackBarAction(
                      label: 'Geri Al',
                      textColor: _T.accent2,
                      onPressed: () =>
                          setState(() => _myNotes.insert(index, note)),
                    ),
                  ),
                );
              },
              child: _noteCard(note),
            ),
          );
        }),
      ]),
    );
  }

  Widget _noteCard(Map<String, dynamic> note) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.88),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow( color: Colors.black.withOpacity(0.10),blurRadius: 12,offset: const Offset(0, 4))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Resim sadece path
              if ((note['image'] as String).isNotEmpty)
                ClipRRect(
                  borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
                  child: _buildNoteImage(
                      note['image'], note['isLocal'] ?? false),
                ),
              // Metin alanı
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(note['title']!,
                            style: const TextStyle( fontWeight: FontWeight.bold,fontSize: 15,color: _T.textDark)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _T.gradientEnd.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(note['date']!,
                              style: const TextStyle(color: _T.gradientStart,fontSize: 11,fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(note['note']!,
                        style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  // ── Action Button ────────────────────────────
  Widget _actionButton(
      {required String label,
        required IconData icon,
        required VoidCallback onPressed}) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_T.accent, Color(0xFF2E7D32)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: _T.accent.withOpacity(0.38),blurRadius: 14,offset: const Offset(0, 5))
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}