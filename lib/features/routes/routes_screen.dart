import 'dart:ui';
import 'package:flutter/material.dart';
import 'routes_service.dart';
import 'routes_model.dart';
import '../../widgets/navigation_bar.dart';
import '../active_trip/active_trip_screen.dart';
import 'package:intl/intl.dart';
import '../../services/favorites_service.dart';

class StartedRoutesScreen extends StatelessWidget {
  const StartedRoutesScreen({super.key});

  // Stil sabitleri
  static const _teal = Color(0xFF00BFA5);
  static const _textDark = Color(0xFF1A2E2E);
  static const _textMid = Color(0xFF4A6060);
  static const _bgTop = Color(0xFFE0F2F1);
  static const _bgBottom = Color(0xFFF5FDFD);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Arka plan degrade
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_bgTop, _bgBottom],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: StreamBuilder<List<SavedTrip>>(
            stream: RoutesService().getTrips(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: _teal));
              }
              final trips = snap.data ?? [];

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildSliverHeader(context, trips.length),
                  if (trips.isEmpty)
                    SliverFillRemaining(child: _buildEmptyState())
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                              (context, i) => _ModernTripCard(trip: trips[i]),
                          childCount: trips.length,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
      // Nav bar'ı Stack yerine buraya aldım, daha stabil çalışır
      bottomNavigationBar: const bottomNav(selectedIndex: 1),
    );
  }

  // ── Sliver Header ─────────────────────────────────────────────────────────
  Widget _buildSliverHeader(BuildContext context, int count) {
    return SliverAppBar(
      expandedHeight: 70.0,
      pinned: true,
      backgroundColor: _bgTop,
      elevation: 0.5,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _teal, size: 22),
        onPressed: () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            Navigator.pushReplacementNamed(context, '/home');
          }
        },
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsetsDirectional.only(start: 56, bottom: 16),
        centerTitle: false,
        title: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Rotalarım',
              style: TextStyle(
                color: _textDark,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            if (count > 0)
              Text(
                '$count Kayıtlı Plan',
                style: TextStyle(
                  color: _teal.withOpacity(0.8), // Siyah yerine Voyixi yeşili
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 35),
          child: Transform.scale(
            scale: 4.5,
            child: Image.asset(
              'assets/images/app_logo_plan.png',
              height: 40,
              width: 40,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map_outlined, size: 64, color: _teal.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text('Henüz kayıtlı planın yok',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _textDark)),
        ],
      ),
    );
  }
}

// ── MODERN TRIP KARTI (TÜM FONKSİYONLAR DAHİL) ──────────────────────────────
class _ModernTripCard extends StatefulWidget {
  final SavedTrip trip;
  const _ModernTripCard({required this.trip});

  @override
  State<_ModernTripCard> createState() => _ModernTripCardState();
}

class _ModernTripCardState extends State<_ModernTripCard> {
  // Stil sabitleri
  static const _teal = Color(0xFF00BFA5);
  static const _textDark = Color(0xFF1A2E2E);
  static const _textMid = Color(0xFF4A6060);

  bool _isFavorited = false;

  @override
  void initState() {
    super.initState();
    _checkFavorite();
  }

  // Firestore'dan bu rotanın favoride olup olmadığını kontrol et
  Future<void> _checkFavorite() async {
    final result = await FavoritesService.isRouteFavorited(widget.trip.id);
    if (mounted) setState(() => _isFavorited = result);
  }

  // Kalbe basınca: favorideyse çıkar, değilse ekle
  Future<void> _toggleFavorite() async {
    if (_isFavorited) {
      final docId = await FavoritesService.getFavoriteRouteDocId(widget.trip.id);
      if (docId != null) await FavoritesService.removeFavoriteRoute(docId);
    } else {
      await FavoritesService.addFavoriteRoute(FavoriteRoute(
        routeId: widget.trip.id,
        title: widget.trip.title,
        city: widget.trip.city,
        days: widget.trip.days,
        budget: widget.trip.budget,
        imageUrl: widget.trip.imageUrl,
        summary: widget.trip.summary,
      ));
    }
    // setState ile ikon anında değişir, Firestore'u beklemiyor
    if (mounted) setState(() => _isFavorited = !_isFavorited);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ActiveTripScreen(
            savedTrip: widget.trip,
            tripResult: widget.trip.toTripResult(),
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06),
                blurRadius: 15, offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Üst Bölüm: Görsel ve Cam Efekti Şehir Etiketi
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: SizedBox(
                    height: 170,
                    width: double.infinity,
                    child: widget.trip.imageUrl != null
                        ? Image.network(widget.trip.imageUrl!, fit: BoxFit.cover)
                        : Container(color: _teal.withOpacity(0.1),
                        child: const Icon(Icons.image, color: _teal)),
                  ),
                ),

                // Şehir Etiketi (Glassmorphism)
                Positioned(
                  top: 12, left: 12,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        color: Colors.black.withOpacity(0.3),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.white, size: 12),
                            const SizedBox(width: 4),
                            Text(widget.trip.city,
                                style: const TextStyle(color: Colors.white,
                                    fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Kalp Butonu
                Positioned(
                  top: 10, right: 56,
                  child: GestureDetector(
                    onTap: _toggleFavorite,
                    child: CircleAvatar(
                      backgroundColor: Colors.white.withOpacity(0.9),
                      radius: 18,
                      child: Icon(
                        _isFavorited ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: _isFavorited ? Colors.redAccent : _teal,
                        size: 20,
                      ),
                    ),
                  ),
                ),

                // Düzenle Butonu (Fonksiyonel)
                Positioned(
                  top: 10, right: 10,
                  child: GestureDetector(
                    onTap: () => _showEditDialog(context),
                    child: CircleAvatar(
                      backgroundColor: Colors.white.withOpacity(0.9),
                      radius: 18,
                      child: const Icon(Icons.edit_note_rounded, color: _teal, size: 20),
                    ),
                  ),
                ),

                // Başlık Overlay
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter, end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                      ),
                    ),
                    child: Text(widget.trip.title,
                        style: const TextStyle(color: Colors.white,
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),

            // İçerik Bölümü
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TUR TANIMI (SUMMARY)
                  Text(widget.trip.summary,
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _textMid, fontSize: 13, height: 1.4)),
                  const SizedBox(height: 12),

                  // TERCİHLER (PREFERENCES)
                  if (widget.trip.preferences.isNotEmpty)
                    Wrap(
                      spacing: 6, runSpacing: 6,
                      children: widget.trip.preferences.take(3).map((p) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: _teal.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20)),
                        child: Text(p, style: const TextStyle(
                            color: _teal, fontSize: 10, fontWeight: FontWeight.w600)),
                      )).toList(),
                    ),
                  const SizedBox(height: 16),

                  // ALT BİLGİ VE SİLME FONKSİYONU
                  Row(
                    children: [
                      // TARİH BÖLÜMÜ
                      const Icon(Icons.calendar_month_rounded, size: 14, color: _teal),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('dd.MM.yyyy').format(widget.trip.tripDate ?? DateTime.now()),
                        style: const TextStyle(fontSize: 11,
                            fontWeight: FontWeight.w600, color: _textMid),
                      ),
                      const SizedBox(width: 12),
                      // GÜN VE BÜTÇE
                      const Icon(Icons.access_time_filled_rounded, size: 14, color: _teal),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.trip.days} Gün • ${widget.trip.budget}',
                        style: const TextStyle(fontSize: 11,
                            fontWeight: FontWeight.w700, color: _textDark),
                      ),
                      const Spacer(),
                      // SİLME BUTONU
                      GestureDetector(
                        onTap: () => _confirmDelete(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.delete_outline_rounded,
                              size: 18, color: Colors.redAccent),
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

  // ──ORİJİNAL FONKSİYONLAR───────────────────────────
  void _showEditDialog(BuildContext context) {
    final titleCtrl = TextEditingController(text: widget.trip.title);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20,
            MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 20),
            const Text('Plan Adını Düzenle',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: titleCtrl,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Yeni Plan Adı',
                labelStyle: const TextStyle(color: _teal),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _teal)),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _teal,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  await RoutesService().updateTrip(widget.trip.id,
                      title: titleCtrl.text.trim());
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Değişiklikleri Kaydet',
                    style: TextStyle(color: Colors.white,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Planı Sil',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('"${widget.trip.title}" rotasını silmek istediğine emin misin?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Vazgeç', style: TextStyle(color: _textMid))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              Navigator.pop(context);
              await RoutesService().deleteTrip(widget.trip.id);
            },
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}