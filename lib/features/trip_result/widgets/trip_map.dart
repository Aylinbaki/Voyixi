import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../trip_result_model.dart';

const _dayColors = [
  Color(0xFF00BFA5),
  Color(0xFF5B8DEF),
  Color(0xFF9C6FDE),
  Color(0xFFEF6C8D),
  Color(0xFF43A047),
  Color(0xFFF9A825),
  Color(0xFF00ACC1),
];

class TripMap extends StatefulWidget {
  final List<DayPlan> dayPlans;
  const TripMap({super.key, required this.dayPlans});

  @override
  State<TripMap> createState() => TripMapState();
}

class TripMapState extends State<TripMap> {
  GoogleMapController? _mapController;
  final Map<MarkerId, Marker> _markers = {};
  final Map<PolylineId, Polyline> _polylines = {};
  int _visibleCount = 0;

  List<({PlaceItem place, int dayIdx, int placeIdx})> get _allPlaces {
    final result = <({PlaceItem place, int dayIdx, int placeIdx})>[];
    for (int d = 0; d < widget.dayPlans.length; d++) {
      for (int p = 0; p < widget.dayPlans[d].places.length; p++) {
        final pl = widget.dayPlans[d].places[p];
        if (pl.lat != null && pl.lng != null) {
          result.add((place: pl, dayIdx: d, placeIdx: p));
        }
      }
    }
    return result;
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
  Future<void> refreshMap() async {
    _markers.clear();
    _polylines.clear();
    if (mounted) setState(() => _visibleCount = 0);
    await _animateMarkers();
  }

  Future<void> _animateMarkers() async {
    final all = _allPlaces;
    if (all.isEmpty) return;

    for (int i = 0; i < all.length; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;

      final item = all[i];
      final color = _dayColors[item.dayIdx % _dayColors.length];
      final markerId = MarkerId('${item.dayIdx}_${item.placeIdx}');
      final icon = await _buildNumberedMarker(item.placeIdx + 1, color);
      if (!mounted) return;
      if (item.placeIdx > 0) {
        final prev = all[i - 1];
        if (prev.dayIdx == item.dayIdx && prev.place.lat != null) {
          final polyId = PolylineId('line_${item.dayIdx}_${item.placeIdx}');
          _polylines[polyId] = Polyline(
            polylineId: polyId,
            points: [
              LatLng(prev.place.lat!, prev.place.lng!),
              LatLng(item.place.lat!, item.place.lng!),
            ],
            color: color,
            width: 3,
            patterns: [PatternItem.dash(12), PatternItem.gap(6)],
          );
        }
      }

      setState(() {
        _markers[markerId] = Marker(
          markerId: markerId,
          position: LatLng(item.place.lat!, item.place.lng!),
          icon: icon,
          infoWindow: InfoWindow(
            title: '${item.placeIdx + 1}. ${item.place.name}',
            snippet: item.place.timeSlot,
          ),
        );
        _visibleCount = i + 1;
      });
    }

    await Future.delayed(const Duration(milliseconds: 300));
    _fitBounds(all);
  }

  Future<BitmapDescriptor> _buildNumberedMarker(int number, Color color) async {
    const size = 52.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Gölge
    canvas.drawCircle(
      const Offset(size / 2, size / 2 + 2),
      size / 2 - 2,
      Paint()
        ..color = Colors.black.withOpacity(0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Dolu daire
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2 - 2,
      Paint()..color = color,
    );

    // Beyaz kenar
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2 - 4,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // Numara
    final tp = TextPainter(
      text: TextSpan(
        text: '$number',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset((size - tp.width) / 2, (size - tp.height) / 2));

    final img = await recorder
        .endRecording()
        .toImage(size.toInt(), size.toInt());
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  void _fitBounds(
      List<({PlaceItem place, int dayIdx, int placeIdx})> all) {
    if (all.isEmpty || _mapController == null) return;

    double minLat = all.first.place.lat!;
    double maxLat = all.first.place.lat!;
    double minLng = all.first.place.lng!;
    double maxLng = all.first.place.lng!;

    for (final item in all) {
      if (item.place.lat! < minLat) minLat = item.place.lat!;
      if (item.place.lat! > maxLat) maxLat = item.place.lat!;
      if (item.place.lng! < minLng) minLng = item.place.lng!;
      if (item.place.lng! > maxLng) maxLng = item.place.lng!;
    }

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat - 0.01, minLng - 0.01),
          northeast: LatLng(maxLat + 0.01, maxLng + 0.01),
        ),
        60,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final all = _allPlaces;
    if (all.isEmpty) return const SizedBox.shrink();

    final center = LatLng(all.first.place.lat!, all.first.place.lng!);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 260,
        child: Stack(
          children: [
            // ── Scroll çakışmasını önlemek için EagerGestureRecognizer ──
            RawGestureDetector(
              gestures: {
                // Harita üzerindeki tüm pan/drag event'lerini harita alır,
                // üstteki ListView'e geçirmez.
                PanGestureRecognizer:
                    GestureRecognizerFactoryWithHandlers<PanGestureRecognizer>(
                  () => PanGestureRecognizer(),
                  (instance) {
                    instance.onDown = (_) {};
                  },
                ),
                ScaleGestureRecognizer:
                    GestureRecognizerFactoryWithHandlers<ScaleGestureRecognizer>(
                  () => ScaleGestureRecognizer(),
                  (instance) {
                    instance.onStart = (_) {};
                  },
                ),
              },
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: center,
                  zoom: 13,
                ),
                markers: Set<Marker>.of(_markers.values),
                polylines: Set<Polyline>.of(_polylines.values),
                onMapCreated: (ctrl) {
                  _mapController = ctrl;
                  Future.delayed(
                    const Duration(milliseconds: 500),
                    _animateMarkers,
                  );
                },
                zoomGesturesEnabled: true,
                scrollGesturesEnabled: true,
                rotateGesturesEnabled: true,
                tiltGesturesEnabled: true,
                zoomControlsEnabled: false,
                myLocationButtonEnabled: false,
                mapToolbarEnabled: false,
              ),
            ),

            // Sağ üst sayaç
            Positioned(
              top: 10, right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.place_rounded,
                      color: Color(0xFF00BFA5), size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '$_visibleCount / ${all.length} mekan',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A2E2E),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}