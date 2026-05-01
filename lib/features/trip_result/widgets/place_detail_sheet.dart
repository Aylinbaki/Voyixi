import 'package:flutter/material.dart';
import '../trip_result_model.dart';

class PlaceDetailSheet extends StatelessWidget {
  final PlaceItem place;
  final Color dayColor;
  const PlaceDetailSheet({super.key, required this.place, required this.dayColor});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  if (place.photoUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        place.photoUrl!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _photoPlaceholder(),
                      ),
                    )
                  else
                    _photoPlaceholder(),
                  const SizedBox(height: 20),
                  Text(place.name,
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A2E2E))),
                  const SizedBox(height: 8),
                  Text(place.description,
                      style: const TextStyle(
                          fontSize: 14, color: Color(0xFF4A6060), height: 1.6)),
                  const SizedBox(height: 20),
                  Row(children: [
                    Expanded(child: _infoCard(Icons.access_time_rounded,
                        'Ziyaret Saati', place.timeSlot, dayColor)),
                    const SizedBox(width: 10),
                    Expanded(child: _infoCard(Icons.timer_outlined,
                        'Süre', place.duration, const Color(0xFF5B8DEF))),
                  ]),
                  const SizedBox(height: 10),
                  _infoCard(Icons.people_rounded, 'Kalabalık Tahmini',
                      place.crowdLevel, _crowdColor(place.crowdLevel)),
                  const SizedBox(height: 20),
                  if (place.lat != null)
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.navigation_rounded, size: 18),
                      label: const Text('Google Maps\'te Aç'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: dayColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
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

  Widget _photoPlaceholder() => Container(
        height: 200,
        decoration: BoxDecoration(
          color: dayColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(child: Icon(Icons.place_rounded, color: dayColor, size: 48)),
      );

  Widget _infoCard(IconData icon, String label, String value, Color color) =>
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: TextStyle(
                    fontSize: 11, color: color, fontWeight: FontWeight.w600)),
            Text(value,
                style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1A2E2E),
                    fontWeight: FontWeight.w700)),
          ]),
        ]),
      );

  Color _crowdColor(String level) => switch (level) {
        'Sakin' => const Color(0xFF4CAF50),
        'Yoğun' => const Color(0xFFEF6C00),
        'Çok Yoğun' => const Color(0xFFE53935),
        _ => const Color(0xFFF9A825),
      };
}