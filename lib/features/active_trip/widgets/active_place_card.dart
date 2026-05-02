import 'package:flutter/material.dart';
import '../../trip_result/trip_result_model.dart';
import '../active_trip_state_model.dart';
import 'review_sheet.dart';
import '../../../services/favorites_service.dart';

//  StatefulWidget: Kalp butonunun anlık görsel güncellemesi için
class ActivePlaceCard extends StatefulWidget {
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

  @override
  State<ActivePlaceCard> createState() => _ActivePlaceCardState();
}

class _ActivePlaceCardState extends State<ActivePlaceCard> {
  bool _isFavorited = false;

  bool get _isCurrent => widget.state.status == TripPlaceStatus.current;
  bool get _isCompleted => widget.state.status == TripPlaceStatus.completed;

  @override
  void initState() {
    super.initState();
    _checkFavorite();
  }

  // Firestore'dan bu mekanın favoride olup olmadığını kontrol et
  Future<void> _checkFavorite() async {
    final result = await FavoritesService.isPlaceFavorited(
        widget.place.name, widget.city);
    if (mounted) setState(() => _isFavorited = result);
  }

  // Kalbe basınca: favorideyse çıkar, değilse ekle
  Future<void> _toggleFavorite() async {
    if (_isFavorited) {
      final places = await FavoritesService.favoritePlacesStream().first;
      final doc = places.firstWhere(
            (p) => p.name == widget.place.name && p.city == widget.city,
        orElse: () => FavoritePlace(name: '', description: '', city: ''),
      );
      if (doc.id != null) await FavoritesService.removeFavoritePlace(doc.id!);
    } else {
      await FavoritesService.addFavoritePlace(FavoritePlace(
        name: widget.place.name,
        description: widget.place.description,
        city: widget.city,
        photoUrl: widget.place.photoUrl,
        placeId: widget.place.placeId,
        lat: widget.place.lat,
        lng: widget.place.lng,
      ));
    }
    // setState ile ikon anında değişir
    if (mounted) setState(() => _isFavorited = !_isFavorited);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: _isCurrent
            ? Border.all(color: const Color(0xFF0077B6), width: 2)
            : _isCompleted
            ? Border.all(color: widget.dayColor.withOpacity(0.25))
            : null,
        boxShadow: [
          BoxShadow(
            color: _isCurrent
                ? const Color(0xFF0077B6).withOpacity(0.15)
                : widget.dayColor.withOpacity(0.07),
            blurRadius: _isCurrent ? 20 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isCurrent)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: const BoxDecoration(
                color: Color(0xFF0077B6),
                borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: const Row(children: [
                Icon(Icons.location_on_rounded, color: Colors.white, size: 14),
                SizedBox(width: 6),
                Text('ŞU ANDA BURADASINIZ',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8)),
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
                    // Numara / tamamlandı ikonu
                    Container(
                      width: 30, height: 30,
                      decoration: BoxDecoration(
                        color: _isCompleted
                            ? widget.dayColor.withOpacity(0.15)
                            : _isCurrent
                            ? const Color(0xFF0077B6)
                            : widget.dayColor,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: _isCompleted
                            ? Icon(Icons.check_rounded,
                            color: widget.dayColor, size: 16)
                            : Text('${widget.number}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Fotoğraf
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 76, height: 76,
                        child: widget.place.photoUrl != null
                            ? Image.network(widget.place.photoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholder())
                            : _placeholder(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(widget.place.name,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: _isCompleted
                                          ? const Color(0xFF8AABAB)
                                          : const Color(0xFF1A2E2E),
                                    )),
                              ),
                              // Kalp butonu
                              GestureDetector(
                                onTap: _toggleFavorite,
                                child: Container(
                                  width: 26, height: 26,
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.08),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _isFavorited
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    size: 14,
                                    color: _isFavorited
                                        ? Colors.redAccent
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(widget.place.description,
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
                Wrap(spacing: 8, children: [
                  _chip(Icons.access_time_rounded, widget.place.timeSlot,
                      const Color(0xFFE8F5F3), const Color(0xFF00BFA5)),
                  _crowdChip(widget.place.crowdLevel),
                ]),
                const SizedBox(height: 10),

                // Tamamlanan mekan değerlendirmesi
                if (_isCompleted && widget.state.rating != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Icon(Icons.person_outline_rounded,
                              color: Color(0xFFF9A825), size: 14),
                          const SizedBox(width: 6),
                          const Text('Değerlendirmeniz',
                              style: TextStyle(
                                  color: Color(0xFFF9A825),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700)),
                        ]),
                        const SizedBox(height: 6),
                        Row(
                          children: List.generate(
                              5,
                                  (i) => Icon(
                                i < (widget.state.rating ?? 0)
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                color: Colors.amber,
                                size: 18,
                              )),
                        ),
                        if (widget.state.review != null &&
                            widget.state.review!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text('"${widget.state.review}"',
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
                    label: 'Yorumu Düzenle',
                    color: const Color(0xFF00BFA5),
                    onTap: () => _showReview(context),
                  ),
                ],

                // Şu an bulunan mekan
                if (_isCurrent) ...[
                  Row(children: [
                    Expanded(
                      child: _fillBtn(
                        icon: Icons.volume_up_rounded,
                        label: 'Sesli Rehber',
                        color: const Color(0xFF9C6FDE),
                        onTap: () {},
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _fillBtn(
                        icon: Icons.check_circle_rounded,
                        label: 'Tamamlandı',
                        color: const Color(0xFF00BFA5),
                        onTap: () {
                          widget.onComplete();
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
                    label: 'Nasıl Giderim?',
                    color: widget.dayColor,
                    onTap: () {},
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
      color: widget.dayColor.withOpacity(0.12),
      child: Icon(Icons.place_rounded, color: widget.dayColor, size: 28));

  Widget _chip(IconData icon, String label, Color bg, Color fg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration:
    BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 11, color: fg),
      const SizedBox(width: 4),
      Text(label,
          style: TextStyle(
              fontSize: 11, color: fg, fontWeight: FontWeight.w600)),
    ]),
  );

  Widget _crowdChip(String level) {
    final map = {
      'Sakin': (const Color(0xFFE8F5E9), const Color(0xFF4CAF50)),
      'Orta': (const Color(0xFFFFF8E1), const Color(0xFFF9A825)),
      'Yoğun': (const Color(0xFFFFF3E0), const Color(0xFFEF6C00)),
      'Çok Yoğun': (const Color(0xFFFFEBEE), const Color(0xFFE53935)),
    };
    final c = map[level] ?? map['Orta']!;
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
          child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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
        placeName: widget.place.name,
        initialRating: widget.state.rating,
        initialReview: widget.state.review,
        onSave: widget.onReview,
      ),
    );
  }
}