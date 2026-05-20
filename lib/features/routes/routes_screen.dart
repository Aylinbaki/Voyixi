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
  //static const _bgTop = Color(0xFFE0F2F1);
  //static const _bgBottom = Color(0xFFF5FDFD);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Arka plan degrade
      extendBodyBehindAppBar: false,
      backgroundColor: const Color(0xFF0DA3A3),
      bottomNavigationBar: const bottomNav(selectedIndex: 1),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0DA3A3), Color(0xFFB8F0F0)],
          ),
        ),
        child: StreamBuilder<List<SavedTrip>>(
          stream: RoutesService().getTrips(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: _teal));
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
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
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
    );
  }


  // ── Sliver Header ─────────────────────────────────────────────────────────
  Widget _buildSliverHeader(BuildContext context, int count) {
    return SliverAppBar(
      expandedHeight: 0,
      pinned: true,
      toolbarHeight: 70,
      stretch: false,
      centerTitle: false,

      backgroundColor: const Color(0xFF0DA3A3),
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      forceElevated: false,

      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: GestureDetector(
          onTap: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/home');
            }
          },
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
      ),

      title: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,  // ← center → start
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Routes',
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
              letterSpacing: 0,
            ),
          ),
          if (count > 0)
            Text(
              '$count Recorded Plan',
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
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
          const Text("You don't have a saved plan yet.",
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
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.8)],
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
                        '${widget.trip.days} Day • ${widget.trip.budget}',
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
    DateTime? selectedDate = widget.trip.startDate ?? widget.trip.tripDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(          // ← ctx + StatefulBuilder
        builder: (_, setModal) => Padding(        // ← setModal burada tanımlı
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
              const Text('Edit the Plan',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: titleCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'New Plan Name',
                  labelStyle: const TextStyle(color: _teal),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _teal)),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Travel History',
                  style: TextStyle(fontSize: 13,
                      fontWeight: FontWeight.w600, color: _textMid)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker( //takvim
                    context: context,
                    initialDate: selectedDate ?? DateTime.now(),
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    builder: (ctx, child) => Theme(
                      data: Theme.of(ctx).copyWith(
                        colorScheme: const ColorScheme.light(primary: _teal),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) setModal(() => selectedDate = picked); //UI güncelle
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(children: [
                    const Icon(Icons.calendar_today_rounded, color: _teal, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      selectedDate != null
                          ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                          : 'Choose a date...',
                      style: TextStyle(
                        color: selectedDate != null ? _textDark : Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    if (selectedDate != null)
                      GestureDetector(
                        onTap: () => setModal(() => selectedDate = null),  // ← çalışır
                        child: const Icon(Icons.close_rounded, color: Colors.grey, size: 18),
                      ),
                  ]),
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
                    await RoutesService().updateTrip( //update Firestone
                      widget.trip.id,
                      title: titleCtrl.text.trim(),
                      tripDate: selectedDate,  // seçilen tarih
                      startDate: selectedDate, // aynı tarih startDate olarak da kaydediliyor
                      days: widget.trip.days,
                    );
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Save Changes',
                      style: TextStyle(color: Colors.white,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Plan',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete the ${widget.trip.title} route?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: _textMid))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              Navigator.pop(context);
              await RoutesService().deleteTrip(widget.trip.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}