import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../models/request_item.dart';
import 'shopper_matched_screen.dart';

class RequestStatusScreen extends ConsumerStatefulWidget {
  const RequestStatusScreen({
    super.key,
    required this.orderType,
    required this.totalAmount,
    required this.storeName,
    required this.items,
  });

  final String orderType;
  final double totalAmount;
  final String storeName;
  final List<RequestItem> items;

  @override
  ConsumerState<RequestStatusScreen> createState() =>
      _RequestStatusScreenState();
}

class _RequestStatusScreenState extends ConsumerState<RequestStatusScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;
  Timer? _matchTimer;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    // Simulate shopper match after 5 seconds
    _matchTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ShopperMatchedScreen(
            shopperName: 'Ademola',
            shopperRating: 4.9,
            deliveryCount: 240,
            estimatedMinutes: 15,
            totalAmount: widget.totalAmount,
            items: widget.items,
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _matchTimer?.cancel();
    super.dispose();
  }

  String _formatAmount(double amount) {
    final formatted = amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    return '₦ $formatted';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F1),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 24),
                    _buildSearchAnimation(),
                    const SizedBox(height: 32),
                    const Text(
                      'Finding Your\nShopper...',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0D1512),
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Connecting with expert shoppers\nnear Lekki Phase 1.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF7A7C77),
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildOrderSummaryCard(),
                    const SizedBox(height: 24),
                    _buildCancelButton(context),
                    const SizedBox(height: 10),
                    const Text(
                      'You can cancel for free within the next 2 minutes.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9A9C97),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF202123),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'Request Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF202123),
              ),
            ),
          ),
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFD9DDD7),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              'assets/images/account.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.person,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAnimation() {
    return SizedBox(
      width: 260,
      height: 240,
      child: AnimatedBuilder(
        animation: _pulseAnim,
        builder: (_, __) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Outer pulsing ring
              Transform.scale(
                scale: _pulseAnim.value,
                child: Container(
                  width: 210,
                  height: 210,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFE4E7E2).withValues(alpha: 0.7),
                  ),
                ),
              ),
              // Middle ring
              Container(
                width: 160,
                height: 160,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFECEEEB),
                ),
              ),
              // Inner white circle with search icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.search_rounded,
                  color: AppColors.primary,
                  size: 42,
                ),
              ),
              // Avatar — top right
              Positioned(
                top: 10,
                right: 10,
                child: _AvatarBubble(
                  size: 52,
                  backgroundColor: const Color(0xFFE8A060),
                  imagePath: 'assets/images/account.png',
                ),
              ),
              // Avatar — left
              Positioned(
                left: 0,
                top: 85,
                child: _AvatarBubble(
                  size: 48,
                  backgroundColor: const Color(0xFF2A3A30),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
              // Store icon bubble — bottom left
              Positioned(
                left: 24,
                bottom: 16,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFE8A020),
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOrderSummaryCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F2EF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'ORDER SUMMARY',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF9A9C97),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8A020),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _formatAmount(widget.totalAmount),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Order name
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Text(
              widget.storeName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0D1512),
              ),
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF0F2EF)),

          // Items
          ...List.generate(widget.items.length, (i) {
            final item = widget.items[i];
            return _OrderItemRow(item: item, index: i);
          }),

          const Divider(height: 1, color: Color(0xFFF0F2EF)),

          // Delivery estimate row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary,
                  ),
                  child: const Icon(
                    Icons.timer_outlined,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Est. Delivery: 45m',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF5A5C56),
                  ),
                ),
                const Spacer(),
                const Text(
                  'PRIORITY PICKUP',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancelButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFFFFECEC),
          borderRadius: BorderRadius.circular(28),
        ),
        alignment: Alignment.center,
        child: const Text(
          'Cancel Request',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFFD93025),
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// AVATAR BUBBLE
// ===========================================================================
class _AvatarBubble extends StatelessWidget {
  const _AvatarBubble({
    required this.size,
    required this.backgroundColor,
    this.imagePath,
    this.child,
  });

  final double size;
  final Color backgroundColor;
  final String? imagePath;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: imagePath != null
          ? Image.asset(
              imagePath!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  child ??
                  Icon(Icons.person, color: Colors.white, size: size * 0.5),
            )
          : child,
    );
  }
}

// ===========================================================================
// ORDER ITEM ROW
// ===========================================================================
class _OrderItemRow extends StatelessWidget {
  const _OrderItemRow({required this.item, required this.index});

  final RequestItem item;
  final int index;

  static const _colors = [
    Color(0xFF2A5C3A),
    Color(0xFF4A7C3A),
    Color(0xFF3A6C5A),
    Color(0xFF5A4C2A),
  ];

  static const _icons = [
    Icons.eco_rounded,
    Icons.rice_bowl_rounded,
    Icons.local_grocery_store_rounded,
    Icons.set_meal_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final color = _colors[index % _colors.length];
    final icon = _icons[index % _icons.length];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0D1512),
                  ),
                ),
                if (item.unit.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.unit,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9A9C97),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
