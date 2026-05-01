import 'package:flutter/material.dart';
import '../trip_plan_model.dart';
import '../step_shell.dart';
import '../../trip_result/trip_result_screen.dart';

const _prefItems = [
  ('🏛️', 'Tarih ve Kültür'),
  ('🍽️', 'Yemek ve Lezzet'),
  ('🌿', 'Doğa ve Manzara'),
  ('🛍️', 'Alışveriş'),
  ('🎭', 'Gece Hayatı'),
  ('🏔️', 'Macera'),
];

const _budgets = [
  ('💰', 'Ekonomik', 'Hesaplı seçenekler', 'ekonomik'),
  ('💵', 'Orta', 'Dengeli bütçe', 'orta'),
  ('💎', 'Lüks', 'Premium deneyim', 'lüks'),
];

class Step3Preferences extends StatefulWidget {
  final TripPlanModel plan;
  final VoidCallback onBack;

  const Step3Preferences({super.key, required this.plan, required this.onBack});

  @override
  State<Step3Preferences> createState() => _Step3PreferencesState();
}

class _Step3PreferencesState extends State<Step3Preferences> {
  bool _loading = false;

  bool get _canGenerate =>
      widget.plan.preferences.isNotEmpty && widget.plan.budget.isNotEmpty;

  void _togglePref(String pref) {
    setState(() {
      if (widget.plan.preferences.contains(pref)) {
        widget.plan.preferences = List.from(widget.plan.preferences)..remove(pref);
      } else {
        widget.plan.preferences = List.from(widget.plan.preferences)..add(pref);
      }
    });
  }

  Future<void> _generate() async {
  setState(() => _loading = true);
  try {
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TripResultScreen(plan: widget.plan),
        ),
      );
    }
  } finally {
    if (mounted) setState(() => _loading = false);
  }
}

  @override
  Widget build(BuildContext context) {
    return StepShell(
      icon: Icons.favorite_rounded,
      title: 'Son birkaç\ntercih!',
      canGoNext: _canGenerate,
      onNext: _generate,
      isLastStep: true,
      isLoading: _loading,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Seyahat Tercihleriniz',
              style: TextStyle(color: Color(0xFF4A6060), fontSize: 13,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.1,
            children: _prefItems.map((item) {
              final sel = widget.plan.preferences.contains(item.$2);
              return GestureDetector(
                onTap: () => _togglePref(item.$2),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color: sel ? const Color(0xFF00BFA5) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: sel ? const Color(0xFF00BFA5) : const Color(0xFFCCE8E5)),
                    boxShadow: sel
                        ? [BoxShadow(color: const Color(0xFF00BFA5).withOpacity(0.25),
                            blurRadius: 8, offset: const Offset(0, 3))]
                        : [],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(item.$1, style: const TextStyle(fontSize: 26)),
                      const SizedBox(height: 6),
                      Text(item.$2,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: sel ? Colors.white : const Color(0xFF4A6060),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          )),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          const Text('Bütçe Tercihiniz',
              style: TextStyle(color: Color(0xFF4A6060), fontSize: 13,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ..._budgets.map((b) {
            final sel = widget.plan.budget == b.$4;
            return GestureDetector(
              onTap: () => setState(() => widget.plan.budget = b.$4),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: sel ? const Color(0xFF00BFA5) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: sel ? const Color(0xFF00BFA5) : const Color(0xFFCCE8E5)),
                  boxShadow: sel
                      ? [BoxShadow(color: const Color(0xFF00BFA5).withOpacity(0.2),
                          blurRadius: 8, offset: const Offset(0, 3))]
                      : [],
                ),
                child: Row(
                  children: [
                    Text(b.$1, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 14),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(b.$2,
                          style: TextStyle(
                            color: sel ? Colors.white : const Color(0xFF1A2E2E),
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          )),
                      Text(b.$3,
                          style: TextStyle(
                            color: sel ? Colors.white70 : const Color(0xFF8AABAB),
                            fontSize: 12,
                          )),
                    ]),
                    const Spacer(),
                    if (sel)
                      const Icon(Icons.check_circle_rounded,
                          color: Colors.white, size: 20),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}