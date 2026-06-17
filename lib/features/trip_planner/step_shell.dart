import 'package:flutter/material.dart';

class StepShell extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  final bool canGoNext;
  final VoidCallback onNext;
  final bool isLastStep;
  final bool isLoading;
  final Color cardColor;  //color

  const StepShell({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    required this.canGoNext,
    required this.onNext,
    this.isLastStep = false,
    this.isLoading = false,
    this.cardColor = Colors.white, //color
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Kart
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: cardColor, //değiş
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // İkon
                      Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00BFA5),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(icon, color: Colors.white, size: 26),
                      ),
                      const SizedBox(height: 16),
                      // Başlık
                      Text(title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A2E2E),
                            height: 1.3,
                          )),
                      const SizedBox(height: 22),
                      child,
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Alt buton
        Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20,
              MediaQuery.of(context).padding.bottom + 16),
          child: _NextButton(
            canGoNext: canGoNext && !isLoading,
            isLastStep: isLastStep,
            isLoading: isLoading,
            onTap: onNext,
          ),
        ),
      ],
    );
  }
}

class _NextButton extends StatefulWidget {
  final bool canGoNext;
  final bool isLastStep;
  final bool isLoading;
  final VoidCallback onTap;

  const _NextButton({
    required this.canGoNext,
    required this.isLastStep,
    required this.isLoading,
    required this.onTap,
  });

  @override
  State<_NextButton> createState() => _NextButtonState();
}

class _NextButtonState extends State<_NextButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.canGoNext ? widget.onTap : null,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          return Container(
            width: double.infinity,
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: widget.canGoNext
                  ? LinearGradient(
                      colors: const [
                        Color(0xFF00BFA5),
                        Color(0xFF4DD0C4),
                        Color(0xFF00897B),
                      ],
                      stops: [
                        (_ctrl.value - 0.5).clamp(0.0, 1.0),
                        _ctrl.value.clamp(0.0, 1.0),
                        (_ctrl.value + 0.5).clamp(0.0, 1.0),
                      ],
                      end: Alignment.centerRight, //begin
                      begin: Alignment.centerLeft, // end
                    )
                  : const LinearGradient(
                      colors: [Color(0xFFCCE8E5), Color(0xFFCCE8E5)]),
              boxShadow: widget.canGoNext
                  ? [BoxShadow(
                      color: const Color(0xFF00BFA5).withOpacity(0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 5))]
                  : [],
            ),
            child: Center(
              child: widget.isLoading
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.isLastStep)
                          const Icon(Icons.auto_awesome_rounded,
                              color: Colors.white, size: 18),
                        if (!widget.isLastStep)
                          const Icon(Icons.arrow_forward_rounded,
                              color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          widget.isLastStep ? 'Create Plan': 'Next',
                          style: TextStyle(
                            color: widget.canGoNext ? Colors.white : const Color(0xFF8AABAB),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }
}