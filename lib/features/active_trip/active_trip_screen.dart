import 'package:flutter/material.dart';
import '../routes/routes_model.dart';
import '../trip_result/trip_result_model.dart';
import 'active_trip_state_model.dart';
import 'services/active_trip_service.dart';
import 'widgets/active_place_card.dart';
import 'widgets/active_trip_map.dart';
import '../../widgets/navigation_bar.dart';
import 'widgets/audio_guide_button.dart';
import '../../features/routes/routes_service.dart';


const _dayColors = [
  Color(0xFF00BFA5), Color(0xFF5B8DEF), Color(0xFF9C6FDE),
  Color(0xFFEF6C8D), Color(0xFF43A047), Color(0xFFF9A825),
];

class ActiveTripScreen extends StatefulWidget {
  final SavedTrip savedTrip;
  final TripResult tripResult;

  const ActiveTripScreen({
    super.key,
    required this.savedTrip,
    required this.tripResult,
  });

  @override
  State<ActiveTripScreen> createState() => _ActiveTripScreenState();
}

class _ActiveTripScreenState extends State<ActiveTripScreen> {
  List<TripPlaceState> _states = [];
  bool _loading = true;

  static const _teal = Color(0xFF00BFA5);
  static const _blue = Color(0xFF0077B6);
  static const _bg = Color(0xFFF0FAFA);
  static const _textDark = Color(0xFF1A2E2E);

  // Tüm mekanları (dayIdx, placeIdx) ile düz liste
  List<({PlaceItem place, int dayIdx, int placeIdx})> get _allPlaces {
    final result = <({PlaceItem place, int dayIdx, int placeIdx})>[];
    for (int d = 0; d < widget.tripResult.dayPlans.length; d++) {
      for (int p = 0;
          p < widget.tripResult.dayPlans[d].places.length;
          p++) {
        result.add((
          place: widget.tripResult.dayPlans[d].places[p],
          dayIdx: d,
          placeIdx: p,
        ));
      }
    }
    return result;
  }

  int get _completedCount =>
      _states.where((s) => s.status == TripPlaceStatus.completed).length;
  int get _totalCount => _allPlaces.length;

  TripPlaceState _stateOf(int dayIdx, int placeIdx) =>
      _states.firstWhere(
        (s) => s.dayIdx == dayIdx && s.placeIdx == placeIdx,
        orElse: () => TripPlaceState(dayIdx: dayIdx, placeIdx: placeIdx),
      );

  @override
  void initState() {
    super.initState();
    _initStates();
  }

  Future<void> _initStates() async {
    final saved =
        await ActiveTripService().loadProgress(widget.savedTrip.id);

    if (saved.isNotEmpty) {
      setState(() { _states = saved; _loading = false; });
    } else {
      // İlk kez — ilk mekanı current yap
      final all = _allPlaces;
      final initial = all.map((item) => TripPlaceState(
        dayIdx: item.dayIdx,
        placeIdx: item.placeIdx,
        status: item.dayIdx == 0 && item.placeIdx == 0
            ? TripPlaceStatus.current
            : TripPlaceStatus.waiting,
      )).toList();

      setState(() { _states = initial; _loading = false; });
      await ActiveTripService()
          .saveProgress(widget.savedTrip.id, initial);
    }
  }

  void _completePlace(int dayIdx, int placeIdx) {
    setState(() {
      final idx = _states.indexWhere(
              (s) => s.dayIdx == dayIdx && s.placeIdx == placeIdx);
      if (idx != -1) _states[idx].status = TripPlaceStatus.completed;

      final all = _allPlaces;
      final flat = all.indexWhere(
              (a) => a.dayIdx == dayIdx && a.placeIdx == placeIdx);
      if (flat < all.length - 1) {
        final next = all[flat + 1];
        final ni = _states.indexWhere(
                (s) => s.dayIdx == next.dayIdx && s.placeIdx == next.placeIdx);
        if (ni != -1) _states[ni].status = TripPlaceStatus.current;
      }
    });

    ActiveTripService().saveProgress(widget.savedTrip.id, _states);

    //completionRate Firebase'e yaz
    if (_totalCount > 0) {
      final rate = _completedCount / _totalCount;
      RoutesService().updateCompletionRate(widget.savedTrip.id, rate);
    }
  }

  void _saveReview(int dayIdx, int placeIdx, int rating, String review) {
    setState(() {
      final idx = _states.indexWhere(
          (s) => s.dayIdx == dayIdx && s.placeIdx == placeIdx);
      if (idx != -1) {
        _states[idx].rating = rating;
        _states[idx].review = review;
      }
    });
    ActiveTripService().updateReview(
      widget.savedTrip.id, dayIdx, placeIdx,
      rating: rating, review: review,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF0FAFA),
        body: Center(
            child: CircularProgressIndicator(color: Color(0xFF00BFA5))),
      );
    }

    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(context),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildCurrentCard(),
                const SizedBox(height: 16),
                _buildMapSection(),
                const SizedBox(height: 20),
                _buildDayList(),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const bottomNav(selectedIndex: 1),
    ); 
  }

  // ── App Bar ──────────────────────────────────────────────────────────────
  SliverAppBar _buildAppBar(BuildContext context) {
    final progress =
        _totalCount > 0 ? _completedCount / _totalCount : 0.0;

    return SliverAppBar(
      pinned: true,
      expandedHeight: 130,
      backgroundColor: _teal,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 18),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_teal, _blue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 48, 20, 12),
              child: Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.emoji_events_rounded,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(widget.savedTrip.title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 3),
                      Text(
                          '$_completedCount / $_totalCount Mekan Tamamlandı',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
                // Yüzde + dikey bar
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('İlerleme',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 10)),
                    Text('%${(progress * 100).toInt()}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 20)),
                  ],
                ),
                const SizedBox(width: 8),
                Container(
                  width: 6, height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      height: 50 * progress,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  // ── Şu an kartı ──────────────────────────────────────────────────────────
  Widget _buildCurrentCard() {
    final current = _states
        .where((s) => s.status == TripPlaceStatus.current)
        .toList();

    if (current.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [_teal, _blue]),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Row(children: [
          Icon(Icons.check_circle_rounded, color: Colors.white, size: 26),
          SizedBox(width: 12),
          Expanded(
            child: Text('Tebrikler! Tüm mekanları tamamladınız 🎉',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15)),
          ),
        ]),
      );
    }

    final cp = current.first;
    final place =
        widget.tripResult.dayPlans[cp.dayIdx].places[cp.placeIdx];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF8C42), Color(0xFFFF6B35)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFFFF6B35).withOpacity(0.3),
              blurRadius: 14,
              offset: const Offset(0, 5)),
        ],
      ),
      child: Row(children: [
        Container(
          width: 46, height: 46,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.location_on_rounded,
              color: Colors.white, size: 26),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            const Text('Şimdi Neredesiniz?',
                style: TextStyle(color: Colors.white70, fontSize: 11)),
            Text(place.name,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800)),
            Text('${place.timeSlot} • ${place.duration}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          AudioGuideButton(
            placeName: place.name,
            city: widget.savedTrip.city,
            description: place.description,
            compact: true, // küçük buton modu
          ),
        ],
      ),
    );
  }

  // ── Harita ───────────────────────────────────────────────────────────────
  Widget _buildMapSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(children: [
          Icon(Icons.navigation_rounded, color: _teal, size: 18),
          SizedBox(width: 8),
          Text('Seyahat Rotanız',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _textDark)),
        ]),
        const SizedBox(height: 10),
        ActiveTripMap(
          dayPlans: widget.tripResult.dayPlans,
          states: _states,
        ),
      ],
    );
  }

  // ── Gün listesi ──────────────────────────────────────────────────────────
  Widget _buildDayList() {
    return Column(
      children: widget.tripResult.dayPlans.asMap().entries.map((e) {
        final dayIdx = e.key;
        final day = e.value;
        final dayColor = _dayColors[dayIdx % _dayColors.length];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gün başlığı
            Container(
              margin: const EdgeInsets.only(bottom: 12, top: 4),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: dayColor,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(color: dayColor.withOpacity(0.3),blurRadius: 10,offset: const Offset(0, 3)),
                ],
              ),
              child: Row(children: [
                const Icon(Icons.calendar_today_rounded,
                    color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text('Gün ${dayIdx + 1}',
                    style: const TextStyle(color: Colors.white,fontWeight: FontWeight.w800,fontSize: 15)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${day.places.length} Mekan',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500)),
                ),
              ]),
            ),
            // Mekan kartları
            ...day.places.asMap().entries.map((pe) {
              final placeIdx = pe.key;
              final place = pe.value;
              return ActivePlaceCard(
                place: place,
                number: placeIdx + 1,
                state: _stateOf(dayIdx, placeIdx),
                dayColor: dayColor,
                city: widget.savedTrip.city, // bunu ekle
                onComplete: () => _completePlace(dayIdx, placeIdx),
                onReview: (r, rev) => _saveReview(dayIdx, placeIdx, r, rev),
              );
            }),
            const SizedBox(height: 8),
          ],
        );
      }).toList(),
    );
  }
}