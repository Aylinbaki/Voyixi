import 'package:flutter/material.dart';
import 'trip_planner_flow.dart';

class TripPlannerEntry extends StatelessWidget {
  const TripPlannerEntry({super.key});

  @override
  Widget build(BuildContext context) {
  return Scaffold(
    body: Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF0FAFA), Color(0xFDFCF0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea( 
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start, 
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12), 
                      child: Row(
                        children: [
                          Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF4A6060), size: 18),
                          SizedBox(width: 4),
                          Text('Home', style: TextStyle(color: Color(0xFF4A6060), fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                  Image.asset(
                    "assets/images/app_logo_plan.png",
                    height: 70, 
                    fit: BoxFit.contain,
                  ),
                ],
              ),
              const SizedBox(height: 30), 
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFF00BFA5).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, color: Color(0xFF00BFA5), size: 15),
                    SizedBox(width: 6),
                    Text(
                      'AI-powered smart travel planner',
                      style: TextStyle(color: Color(0xFF00897B), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
                const SizedBox(height: 20),
                RichText(
                  textAlign: TextAlign.center,
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 36,fontWeight: FontWeight.w800,height: 1.2,
                    ),
                    children: [
                      TextSpan(
                        text: 'Plan Your\n',style: TextStyle(color: Color(0xFF1A2E2E)),
                      ),
                      TextSpan(
                        text: 'Dream ',style: TextStyle(color: Color(0xFF1A2E2E)),
                      ),
                      TextSpan(
                        text: 'Trip',style: TextStyle(color: Color(0xFF00BFA5)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Create personalized day-by-day travel itineraries to suit your preferences and budget with our AI-powered planner.',
                  style: TextStyle(color: Color(0xFF4A6060),fontSize: 15,height: 1.6,
                  ),
                ),
                const SizedBox(height: 36),
                ...[
                  (Icons.location_on_outlined, 'Personalized Routes'),
                  (Icons.public_rounded, 'Worldwide Destinations'),
                  (Icons.auto_awesome_rounded, 'AI Suggestions'),
                ].map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            item.$1, color: const Color(0xFF00BFA5), size: 18,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            item.$2,
                            style: const TextStyle(
                              color: Color(0xFF1A2E2E),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Spacer(flex: 3),
                _AnimatedButton(
                  label: 'Start your journey',
                  icon: Icons.rocket_launch_rounded,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TripPlannerFlow()),
                  ),
                ),
                const SizedBox(height: 12),
                const Center(
                  child: Text(
                    'Start now, create your plan in minute',
                    style: TextStyle(color: Color(0xFF8AABAB), fontSize: 12),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Animasyonlu buton
class _AnimatedButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _AnimatedButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: const [
                Color(0xFF00BFA5),Color(0xFF4DD0C4),Color(0xFF00897B),
              ],
              stops: [
                (_ctrl.value - 0.5).clamp(0.0, 1.0),
                _ctrl.value.clamp(0.0, 1.0),
                (_ctrl.value + 0.5).clamp(0.0, 1.0),
              ],
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00BFA5).withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
