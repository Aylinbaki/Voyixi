import 'dart:ui';
import 'package:flutter/material.dart';
import 'routes_service.dart';
import 'routes_model.dart';
import '../../widgets/navigation_bar.dart';
import '../active_trip/active_trip_screen.dart';
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
      expandedHeight: 120.0,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        centerTitle: false,
        title: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Rotalarım',
                style: TextStyle(color: _textDark, fontSize: 22, fontWeight: FontWeight.w800)),
            if (count > 0)
              Text('$count Kayıtlı Plan',
                  style: const TextStyle(color: _textMid, fontSize: 11, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _teal, size: 20),
        onPressed: () => Navigator.maybePop(context),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Image.asset('assets/images/app_logo_plan.png', height: 40),
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
class _ModernTripCard extends StatelessWidget {
  final SavedTrip trip;
  const _ModernTripCard({required this.trip});

  static const _teal = Color(0xFF00BFA5);
  static const _textDark = Color(0xFF1A2E2E);
  static const _textMid = Color(0xFF4A6060);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ActiveTripScreen(
        savedTrip: trip,
        tripResult: trip.toTripResult(),
      ),
    ),
  ),
  child: Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(  
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 15, offset: const Offset(0, 8)),
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
                  child: trip.imageUrl != null
                      ? Image.network(trip.imageUrl!, fit: BoxFit.cover)
                      : Container(color: _teal.withOpacity(0.1), child: const Icon(Icons.image, color: _teal)),
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
                          Text(trip.city, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
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
                  child: Text(trip.title, 
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
                Text(trip.summary, 
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _textMid, fontSize: 13, height: 1.4)),
                const SizedBox(height: 12),
                
                // TERCİHLER (PREFERENCES)
                if (trip.preferences.isNotEmpty)
                  Wrap(
                    spacing: 6, runSpacing: 6,
                    children: trip.preferences.take(3).map((p) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: _teal.withOpacity(0.08), borderRadius: BorderRadius.circular(20)),
                      child: Text(p, style: const TextStyle(color: _teal, fontSize: 10, fontWeight: FontWeight.w600)),
                    )).toList(),
                  ),
                const SizedBox(height: 16),
                
                // ALT BİLGİ VE SİLME FONKSİYONU
                Row(
                  children: [
                    const Icon(Icons.access_time_filled_rounded, size: 14, color: _teal),
                    const SizedBox(width: 4),
                    Text('${trip.days} Gün • ${trip.budget}', 
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _textDark)),
                    const Spacer(),
                    
                    // SİLME BUTONU (FONKSİYONEL)
                    GestureDetector(
                      onTap: () => _confirmDelete(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.red.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent),
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
  // ── SENİN ORİJİNAL FONKSİYONLARIN (GÜNCELLENDİ) ───────────────────────────

  void _showEditDialog(BuildContext context) {
    final titleCtrl = TextEditingController(text: trip.title);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 20),
            const Text('Plan Adını Düzenle', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: titleCtrl,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Yeni Plan Adı',
                labelStyle: const TextStyle(color: _teal),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _teal)),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _teal,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  await RoutesService().updateTrip(trip.id, title: titleCtrl.text.trim());
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Değişiklikleri Kaydet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
        title: const Text('Planı Sil', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('"${trip.title}" rotasını silmek istediğine emin misin?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Vazgeç', style: TextStyle(color: _textMid))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              Navigator.pop(context);
              await RoutesService().deleteTrip(trip.id);
            },
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}