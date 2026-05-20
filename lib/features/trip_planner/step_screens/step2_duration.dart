// lib/features/trip_planner/steps/step2_duration.dart

import 'package:flutter/material.dart';
import '../trip_plan_model.dart';
import '../step_shell.dart';

class Step2Duration extends StatefulWidget {
  final TripPlanModel plan;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const Step2Duration({
    super.key, required this.plan,
    required this.onNext, required this.onBack,
  });

  @override
  State<Step2Duration> createState() => _Step2DurationState();
}

class _Step2DurationState extends State<Step2Duration> {
  final _quickPicks = [1, 2, 3, 4, 5, 7, 10, 14];

  @override
  Widget build(BuildContext context) {
    final days = widget.plan.days;

    return StepShell(
      icon: Icons.calendar_month_rounded,
      title: 'How many days \nare you planning your trip?',
      canGoNext: true,
      onNext: widget.onNext,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: const Color(0xFF00BFA5).withOpacity(0.1),
                    blurRadius: 16, offset: const Offset(0, 4))
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$days',
                      style: const TextStyle(
                        fontSize: 72,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF00BFA5),
                        height: 1,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12, left: 6),
                      child: Text('day',
                          style: TextStyle(fontSize: 20, color: Color(0xFF4A6060),
                              fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _durationLabel(days),
                  style: const TextStyle(color: Color(0xFF8AABAB), fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // +/- kontrol
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _circleBtn(Icons.remove_rounded, () {
                if (days > 1) setState(() => widget.plan.days--);
              }),
              const SizedBox(width: 24),
              SizedBox(
                width: 80,
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xFF00BFA5),
                    inactiveTrackColor: const Color(0xFFCCE8E5),
                    thumbColor: const Color(0xFF00BFA5),
                    overlayColor: const Color(0xFF00BFA5).withOpacity(0.15),
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                  ),
                  child: Slider(
                    value: days.toDouble(),
                    min: 1, max: 14,
                    onChanged: (v) => setState(() => widget.plan.days = v.round()),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              _circleBtn(Icons.add_rounded, () {
                if (days < 14) setState(() => widget.plan.days++);
              }),
            ],
          ),
          const SizedBox(height: 20),

          // Hızlı seçim çipleri
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Quick Selection',
                style: TextStyle(color: Color(0xFF4A6060), fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickPicks.map((d) {
              final sel = widget.plan.days == d;
              return GestureDetector(
                onTap: () => setState(() => widget.plan.days = d),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: sel ? const Color(0xFF00BFA5) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: sel ? const Color(0xFF00BFA5) : const Color(0xFFCCE8E5)),
                  ),
                  child: Text('$d day',
                      style: TextStyle(
                        color: sel ? Colors.white : const Color(0xFF4A6060),
                        fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                        fontSize: 13,
                      )),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF00BFA5).withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF00BFA5), size: 22),
        ),
      );

  String _durationLabel(int d) {
    if (d == 1) return 'A day trip';
    if (d <= 3) return 'Short holiday';
    if (d <= 7) return 'Week trip';
    return 'Long holiday';
  }
}