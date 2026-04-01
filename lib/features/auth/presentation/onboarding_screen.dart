import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

// ---------------------------------------------------------------------------
// Slide data
// ---------------------------------------------------------------------------
class _Slide {
  const _Slide({
    required this.image,
    required this.badge,
    required this.title,
    required this.subtitle,
  });

  final String image;
  final String badge;
  final String title;
  final String subtitle;
}

const _slides = [
  _Slide(
    image: 'assets/images/screen2.png',
    badge: '🛍  TRUSTED FIRST',
    title: 'Shop smarter with trusted local shoppers',
    subtitle:
        'Post your list once and get real-time updates until delivery reaches your door.',
  ),
  _Slide(
    image: 'assets/images/screen4.png',
    badge: '📊  LIVE TRACKING',
    title: 'Track every order at a glance',
    subtitle:
        'See status, approvals, and updates in one clean timeline while shopping is in progress.',
  ),
  _Slide(
    image: 'assets/images/screen1.png',
    badge: '₦  BARGAIN LIVE',
    title: 'Real-Time Negotiation',
    subtitle:
        'Bargain like you\'re there. Chat directly with your shoppers in real-time to negotiate prices and get the absolute best value for your money at any local market.',
  ),
  _Slide(
    image: 'assets/images/screen.png',
    badge: '✅  EASY RECEIVE',
    title: 'Chat, approve, and receive confidently',
    subtitle:
        'Coordinate details directly with your shopper and receive your order without stress.',
  ),
];

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.onLogin,
    required this.onRegister,
  });

  final VoidCallback onLogin;
  final VoidCallback onRegister;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextSlide() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOut,
      );
    } else {
      widget.onRegister();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final slide = _slides[_currentPage];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFC8E6C9), // mint green top-left
              Color(0xFFF5EDD8), // warm cream bottom-right
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                // ── Header ──────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'SwiftShopper',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    GestureDetector(
                      onTap: widget.onLogin,
                      child: Text(
                        'SKIP',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF888888),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // ── Slide image card ─────────────────────────────────────
                Expanded(
                  flex: 56,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _slides.length,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemBuilder: (context, index) =>
                        _SlideCard(slide: _slides[index]),
                  ),
                ),
                const SizedBox(height: 28),
                // ── Title ────────────────────────────────────────────────
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      slide.title,
                      key: ValueKey(slide.title),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        height: 1.3,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // ── Subtitle ─────────────────────────────────────────────
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    slide.subtitle,
                    key: ValueKey(slide.subtitle),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // ── Page indicators ──────────────────────────────────────
                Row(
                  children: List.generate(_slides.length, (i) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeOut,
                      margin: const EdgeInsets.only(right: 6),
                      height: 6,
                      width: _currentPage == i ? 36 : 18,
                      decoration: BoxDecoration(
                        color:
                            _currentPage == i
                                ? AppColors.primary
                                : const Color(0xFFCCCCCC),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 20),
                // ── Step counter + next button ───────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'STEP',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0,
                            fontSize: 11,
                          ),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              (_currentPage + 1).toString().padLeft(2, '0'),
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '/ ${_slides.length.toString().padLeft(2, '0')}',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _nextSlide,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Slide card with green glow shadow and badge
// ---------------------------------------------------------------------------
class _SlideCard extends StatelessWidget {
  const _SlideCard({required this.slide});

  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Green glow behind-left of card
        Positioned(
          left: -10,
          top: 12,
          bottom: 12,
          child: Container(
            width: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.25),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(28),
                bottomLeft: Radius.circular(28),
              ),
            ),
          ),
        ),
        // Main image card
        Container(
          margin: const EdgeInsets.only(left: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.15),
                blurRadius: 24,
                offset: const Offset(-6, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Image.asset(
              slide.image,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.accentSoft,
                child: const Center(
                  child: Icon(
                    Icons.image_rounded,
                    size: 60,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
        ),
        // Badge – bottom right of card
        Positioned(
          bottom: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFD4860A),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              slide.badge,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
