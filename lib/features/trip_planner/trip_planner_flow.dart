import 'package:flutter/material.dart';
import 'trip_plan_model.dart';
import 'step_screens/step1_destination.dart';
import 'step_screens/step2_duration.dart';
import 'step_screens/step3_preferences.dart';

class TripPlannerFlow extends StatefulWidget {
  const TripPlannerFlow({super.key});
  @override
  State<TripPlannerFlow> createState() => _TripPlannerFlowState();
}

class _TripPlannerFlowState extends State<TripPlannerFlow> {
  int _step = 0; // 0, 1, 2
  final _plan = TripPlanModel();

  void _next() {
    if (_step < 2) setState(() => _step++);
  }

  void _back() {
    if (_step > 0) {
      setState(() => _step--);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps = [
      Step1Destination(plan: _plan, onNext: _next),
      Step2Duration(plan: _plan, onNext: _next, onBack: _back),
      Step3Preferences(plan: _plan, onBack: _back),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: _back,
          child: const Row(
            children: [
              SizedBox(width: 16),
              Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF4A6060), size: 18),
              SizedBox(width: 4),
              Text('Back', style: TextStyle(color: Color(0xFF4A6060), fontSize: 14)),
            ],
          ),
        ),
        leadingWidth: 120,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(36),
          child: _StepIndicator(currentStep: _step, totalSteps: 3),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, anim) =>
            FadeTransition(opacity: anim, child: child),
        child: KeyedSubtree(key: ValueKey(_step), child: steps[_step]),
      ),
    );
  }
}

// tepedki göstrge
class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const _StepIndicator({required this.currentStep, required this.totalSteps});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      child: Row(
        children: List.generate(totalSteps * 2 - 1, (i) {
          if (i.isOdd) {
            // Çizgi
            final filled = currentStep > i ~/ 2;
            return Expanded(
              child: Container(
                height: 2,
                color: filled ? const Color(0xFF00BFA5) : const Color(0xFFCCE8E5),
              ),
            );
          }
          // Daire
          final stepIdx = i ~/ 2;
          final isActive = stepIdx == currentStep;
          final isDone = stepIdx < currentStep;
          return Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (isActive || isDone) ? const Color(0xFF00BFA5) : Colors.white,
              border: Border.all(
                color: (isActive || isDone) ? const Color(0xFF00BFA5) : const Color(0xFFCCE8E5),
                width: 2,
              ),
            ),
            child: Center(
              child: isDone
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                  : Text('${stepIdx + 1}',
                      style: TextStyle(
                        color: isActive ? Colors.white : const Color(0xFF8AABAB),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      )),
            ),
          );
        }),
      ),
    );
  }
}