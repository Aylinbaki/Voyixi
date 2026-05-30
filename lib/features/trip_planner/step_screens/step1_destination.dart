import 'package:flutter/material.dart';
import '../trip_plan_model.dart';
import '../step_shell.dart';

const _popularCities = [
  'Istanbul', 'Paris', 'Rome', 'Barcelona', 'Amsterdam',
'Prague', 'Vienna', 'Budapest', 'Athens', 'Lisbon', 'Berlin', 'London',
];

class Step1Destination extends StatefulWidget {
  final TripPlanModel plan;
  final VoidCallback onNext;

  const Step1Destination({super.key, required this.plan, required this.onNext});

  @override
  State<Step1Destination> createState() => _Step1DestinationState();
}

class _Step1DestinationState extends State<Step1Destination> {
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ctrl.text = widget.plan.city;
    _ctrl.addListener(() => setState(() => widget.plan.city = _ctrl.text.trim()));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _select(String city) {
    _ctrl.text = city;
    widget.plan.city = city;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return StepShell(
      icon: Icons.location_on_rounded,
      title: 'Where do you want to go?',
      canGoNext: widget.plan.city.isNotEmpty,
      onNext: widget.onNext,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Arama boxu
          TextField(
            controller: _ctrl,
            decoration: InputDecoration(
              hintText: 'Write the city name....',
              hintStyle: const TextStyle(color: Color(0xFF8AABAB)),
              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF00BFA5)),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFCCE8E5)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFCCE8E5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF00BFA5), width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Popular Cities',
              style: TextStyle(color: Color(0xFF4A6060), fontSize: 13,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _popularCities.map((city) {
              final selected = widget.plan.city == city;
              return GestureDetector(
                onTap: () => _select(city),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFF00BFA5) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? const Color(0xFF00BFA5) : const Color(0xFFCCE8E5),
                    ),
                  ),
                  child: Text(city,
                      style: TextStyle(
                        color: selected ? Colors.white : const Color(0xFF4A6060),
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
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
}