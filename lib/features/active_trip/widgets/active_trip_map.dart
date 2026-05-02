import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../trip_result/trip_result_model.dart';
import '../active_trip_state_model.dart';
import 'package:flutter/gestures.dart';

const _dayBaseColors = [
  Color(0xFF00BFA5), Color(0xFF5B8DEF), Color(0xFF9C6FDE),
  Color(0xFFEF6C8D), Color(0xFF43A047), Color(0xFFF9A825),
];

class ActiveTripMap extends StatefulWidget {
  final List<DayPlan> dayPlans;
  final List<TripPlaceState> states;

  const ActiveTripMap({
    super.key,
    required this.dayPlans,
    required this.states,
  });

  @override
  State<ActiveTripMap> createState() => _ActiveTripMapState();
}

class _ActiveTripMapState extends State<ActiveTripMap> {
  GoogleMapController? _ctrl;
  Map<MarkerId, Marker> _markers = {};
  Map<PolylineId, Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _buildMarkers());
  }

  @override
  void didUpdateWidget(ActiveTripMap old) {
    super.didUpdateWidget(old);
    _buildMarkers();
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  TripPlaceState _stateOf(int dayIdx, int placeIdx) =>
      widget.states.firstWhere(
        (s) => s.dayIdx == dayIdx && s.placeIdx == placeIdx,
        orElse: () => TripPlaceState(dayIdx: dayIdx, placeIdx: placeIdx),
      );

  Color _markerColor(TripPlaceStatus status, Color dayColor) {
    switch (status) {
      case TripPlaceStatus.completed:
        return dayColor.withOpacity(0.4);
      case TripPlaceStatus.current:
        return const Color(0xFF0077B6);
      case TripPlaceStatus.waiting:
        return dayColor;
    }
  }

  double _markerSize(TripPlaceStatus status) {
    switch (status) {
      case TripPlaceStatus.current: return 64.0;
      case TripPlaceStatus.completed: return 40.0;
      case TripPlaceStatus.waiting: return 50.0;
    }
  }

  Future<void> _buildMarkers() async {
    final newMarkers = <MarkerId, Marker>{};
    final newPolylines = <PolylineId, Polyline>{};

    for (int d = 0; d < widget.dayPlans.length; d++) {
      final dayColor = _dayBaseColors[d % _dayBaseColors.length];
      final places = widget.dayPlans[d].places;

      for (int p = 0; p < places.length; p++) {
        final place = places[p];
        if (place.lat == null || place.lng == null) continue;

        final state = _stateOf(d, p);
        final color = _markerColor(state.status, dayColor);
        final size = _markerSize(state.status);
        final markerId = MarkerId('${d}_$p');

        final icon = await _buildMarkerIcon(
          number: p + 1,
          color: color,
          size: size,
          isCurrent: state.status == TripPlaceStatus.current,
          isCompleted: state.status == TripPlaceStatus.completed,
        );

        newMarkers[markerId] = Marker(
          markerId: markerId,
          position: LatLng(place.lat!, place.lng!),
          icon: icon,
          zIndex: state.status == TripPlaceStatus.current ? 2 : 1,
          infoWindow: InfoWindow(
            title: state.status == TripPlaceStatus.current
                ? '📍 Şu An: ${place.name}'
                : state.status == TripPlaceStatus.completed
                    ? '✅ ${place.name}'
                    : place.name,
            snippet: place.timeSlot,
          ),
        );

        // Polyline — önceki mekanla bağla
        if (p > 0) {
          final prev = places[p - 1];
          if (prev.lat != null && prev.lng != null) {
            final prevState = _stateOf(d, p - 1);
            final isCompletedLine =
                prevState.status == TripPlaceStatus.completed;
            final polyId = PolylineId('${d}_$p');
            newPolylines[polyId] = Polyline(
              polylineId: polyId,
              points: [
                LatLng(prev.lat!, prev.lng!),
                LatLng(place.lat!, place.lng!),
              ],
              color: isCompletedLine? dayColor.withOpacity(0.3) : dayColor,
              width: isCompletedLine ? 2 : 3,
              patterns: isCompletedLine
                  ? [PatternItem.dash(8), PatternItem.gap(6)]
                  : [],
            );
          }
        }
      }
    }

    if (!mounted) return;
    setState(() {
      _markers = newMarkers;
      _polylines = newPolylines;
    });

    // Aktif mekanı göster
    final current = widget.states
        .where((s) => s.status == TripPlaceStatus.current)
        .toList();
    if (current.isNotEmpty && _ctrl != null) {
      final cp = current.first;
      final place =
          widget.dayPlans[cp.dayIdx].places[cp.placeIdx];
      if (place.lat != null) {
        _ctrl!.animateCamera(CameraUpdate.newLatLngZoom(
            LatLng(place.lat!, place.lng!), 14));
      }
    }
  }

  Future<BitmapDescriptor> _buildMarkerIcon({
    required int number,
    required Color color,
    required double size,
    required bool isCurrent,
    required bool isCompleted,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Aktif için dış halka
    if (isCurrent) {
      canvas.drawCircle(Offset(size / 2, size / 2), size / 2,
          Paint()..color = color.withOpacity(0.2));
    }

    // Gölge
    canvas.drawCircle(
      Offset(size / 2, size / 2 + 2),
      size / 2 - 7,
      Paint()
        ..color = Colors.black.withOpacity(0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Ana daire
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 6,
        Paint()..color = color);

    // Beyaz kenar
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 2 - 8,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = isCurrent ? 3 : 2,
    );

    // İçerik: tamamlandıysa tik, değilse rakam
    final text = isCompleted ? '✓' : '$number';
    final fontSize = isCompleted ? size * 0.32 : size * 0.3;
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
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

  @override
Widget build(BuildContext context) {
  LatLng center = const LatLng(41.0082, 28.9784);
  outer:
  for (final day in widget.dayPlans) {
    for (final p in day.places) {
      if (p.lat != null) {
        center = LatLng(p.lat!, p.lng!);
        break outer;
      }
    }
  }

  return SizedBox(
    height: 240,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          RawGestureDetector(
            gestures: {
              PanGestureRecognizer:
                  GestureRecognizerFactoryWithHandlers<PanGestureRecognizer>(
                () => PanGestureRecognizer(),
                (i) => i.onDown = (_) {},
              ),
              ScaleGestureRecognizer:
                  GestureRecognizerFactoryWithHandlers<ScaleGestureRecognizer>(
                () => ScaleGestureRecognizer(),
                (i) => i.onStart = (_) {},
              ),
            },
            child: GoogleMap(
              initialCameraPosition:
                  CameraPosition(target: center, zoom: 13),
              markers: Set.of(_markers.values),
              polylines: Set.of(_polylines.values),
              onMapCreated: (c) {
                _ctrl = c;
                _buildMarkers();
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
          // Legend
          Positioned(
            bottom: 10, left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.93),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(
                    color: Colors.black.withOpacity(0.07), blurRadius: 8)],
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                _dot(const Color(0xFF00BFA5).withOpacity(0.4), 'Tamamlandı'),
                const SizedBox(width: 10),
                _dot(const Color(0xFF0077B6), 'Şu An'),
                const SizedBox(width: 10),
                _dot(const Color(0xFF00BFA5), 'Bekliyor'),
              ]),
            ),
          ),
        ],
      ),
    ),
  );
}
  Widget _dot(Color color, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10, height: 10,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: Color(0xFF4A6060))),
        ],
      );
}