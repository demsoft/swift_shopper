import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../models/request_item.dart';
import 'request_status_screen.dart';
// ignore: unused_import
import '../../navigation/providers/navigation_provider.dart';

class OrderSuccessScreen extends ConsumerWidget {
  const OrderSuccessScreen({
    super.key,
    required this.orderType,
    required this.totalAmount,
    required this.deliveryFee,
    required this.storeName,
    required this.storeLocation,
    required this.items,
    this.storeImagePath,
  });

  final String orderType;
  final double totalAmount;
  final double deliveryFee;
  final String storeName;
  final String storeLocation;
  final List<RequestItem> items;
  final String? storeImagePath;

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
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F1),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // ── Glow + checkmark icon ──
              Stack(
                alignment: Alignment.center,
                children: [
                  // Outer glow
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.18),
                          AppColors.primary.withValues(alpha: 0.06),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.55, 1.0],
                      ),
                    ),
                  ),
                  // Inner green circle
                  Container(
                    width: 90,
                    height: 90,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 46,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 36),

              // ── Title ──
              const Text(
                'Request Posted\nSuccessfully!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0D1512),
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 14),

              // ── Subtitle ──
              const Text(
                "We're matching you with the best\nshopper in your area.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF7A7C77),
                  height: 1.55,
                ),
              ),

              const SizedBox(height: 40),

              // ── Order summary card ──
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    // Order type row
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              width: 48,
                              height: 48,
                              child: storeImagePath != null
                                  ? (storeImagePath!.startsWith('http')
                                      ? Image.network(
                                          storeImagePath!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              _FallbackIcon(),
                                        )
                                      : Image.asset(
                                          storeImagePath!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              _FallbackIcon(),
                                        ))
                                  : _FallbackIcon(),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'ORDER TYPE',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF9A9C97),
                                    letterSpacing: 0.6,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  orderType,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0D1512),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Watermark icon
                          Icon(
                            Icons.storefront_rounded,
                            size: 64,
                            color: const Color(0xFFF0F2EF),
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1, color: Color(0xFFF0F2EF)),

                    // Estimate + status row
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ESTIMATE',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF9A9C97),
                                  letterSpacing: 0.6,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatAmount(totalAmount),
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primary,
                                  height: 1,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFDF0E0),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'PENDING MATCH',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFD4860A),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 2),

              // ── Track Order Status button ──
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => RequestStatusScreen(
                        orderType: orderType,
                        totalAmount: totalAmount,
                        deliveryFee: deliveryFee,
                        storeName: storeName,
                        items: items,
                        storeImagePath: storeImagePath,
                      ),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  height: 58,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(29),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'Track Order Status',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // ── Back to Home ──
              GestureDetector(
                onTap: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
                child: const Text(
                  'Back to Home',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),

              const Spacer(),

              // ── Contact support ──
              GestureDetector(
                onTap: () {},
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(fontSize: 13, color: Color(0xFF9A9C97)),
                    children: [
                      TextSpan(text: 'Need help?  '),
                      TextSpan(
                        text: 'Contact Support',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _FallbackIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF0F2EF),
      child: const Icon(
        Icons.shopping_basket_rounded,
        color: AppColors.primary,
        size: 24,
      ),
    );
  }
}
