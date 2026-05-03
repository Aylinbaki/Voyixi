import 'package:flutter/material.dart';
import '../trip_planner/trip_plan_model.dart';
import 'trip_result_model.dart';
import 'gemini_service.dart';
import 'widgets/day_section.dart';
import 'widgets/trip_map.dart';
import '../routes/routes_widget.dart';
import '../routes/routes_service.dart';
import '../active_trip/active_trip_screen.dart';
import '../routes/routes_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/user_service.dart';

class TripResultScreen extends StatefulWidget {
  final TripPlanModel plan;
  final TripResult? result;
  const TripResultScreen({super.key, required this.plan,this.result,});

  @override
  State<TripResultScreen> createState() => _TripResultScreenState();
}

class _TripResultScreenState extends State<TripResultScreen> {
  final _mapKey = GlobalKey<TripMapState>();
  TripResult? _result;
  String _error = '';
  bool _loading = true;
  int _visibleDays = 0;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  Future<void> _generate() async {
    setState(() {
      _loading = true;
      _error = '';
      _result = null;
      _visibleDays = 0;
    });
    try {
      final result = await GeminiService().generateTripPlan(widget.plan);
      if (!mounted) return;
      setState(() {
        _result = result;
        _loading = false;
      });
      for (int i = 0; i < result.dayPlans.length; i++) {
        await Future.delayed(const Duration(milliseconds: 250));
        if (mounted) setState(() => _visibleDays = i + 1);
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  // Sessiz kayıt — hata olursa görmezden gel
  Future<void> _saveQuietly() async {
    if (_result == null) return;
    try {
      await RoutesService().saveTrip(
        result: _result!,
        title: '${_result!.city} Seyahati',
        tripDate: DateTime.now(),
      );
    } catch (_) {}
  }

  Future<void> _savePlan() async {
    if (_result == null) return; //gemini'dan gelen rota var mı
    try {
      // 1. Mevcut trip kaydetme — değişmedi
      await RoutesService().saveTrip(
        result: _result!,
        title: '${_result!.city} Seyahati',
        tripDate: DateTime.now(),
      );

      // 2. Profil istatistiklerini güncelle
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        // Müze sayısını place isimlerinden bul
        final museumCount = _result!.dayPlans
            .expand((d) => d.places)
            .where((p) =>
        p.name.toLowerCase().contains('müze') ||
            p.name.toLowerCase().contains('museum'))
            .length;

        await UserService().incrementStats(
          uid: uid,
          distanceKm: _result!.totalDistanceKm,
          city: _result!.city,
          country: _result!.country,
          museumCount: museumCount,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Plan kaydedildi! ✅'),
            backgroundColor: Color(0xFF00BFA5),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kayıt hatası: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FAFA),
      body: _loading
          ? _buildLoading()
          : _error.isNotEmpty
          ? _buildError()
          : _buildContent(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBottomBar() {
    if (_loading || _error.isNotEmpty) return const SizedBox.shrink();
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _savePlan,
              icon: const Icon(Icons.bookmark_rounded, size: 18),
              label: const Text('Planı Kaydet'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF00BFA5),
                side: const BorderSide(color: Color(0xFF00BFA5)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              // Geziye Başla onPressed:
              onPressed: () async {
                await _savePlan();

                final id = await showModalBottomSheet<String>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => RoutesWidget(result: _result!),
                );

                if (id != null && mounted) {
                  final trips = await RoutesService().getTrips().first;
                  final saved = trips.firstWhere((t) => t.id == id);
                  if (mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ActiveTripScreen(
                          savedTrip: saved,
                          tripResult: _result!,
                        ),
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.explore_rounded, size: 18),
              label: const Text('Geziye Başla'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00BFA5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Yükleniyor görünümü
 Widget _buildLoading() {
  return Container(
    width: double.infinity,
    height: double.infinity,
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF00BFA5), Color(0xFF0077B6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.auto_awesome_rounded,
              color: Colors.white, size: 56),
          const SizedBox(height: 24),
          Text(
            'VOYİXİ ile ${widget.plan.city} planınız\nhazırlanıyor...',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.plan.days} gün • ${widget.plan.budget}',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 40),
          const CircularProgressIndicator(
              color: Colors.white, strokeWidth: 3),
        ],
      ),
    ),
  );
}
  // ── Hata 
  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Color(0xFF00BFA5), size: 56),
            const SizedBox(height: 16),
            const Text('Plan oluşturulamadı',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(_error,
                style: const TextStyle(color: Color(0xFF6B8C8C), fontSize: 12),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _generate,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tekrar Dene'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00BFA5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Ana içerik 
  Widget _buildContent() {
    final r = _result!;
    return CustomScrollView(
      
      slivers: [
        SliverAppBar(
          expandedHeight: 160,
          pinned: true,
          backgroundColor: const Color(0xFF0077B6),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF00BFA5), Color(0xFF0077B6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.auto_awesome_rounded,
                            color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${r.city} Seyahat Planınız',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${r.days} Gün • ${_budgetLabel(r.budget)}',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      // Yeniden Planla
                      GestureDetector(
                        onTap: _generate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(children: [
                            Icon(Icons.refresh_rounded,
                                color: Colors.white, size: 16),
                            SizedBox(width: 6),
                            Text('Yeniden\nPlanla',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 10),
                  child: Text(
                    'Seyahat Rotanız',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A2E2E),
                    ),
                  ),
                ),
                TripMap(
                  key: _mapKey, 
                  dayPlans: r.dayPlans,
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) {
                if (i >= _visibleDays) return const SizedBox.shrink();
                return AnimatedOpacity(
                  opacity: i < _visibleDays ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 400),
                  child: AnimatedSlide(
                    offset: i < _visibleDays ? Offset.zero : const Offset(0, 0.1),
                    duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                  child: DaySection(
                    dayPlan: r.dayPlans[i],
                    city: r.city,
                    budget: r.budget,
                    startExpanded: i == 0,
                    onPlaceChanged: () => _mapKey.currentState?.refreshMap(),
                  ),
                ),
              );
            },
              childCount: r.dayPlans.length,
            ),
          ),
        ),

        // Alt boşluk (butonlar için)
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }

  String _budgetLabel(String b) => switch (b) {
        'ekonomik' => 'Ekonomik Bütçe',
        'lüks' => 'Lüks Bütçe',
        _ => 'Orta Bütçe',
      };
}