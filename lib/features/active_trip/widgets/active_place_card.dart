// lib/features/active_trip/widgets/active_place_card.dart

import 'package:flutter/material.dart';
import '../../trip_result/trip_result_model.dart';
import '../../trip_result/widgets/place_detail_sheet.dart';
import '../active_trip_state_model.dart';
import 'audio_guide_button.dart';
import 'crowd_indicator.dart';
import 'review_sheet.dart';

class ActivePlaceCard extends StatelessWidget {
  final PlaceItem place;
  final int number;
  final TripPlaceState state;
  final Color dayColor;
  final String city;
  final VoidCallback onComplete;
  final void Function(int rating, String review) onReview;

  const ActivePlaceCard({
    super.key,
    required this.place,
    required this.number,
    required this.state,
    required this.dayColor,
    required this.city,
    required this.onComplete,
    required this.onReview,
  });

  bool get _isCurrent => state.status == TripPlaceStatus.current;
  bool get _isCompleted => state.status == TripPlaceStatus.completed;

  void _openDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PlaceDetailSheet(
        place: place,
        dayColor: dayColor,
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Karta tıklayınca detay sheet aç
      onTap: () => _openDetail(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: _isCurrent
              ? Border.all(color: const Color(0xFF0077B6), width: 2)
              : _isCompleted
              ? Border.all(color: dayColor.withOpacity(0.25))
              : null,
          boxShadow: [
            BoxShadow(
              color: _isCurrent
                  ? const Color(0xFF0077B6).withOpacity(0.15)
                  : dayColor.withOpacity(0.07),
              blurRadius: _isCurrent ? 20 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // "Şu anda buradasın" banner
            if (_isCurrent)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 7),
                decoration: const BoxDecoration(
                  color: Color(0xFF0077B6),
                  borderRadius:
                  BorderRadius.vertical(top: Radius.circular(18)),
                ),
                child: const Row(children: [
                  Icon(Icons.location_on_rounded,
                      color: Colors.white, size: 14),
                  SizedBox(width: 6),
                  // 1. ÇEVİRİ: Şu an buradasınız banner metinleri İngilizce yapıldı
                  Text('YOU ARE HERE NOW',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8)),
                  Spacer(),
                  Text('Tap for details →',
                      style: TextStyle(
                          color: Colors.white60, fontSize: 10)),
                ]),
              ),

            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Numara balonu
                      Container(
                        width: 30, height: 30,
                        decoration: BoxDecoration(
                          color: _isCompleted
                              ? dayColor.withOpacity(0.15)
                              : _isCurrent
                              ? const Color(0xFF0077B6)
                              : dayColor,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: _isCompleted
                              ? Icon(Icons.check_rounded,
                              color: dayColor, size: 16)
                              : Text('$number',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 76,
                          height: 76,
                          child: place.hasPhoto
                              ? Image.network(
                                  place.resolvedPhotoUrl!,
                                  fit: BoxFit.cover,
                                  cacheWidth: 150,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: dayColor,
                                          value: loadingProgress.expectedTotalBytes != null
                                              ? loadingProgress.cumulativeBytesLoaded /
                                                  loadingProgress.expectedTotalBytes!
                                              : null,
                                        ),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    debugPrint(
                                        '⚠️ ActivePlaceCard image error (${place.name}): $error');
                                    return _placeholder();
                                  },
                                )
                              : _placeholder(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // İsim + açıklama
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(place.name,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: _isCompleted
                                      ? const Color(0xFF8AABAB)
                                      : const Color(0xFF1A2E2E),
                                )),
                            const SizedBox(height: 4),
                            Text(place.description,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF6B8C8C),
                                    height: 1.4),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Etiketler
                  Row(children: [
                    _chip(Icons.access_time_rounded, place.timeSlot,
                        const Color(0xFFE8F5F3), const Color(0xFF00BFA5)),
                    const SizedBox(width: 8),

                    // Kalabalık: aktif mekan için gerçek zamanlı, diğerleri statik
                    if (_isCurrent)
  CrowdIndicator(
    placeName: place.name,
    city: city,
    placeId: place.placeId, // 🔴 İŞTE BURASI!
    fallbackLevel: place.crowdLevel,
  )
                    else
                      _staticCrowdChip(place.crowdLevel),
                  ]),
                  const SizedBox(height: 10),

                  // Tamamlanan — yorum göster
                  if (_isCompleted && state.rating != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(children: [
                            Icon(Icons.person_outline_rounded,
                                color: Color(0xFFF9A825), size: 14),
                            SizedBox(width: 6),
                            // 2. ÇEVİRİ: Yorum başlığı İngilizce yapıldı
                            Text('Your Review',
                                style: TextStyle(
                                    color: Color(0xFFF9A825),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700)),
                          ]),
                          const SizedBox(height: 6),
                          Row(
                            children: List.generate(5, (i) => Icon(
                              i < (state.rating ?? 0)
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: Colors.amber,
                              size: 18,
                            )),
                          ),
                          if (state.review != null &&
                              state.review!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text('"${state.review}"',
                                style: const TextStyle(
                                    color: Color(0xFF4A6060),
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic)),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    _outlineBtn(
                      icon: Icons.edit_outlined,
                      // 3. ÇEVİRİ: Yorum düzenleme butonu İngilizce yapıldı
                      label: 'Edit Review',
                      color: const Color(0xFF00BFA5),
                      onTap: () => _showReview(context),
                    ),
                  ],

                  // Aktif mekan butonları
                  if (_isCurrent) ...[
                    Row(children: [
                      Expanded(
                        child: AudioGuideButton(
                          placeName: place.name,
                          city: city,
                          description: place.description,
                          color: const Color(0xFF9C6FDE),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _fillBtn(
                          icon: Icons.check_circle_rounded,
                          // 4. ÇEVİRİ: Tamamlandı onay butonu İngilizce yapıldı
                          label: 'Completed',
                          color: const Color(0xFF00BFA5),
                          onTap: () {
                            onComplete();
                            _showReview(context);
                          },
                        ),
                      ),
                    ]),
                  ],

                  // Bekleyen mekan
                  if (!_isCurrent && !_isCompleted)
                    _outlineBtn(
                      icon: Icons.navigation_rounded,
                      // 5. ÇEVİRİ: Navigasyon yönlendirme butonu İngilizce yapıldı
                      label: 'How to Get There?',
                      color: dayColor,
                      onTap: () {},
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
      color: dayColor.withOpacity(0.12),
      child: Icon(Icons.place_rounded, color: dayColor, size: 28));

  Widget _chip(IconData icon, String label, Color bg, Color fg) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: fg, fontWeight: FontWeight.w600)),
        ]),
      );

  // Statik crowd chip (aktif olmayan kartlar için)
  // ── FIX: Gemini veri yapısıyla tam uyumlu İngilizce Crowd eşleştirmesi ──
  Widget _staticCrowdChip(String level) {
    final map = {
      'Calm': (const Color(0xFFE8F5E9), const Color(0xFF4CAF50)),
      'Moderate': (const Color(0xFFFFF8E1), const Color(0xFFF9A825)),
      'Busy': (const Color(0xFFFFF3E0), const Color(0xFFEF6C00)),
      'Very Busy': (const Color(0xFFFFEBEE), const Color(0xFFE53935)),
    };
    final c = map[level] ?? map['Moderate']!;
    return _chip(Icons.people_rounded, level, c.$1, c.$2);
  }

  Widget _fillBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(12)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: Colors.white, size: 15),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ]),
        ),
      );

  Widget _outlineBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            border: Border.all(color: color.withOpacity(0.4)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 15),
                const SizedBox(width: 6),
                Text(label,
                    style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ]),
        ),
      );

  void _showReview(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReviewSheet(
        placeName: place.name,
        initialRating: state.rating,
        initialReview: state.review,
        onSave: onReview,
      ),
    );
  }
}