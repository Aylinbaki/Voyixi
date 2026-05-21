import 'package:flutter/material.dart';
import '../trip_result_model.dart';
import 'place_detail_sheet.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../services/favorites_service.dart';

//  StatefulWidget: Kalp butonunun anlık görsel güncellemesi için
class PlaceCard extends StatefulWidget {
  final PlaceItem place;
  final int index;
  final Color dayColor;
  final String city;
  final String budget;
  final VoidCallback onDelete;
  final Future<void> Function() onReplace;

  const PlaceCard({
    super.key,
    required this.place,
    required this.index,
    required this.dayColor,
    required this.city,
    required this.budget,
    required this.onDelete,
    required this.onReplace,
  });

  @override
  State<PlaceCard> createState() => _PlaceCardState();
}

class _PlaceCardState extends State<PlaceCard> {
  bool _isFavorited = false;

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
      // Favoriden çıkar — stream'den doc ID bul ve sil
      final places = await FavoritesService.favoritePlacesStream().first;
      final doc = places.firstWhere(
            (p) => p.name == widget.place.name && p.city == widget.city,
        orElse: () => FavoritePlace(name: '', description: '', city: ''),
      );
      if (doc.id != null) await FavoritesService.removeFavoritePlace(doc.id!);
    } else {
      // Favoriye ekle
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
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => PlaceDetailSheet(place: widget.place, dayColor: widget.dayColor),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: widget.dayColor.withOpacity(0.10),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Numara balonu
                  Container(
                    width: 30, height: 30,
                    decoration: BoxDecoration(
                      color: widget.dayColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text('${widget.index}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Fotoğraf
                  ClipRRect(
  borderRadius: BorderRadius.circular(12),
  child: SizedBox(
    width: 80,
    height: 80,
    child: widget.place.hasPhoto
        ? Image.network(
            widget.place.resolvedPhotoUrl!,
            fit: BoxFit.cover,
            cacheWidth: 200,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: widget.dayColor,
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              debugPrint('⚠️ Image load error: $error');
              return _placeholderImage(widget.dayColor);
            },
          )
        : _placeholderImage(widget.dayColor),
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
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1A2E2E),
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
                            const SizedBox(width: 6),
                            // Sil
                            GestureDetector(
                              onTap: widget.onDelete,
                              child: Container(
                                width: 26, height: 26,
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close_rounded,
                                    size: 14, color: Colors.red),
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
            ),
            // Alt kısım: etiketler + butonlar
            Container(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                children: [
                  // Etiket satırı
                  Row(
                    children: [
                      _chip(Icons.access_time_rounded, widget.place.timeSlot,
                          const Color(0xFFE8F5F3), const Color(0xFF00BFA5)),
                      const SizedBox(width: 8),
                      _chip(Icons.timer_outlined, widget.place.duration,
                          const Color(0xFFE8F0FF), const Color(0xFF5B8DEF)),
                      const SizedBox(width: 8),
                      _crowdChip(widget.place.crowdLevel),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _outlineButton(
                          icon: Icons.swap_horiz_rounded,
                          label: 'Değiştir',
                          color: widget.dayColor,
                          onTap: widget.onReplace,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _fillButton(
                          icon: Icons.navigation_rounded,
                          label: 'Nasıl Giderim?',
                          color: widget.dayColor,
                          onTap: () => _openMaps(widget.place),
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

  Widget _placeholderImage(Color color) => Container(
    color: color.withOpacity(0.12),
    child: Icon(Icons.place_rounded, color: color, size: 32),
  );

  Widget _chip(IconData icon, String label, Color bg, Color fg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: fg),
      const SizedBox(width: 4),
      Text(label,
          style: TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.w600)),
    ]),
  );

  Widget _crowdChip(String level) {
    final colors = {
      'Sakin': (const Color(0xFFE8F5E9), const Color(0xFF4CAF50)),
      'Orta': (const Color(0xFFFFF8E1), const Color(0xFFF9A825)),
      'Yoğun': (const Color(0xFFFFF3E0), const Color(0xFFEF6C00)),
      'Çok Yoğun': (const Color(0xFFFFEBEE), const Color(0xFFE53935)),
    };
    final c = colors[level] ?? colors['Orta']!;
    return _chip(Icons.people_rounded, level, c.$1, c.$2);
  }

  Widget _outlineButton({
    required IconData icon,
    required String label,
    required Color color,
    required Future<void> Function() onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            border: Border.all(color: color.withOpacity(0.4)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    color: color, fontSize: 12, fontWeight: FontWeight.w600)),
          ]),
        ),
      );

  Widget _fillButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 5),
            Text(label,
                style: const TextStyle(
                    color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          ]),
        ),
      );

  void _openMaps(PlaceItem p) async {
    if (p.lat == null || p.lng == null) return;
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
          '&destination=${p.lat},${p.lng}&travelmode=walking',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}