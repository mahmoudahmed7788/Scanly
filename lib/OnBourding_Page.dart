import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();

  int _currentPage = 0;

  final List<OnboardingData> _pages = const [
    OnboardingData(
      image: 'assets/images/OnBoarding_1.png',
      title: 'Scan Anything',
      description:
          'Turn your documents and images into digital files quickly and easily.',
    ),
    OnboardingData(
      image: 'assets/images/OnBoarding_2.png',
      title: 'Save & Organize',
      description:
          'Keep your scanned documents organized and easy to access anytime.',
    ),
    OnboardingData(
      image: 'assets/images/OnBoarding_3.png',
      title: 'Powerful Tools',
      description:
          'Scan documents, create PDFs, manage QR codes and more in one place.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // =========================
  // COMPLETE ONBOARDING
  // =========================

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('onboardingCompleted', true);

    if (!mounted) return;

    context.go('/home');
  }

  // =========================
  // NEXT PAGE
  // =========================

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  // =========================
  // SKIP
  // =========================

  void _skip() {
    _completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // =========================
            // TOP GRADIENT HEADER
            // =========================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 20, 20, 25),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppThemeColors.primary, AppThemeColors.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(35),
                  bottomRight: Radius.circular(35),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Scanly',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: _skip,
                    child: const Text(
                      'Skip',
                      style: TextStyle(color: Colors.white70, fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),

            // =========================
            // PAGES
            // =========================
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final page = _pages[index];

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),

                        Expanded(
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  colors.primary.withOpacity(0.08),
                                  colors.secondary.withOpacity(0.04),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.all(18),
                            child: Image.asset(page.image, fit: BoxFit.contain),
                          ),
                        ),

                        const SizedBox(height: 25),

                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: colors.onSurface,
                            fontSize: 29,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 12),

                        Text(
                          page.description,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: colors.onSurface.withOpacity(0.58),
                            fontSize: 15,
                            height: 1.6,
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  );
                },
              ),
            ),

            // =========================
            // INDICATORS
            // =========================
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (index) {
                final active = index == _currentPage;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 28 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: active
                        ? const LinearGradient(
                            colors: [
                              AppThemeColors.primary,
                              AppThemeColors.accent,
                            ],
                          )
                        : null,
                    color: active ? null : colors.onSurface.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                );
              }),
            ),

            const SizedBox(height: 22),

            // =========================
            // NEXT / GET STARTED BUTTON
            // =========================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppThemeColors.primary, AppThemeColors.secondary],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(
                      _currentPage == _pages.length - 1
                          ? 'Get Started'
                          : 'Next',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 22),
          ],
        ),
      ),
    );
  }
}

// =========================
// ONBOARDING DATA
// =========================

class OnboardingData {
  final String image;
  final String title;
  final String description;

  const OnboardingData({
    required this.image,
    required this.title,
    required this.description,
  });
}

// =========================
// APP THEME COLORS
// =========================

class AppThemeColors {
  static const Color primary = Color(0xFF5B5FEF);

  static const Color secondary = Color(0xFF7C5CFC);

  static const Color accent = Color(0xFF00C2FF);
}
