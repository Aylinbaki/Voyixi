import 'package:flutter/material.dart';
import '../trip_result_model.dart';
import '../gemini_service.dart';
import 'place_card.dart';
const _dayColors = [
  Color(0xFF00BFA5),
  Color(0xFF5B8DEF),
  Color(0xFF9C6FDE),
  Color(0xFFEF6C8D),
  Color(0xFF43A047),
  Color(0xFFF9A825),
  Color(0xFF00ACC1),
];

class DaySection extends StatefulWidget {
  final DayPlan dayPlan;
  final String city;
  final String budget;
  final bool startExpanded;
  final VoidCallback? onPlaceChanged;

  const DaySection({
    super.key,
    required this.dayPlan,
    required this.city,
    required this.budget,
    this.startExpanded = false,
    this.onPlaceChanged,
  });

  @override
  State<DaySection> createState() => _DaySectionState();
}

class _DaySectionState extends State<DaySection>
    with SingleTickerProviderStateMixin {
  late bool _expanded;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  Color get _color =>
      _dayColors[(widget.dayPlan.dayNumber - 1) % _dayColors.length];

  @override
  void initState() {
    super.initState();
    _expanded = widget.startExpanded;
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: _expanded ? 1.0 : 0.0,
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _animCtrl.forward() : _animCtrl.reverse();
  }

  Future<void> _replacePlace(int idx) async {
    final excludeNames =
        widget.dayPlan.places.map((p) => p.name).toList();
    final current = widget.dayPlan.places[idx];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF00BFA5)),
      ),
    );

    try {
      final alt = await GeminiService().getAlternativePlace(
        city: widget.city,
        timeSlot: current.timeSlot,
        budget: widget.budget,
        excludeNames: excludeNames,
      );
      if (mounted) {
        Navigator.pop(context);
        setState(() => widget.dayPlan.places[idx] = alt);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
    widget.onPlaceChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _toggle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: _color,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: _color.withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Row(children: [
              const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Text('Day ${widget.dayPlan.dayNumber}',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${widget.dayPlan.places.length} Place',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
              const Spacer(),
              AnimatedRotation(
                turns: _expanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 300),
                child: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: Colors.white, size: 22),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        SizeTransition(
          sizeFactor: _fadeAnim,
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              children: List.generate(widget.dayPlan.places.length, (i) {
                return PlaceCard(
                  key: ValueKey(widget.dayPlan.places[i].name),
                  place: widget.dayPlan.places[i],
                  index: i + 1,
                  dayColor: _color,
                  city: widget.city,
                  budget: widget.budget,
                  onDelete: () =>
                      setState(() => widget.dayPlan.places.removeAt(i)),
                  onReplace: () => _replacePlace(i),
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}