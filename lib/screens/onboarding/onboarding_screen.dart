import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final List<_OnboardingData> _pages = [
    _OnboardingData(
      icon: Icons.photo_library_rounded,
      iconBg: [Color(0xFF8E0000), Color(0xFFC62828)],
      illustrationColors: [
        [Color(0xFFE53935), Color(0xFFB71C1C)],
        [Color(0xFFFF7043), Color(0xFFBF360C)],
        [Color(0xFFF06292), Color(0xFFAD1457)],
      ],
      title: 'Showcase Your\nPortfolio',
      subtitle:
          'Build a stunning visual profile that acts as your digital business card — no compression, no limits.',
      badge: 'Visual-First',
    ),
    _OnboardingData(
      icon: Icons.calendar_today_rounded,
      iconBg: [Color(0xFF6B0000), Color(0xFFC62828)],
      illustrationColors: [
        [Color(0xFFC62828), Color(0xFF8E0000)],
        [Color(0xFFE91E63), Color(0xFF880E4F)],
        [Color(0xFFFF5722), Color(0xFFBF360C)],
      ],
      title: 'Get Booked\nEffortlessly',
      subtitle:
          'Let clients view your real-time availability and book sessions directly — zero back-and-forth.',
      badge: 'Smart Booking',
    ),
    _OnboardingData(
      icon: Icons.people_rounded,
      iconBg: [Color(0xFF8E0000), Color(0xFFD32F2F)],
      illustrationColors: [
        [Color(0xFFD32F2F), Color(0xFF7F0000)],
        [Color(0xFFFF6F00), Color(0xFFE65100)],
        [Color(0xFFAD1457), Color(0xFF560027)],
      ],
      title: 'Connect &\nGrow Globally',
      subtitle:
          'Chat securely with clients, build your reputation with verified reviews, and grow worldwide.',
      badge: 'Global Reach',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _goToLogin();
    }
  }

  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F5),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Page view
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _OnboardingPage(
                    data: _pages[index],
                    screenSize: size,
                  );
                },
              ),
            ),
            // Bottom section
            Container(
              padding: const EdgeInsets.fromLTRB(28, 20, 28, 40),
              color: Colors.white,
              child: Column(
                children: [
                  // Page indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == i ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == i
                              ? const Color(0xFFC62828)
                              : const Color(0xFFE0E0E0),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Buttons
                  Row(
                    children: [
                      if (_currentPage < _pages.length - 1)
                        Expanded(
                          child: TextButton(
                            onPressed: _goToLogin,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(
                              'Skip',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF9E9E9E),
                              ),
                            ),
                          ),
                        ),
                      if (_currentPage < _pages.length - 1)
                        const SizedBox(width: 12),
                      Expanded(
                        flex: _currentPage < _pages.length - 1 ? 2 : 1,
                        child: ElevatedButton(
                          onPressed: _nextPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFC62828),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _currentPage == _pages.length - 1
                                    ? 'Get Started'
                                    : 'Next',
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                _currentPage == _pages.length - 1
                                    ? Icons.arrow_forward_rounded
                                    : Icons.arrow_forward_ios_rounded,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.data, required this.screenSize});

  final _OnboardingData data;
  final Size screenSize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 60, 28, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Illustration
          Expanded(
            child: Center(
              child: _Illustration(
                colors: data.illustrationColors,
                icon: data.icon,
                iconBg: data.iconBg,
              ),
            ),
          ),
          const SizedBox(height: 32),
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              data.badge,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFC62828),
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Title
          Text(
            data.title,
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A1A),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          // Subtitle
          Text(
            data.subtitle,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF7A7A7A),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _Illustration extends StatelessWidget {
  const _Illustration({
    required this.colors,
    required this.icon,
    required this.iconBg,
  });

  final List<List<Color>> colors;
  final IconData icon;
  final List<Color> iconBg;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 260,
      child: Stack(
        children: [
          // Background cards (rotated)
          Positioned(
            top: 20,
            left: 10,
            child: Transform.rotate(
              angle: -0.12,
              child: _PhotoCard(colors: colors[0], width: 140, height: 110),
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: Transform.rotate(
              angle: 0.10,
              child: _PhotoCard(colors: colors[1], width: 120, height: 100),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 40,
            right: 40,
            child: _PhotoCard(colors: colors[2], width: 160, height: 120),
          ),
          // Center icon
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: iconBg,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFC62828).withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 38),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoCard extends StatelessWidget {
  const _PhotoCard({
    required this.colors,
    required this.width,
    required this.height,
  });

  final List<Color> colors;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors[0].withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.photo_camera_rounded,
          color: Colors.white.withValues(alpha: 0.4),
          size: 30,
        ),
      ),
    );
  }
}

class _OnboardingData {
  final IconData icon;
  final List<Color> iconBg;
  final List<List<Color>> illustrationColors;
  final String title;
  final String subtitle;
  final String badge;

  const _OnboardingData({
    required this.icon,
    required this.iconBg,
    required this.illustrationColors,
    required this.title,
    required this.subtitle,
    required this.badge,
  });
}
