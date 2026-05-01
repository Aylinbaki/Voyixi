import 'package:flutter/material.dart';
import '../../trip_result/trip_result_model.dart';
import '../active_trip_state_model.dart';
import 'review_sheet.dart';

class ActivePlaceCard extends StatelessWidget {
  final PlaceItem place;
  final int number;
  final TripPlaceState state;
  final Color dayColor;
  final VoidCallback onComplete;
  final void Function(int rating, String review) onReview;

  const ActivePlaceCard({
    super.key,
    required this.place,
    required this.number,
    required this.state,
    required this.dayColor,
    required this.onComplete,
    required this.onReview,
  });

  bool get _isCurrent => state.status == TripPlaceStatus.current;
  bool get _isCompleted => state.status == TripPlaceStatus.completed;

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
            : _isCompleted ? Border.all(color: dayColor.withOpacity(0.25)) : null,
        boxShadow: [
          BoxShadow(
            color: _isCurrent
                ? const Color(0xFF0077B6).withOpacity(0.15) : dayColor.withOpacity(0.07),
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
              padding: const EdgeInsets.symmetric( horizontal: 14, vertical: 7),
              decoration: const BoxDecoration(
                color: Color(0xFF0077B6),
                borderRadius: BorderRadius.vertical( top: Radius.circular(18)),
              ),
              child: const Row(children: [
                Icon(Icons.location_on_rounded, color: Colors.white, size: 14),
                SizedBox(width: 6),
                Text('ŞU ANDA BURADASINIZ',
                    style: TextStyle(color: Colors.white,fontSize: 11,fontWeight: FontWeight.w800,letterSpacing: 0.8)),
              ]),
            ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Container(
                    width: 30, height: 30,
                    decoration: BoxDecoration(
                      color: _isCompleted
                          ? dayColor.withOpacity(0.15) : _isCurrent
                              ? const Color(0xFF0077B6) : dayColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: _isCompleted
                          ? Icon(Icons.check_rounded,
                              color: dayColor, size: 16)
                          : Text('$number',
                              style: const TextStyle( color: Colors.white,fontSize: 13,fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 76, height: 76,
                      child: place.photoUrl != null
                          ? Image.network(place.photoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _placeholder()) : _placeholder(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(place.name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _isCompleted ? const Color(0xFF8AABAB) : const Color(0xFF1A2E2E),
                            )),
                        const SizedBox(height: 4),
                        Text(place.description,
                            style: const TextStyle(fontSize: 12,color: Color(0xFF6B8C8C), height: 1.4),
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(height: 10),
                Wrap(spacing: 8, children: [
                  _chip(Icons.access_time_rounded, place.timeSlot,const Color(0xFFE8F5F3), const Color(0xFF00BFA5)),
                  _crowdChip(place.crowdLevel),
                ]),
                const SizedBox(height: 10),
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
                        Row(children: [
                          const Icon(Icons.person_outline_rounded,
                              color: Color(0xFFF9A825), size: 14),
                          const SizedBox(width: 6),
                          const Text('Değerlendirmeniz',
                              style: TextStyle(color: Color(0xFFF9A825),fontSize: 11,fontWeight: FontWeight.w700)),
                        ]),
                        const SizedBox(height: 6),
                        Row(
                          children: List.generate(5, (i) => Icon(
                            i < (state.rating ?? 0) 
                            ? Icons.star_rounded: Icons.star_outline_rounded,
                            color: Colors.amber, size: 18,
                          )),
                        ),
                        if (state.review != null &&
                            state.review!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text('"${state.review}"',
                              style: const TextStyle( color: Color(0xFF4A6060),fontSize: 12,fontStyle: FontStyle.italic)),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _outlineBtn(
                    icon: Icons.edit_outlined, label: 'Yorumu Düzenle', color: const Color(0xFF00BFA5), onTap: () => _showReview(context),
                  ),
                ],
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
                    label: 'Nasıl Giderim?',
                    color: dayColor,
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
          Text(label,style: TextStyle(fontSize: 11,color: fg,fontWeight: FontWeight.w600)),
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
          child: Row(mainAxisAlignment: MainAxisAlignment.center,
              children: [
            Icon(icon, color: Colors.white, size: 15),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(color: Colors.white,fontSize: 12,fontWeight: FontWeight.w700)),
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
          child: Row(mainAxisAlignment: MainAxisAlignment.center,
              children: [
            Icon(icon, color: color, size: 15),
            const SizedBox(width: 6),
            Text(label,style: TextStyle(color: color,fontSize: 12,fontWeight: FontWeight.w600)),
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