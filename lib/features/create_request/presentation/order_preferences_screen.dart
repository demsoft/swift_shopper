import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../providers/create_request_provider.dart';
import 'create_request_screen.dart';

class OrderPreferencesScreen extends ConsumerStatefulWidget {
  const OrderPreferencesScreen({super.key});

  @override
  ConsumerState<OrderPreferencesScreen> createState() =>
      _OrderPreferencesScreenState();
}

class _OrderPreferencesScreenState
    extends ConsumerState<OrderPreferencesScreen> {
  bool _isFixed = true;

  void _continue() {
    ref.read(createRequestProvider.notifier).toggleFlexible(!_isFixed);
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const CreateRequestScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2EF),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Order Preferences',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 22),
                ],
              ),
            ),

            // ── Body ─────────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Choose how you want\nyour order handled',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF202123),
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Fixed Price card
                    _ModeCard(
                      isSelected: _isFixed,
                      onTap: () => setState(() => _isFixed = true),
                      iconBg: const Color(0xFFDDEFE2),
                      icon: Icons.shield_rounded,
                      iconColor: AppColors.primary,
                      title: 'Fixed Price Mode',
                      badge: 'PREMIUM',
                      badgeColor: const Color(0xFFE08000),
                      description:
                          'Get a final price upfront. Pay once and we handle everything.',
                      features: const [
                        'No price changes',
                        'No calls or approvals',
                        'Stress-free experience',
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Flexible card
                    _ModeCard(
                      isSelected: !_isFixed,
                      onTap: () => setState(() => _isFixed = false),
                      iconBg: const Color(0xFFE4E6E2),
                      icon: Icons.tune_rounded,
                      iconColor: const Color(0xFF5A5C56),
                      title: 'Flexible Mode',
                      badge: null,
                      badgeColor: null,
                      description:
                          'Approve prices in real-time and stay within your budget.',
                      features: const [
                        'Live updates from shopper',
                        'Approve or reject items',
                        'Better price control',
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Info note
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.06),
                            end: Offset.zero,
                          ).animate(anim),
                          child: child,
                        ),
                      ),
                      child: _InfoNote(
                        key: ValueKey(_isFixed),
                        isFixed: _isFixed,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Continue button ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: GestureDetector(
                onTap: _continue,
                child: Container(
                  height: 58,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(29),
                  ),
                  alignment: Alignment.center,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// MODE CARD
// ===========================================================================
class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.isSelected,
    required this.onTap,
    required this.iconBg,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.badge,
    required this.badgeColor,
    required this.description,
    required this.features,
  });

  final bool isSelected;
  final VoidCallback onTap;
  final Color iconBg;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? badge;
  final Color? badgeColor;
  final String description;
  final List<String> features;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : const Color(0xFFF7F8F6),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon + title + badge row
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF202123),
                        ),
                      ),
                      if (badge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            color: badgeColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            badge!,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Description
            Text(
              description,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF7A7C77),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 12),

            // Features
            ...features.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 13,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Text(
                      f,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF202123),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// INFO NOTE
// ===========================================================================
class _InfoNote extends StatelessWidget {
  const _InfoNote({super.key, required this.isFixed});

  final bool isFixed;

  @override
  Widget build(BuildContext context) {
    final body = isFixed
        ? const TextSpan(
            children: [
              TextSpan(text: 'Transactions are processed in '),
              TextSpan(
                text: 'Naira (₦)',
                style: TextStyle(
                    fontWeight: FontWeight.w700, color: Color(0xFF202123)),
              ),
              TextSpan(
                text:
                    '. Fixed Mode ensures zero price changes after checkout payment.',
              ),
            ],
          )
        : const TextSpan(
            children: [
              TextSpan(text: 'Your shopper sends '),
              TextSpan(
                text: 'live price updates',
                style: TextStyle(
                    fontWeight: FontWeight.w700, color: Color(0xFF202123)),
              ),
              TextSpan(
                text:
                    ' per item. You approve or reject before anything is purchased.',
              ),
            ],
          );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EAE7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: Color(0xFFE08000),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                'i',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF7A7C77),
                  height: 1.5,
                ),
                children: body.children,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
