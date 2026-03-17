import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _controller,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            children: const [
              OnboardPage(
                image: "assets/images/onboarding1.jpg",
                title: "Plan Smarter Travel Better",
                subtitle:
                    "Your personal AI travel companion for discovering the best places.",
              ),
              OnboardPage(
                image: "assets/images/onboarding2.jpg",
                title: "AI Itinerary Generation",
                subtitle:
                    "Tell us your interests and duration. Our AI creates the perfect trip.",
              ),
              OnboardPage(
                image: "assets/images/onboarding3.jpg",
                title: "Smart Route Optimization",
                subtitle: "Routes optimized by distance, time and traffic.",
              ),
              OnboardPage(
                image: "assets/images/onboarding4.jpg",
                title: "Live Map Tracking",
                subtitle:
                    "Follow your journey in real time and discover nearby gems.",
              ),
            ],
          ),
          // Text logo — sol üst
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.only(top: 12, left: 16),
                child: Image.asset(
                  "assets/images/text_logo.png",
                  height: 125,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          // Skip — sağ üst
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 16),
                child: TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, "/login");
                  },
                  child: const Text("Skip"),
                ),
              ),
            ),
          ),
          // Alt kısım: buton, sign in metni, noktalar (yazıların üzerine gelmeyecek şekilde)
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Continue butonu — mavi, ilk sayfada "Explore World", diğerlerinde "Continue >"
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_currentPage == 3) {
                            Navigator.pushReplacementNamed(context, "/login");
                          } else {
                            _controller.nextPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _currentPage == 0 ? "Explore World" : "Continue >",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Already have account? Sign in. — altı çizgili, tıklanabilir
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacementNamed(context, "/login");
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        "Already have account? Sign in.",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.95),
                          fontSize: 14,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.white.withOpacity(0.95),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // 4 yuvarlak nokta — sayfanın en altında
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: SmoothPageIndicator(
                      controller: _controller,
                      count: 4,
                      effect: const ExpandingDotsEffect(
                        dotHeight: 8,
                        dotWidth: 8,
                        expansionFactor: 3,
                        spacing: 6,
                        dotColor: Colors.white38,
                        activeDotColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardPage extends StatelessWidget {
  final String image;
  final String title;
  final String subtitle;

  const OnboardPage({
    super.key,
    required this.image,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(image),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(25, 60, 25, 180),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.black.withOpacity(0.5),
              Colors.transparent,
              Colors.black.withOpacity(0.7),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
