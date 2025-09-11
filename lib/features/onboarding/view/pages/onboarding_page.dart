import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:quickhire/core/theme/color_palette.dart';
import 'package:quickhire/core/views/widgets/custom_button.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<String> _titles = [
    'Find flexible jobs',
    'Trustworthy and ready',
    'No hidden fees',
    'Simple. Fast. Reliable.',
  ];

  final List<String> _descriptions = [
    "Find jobs that fit your needs.\nYour terms. Your schedule. Your way.",
    "Connect with trusted employers who are\nlooking for your unique skills.",
    "Transparent payment system with\nno surprise charges or commissions.",
    "Apply with a single tap and start\nworking right away.",
  ];

  void _nextPage() {
    if (_currentPage < _titles.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      context.go('/login');
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isLastPage = _currentPage == _titles.length - 1;

    return Scaffold(
      backgroundColor: Palette.background,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 360,
                width: 280,
                child: PageView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _titles.length,
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemBuilder: (context, index) {
                    return Lottie.asset(
                      'assets/animations/onboarding${index + 1}.json',
                      height: MediaQuery.of(context).size.height,
                      width: MediaQuery.of(context).size.width,
                    );
                  },
                ),
              ),
              Text(
                _titles[_currentPage],
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Palette.secondary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _descriptions[_currentPage],
                style: const TextStyle(fontSize: 16, color: Palette.subtitle),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              SmoothPageIndicator(
                controller: _pageController,
                count: _titles.length,
                effect: WormEffect(
                  dotWidth: 9.0,
                  dotHeight: 9.0,
                  spacing: 10,
                  activeDotColor: Palette.primary,
                  dotColor: const Color.fromARGB(255, 206, 230, 255),
                ),
              ),
              const SizedBox(height: 60),
              CustomButton(
                text: isLastPage ? "GET STARTED" : "NEXT",
                onPressed: _nextPage,
              ),
              if (!isLastPage)
                CustomButton(
                  text: "Skip",
                  onPressed: () {
                    _pageController.animateToPage(
                      _titles.length - 1,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  backgroundColor: Palette.transparent,
                  foregroundColor: Palette.subtitle,
                  transparent: true,
                )
              else
                const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }
}
