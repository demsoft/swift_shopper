import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../models/home_models.dart';
import '../providers/home_provider.dart';

class ShopperJobDetailScreen extends ConsumerWidget {
  const ShopperJobDetailScreen({super.key, required this.order});

  final ShopperOrderData order;

  String _fmt(double v) => v
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(shopperOrderSummaryProvider(order.orderId));

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F1),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 16, 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Color(0xFF202123), size: 20),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Completed Job',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0D1512),
                          ),
                        ),
                        Text(
                          order.completedAt,
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF9A9C97)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: summaryAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (e, _) => _ErrorView(
                  message: e.toString(),
                  onRetry: () =>
                      ref.invalidate(orderSummaryProvider(order.orderId)),
                ),
                data: (summary) => _DetailBody(
                  order: order,
                  summary: summary,
                  fmt: _fmt,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Detail body ───────────────────────────────────────────────────────────────
class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.order,
    required this.summary,
    required this.fmt,
  });

  final ShopperOrderData order;
  final OrderSummaryData? summary;
  final String Function(double) fmt;

  @override
  Widget build(BuildContext context) {
    final s = summary;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {},
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // ── Status badge ────────────────────────────────────────────────
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: order.isCancelled
                    ? const Color(0xFFFFEBEE)
                    : const Color(0xFFE6F4EA),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    order.isCancelled
                        ? Icons.cancel_outlined
                        : Icons.check_circle_rounded,
                    size: 16,
                    color: order.isCancelled
                        ? const Color(0xFFD93025)
                        : AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    order.isCancelled ? 'CANCELLED' : 'DELIVERED',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: order.isCancelled
                          ? const Color(0xFFD93025)
                          : AppColors.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Store + customer card ───────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F4EA),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.storefront_rounded,
                          color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.storeName,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0D1512)),
                          ),
                          if (s?.storeAddress.isNotEmpty == true) ...[
                            const SizedBox(height: 2),
                            Text(
                              s!.storeAddress,
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xFF9A9C97)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFF0F2EF)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.person_outline_rounded,
                        size: 16, color: Color(0xFF9A9C97)),
                    const SizedBox(width: 8),
                    const Text(
                      'CUSTOMER',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF9A9C97),
                          letterSpacing: 0.6),
                    ),
                    const Spacer(),
                    Text(
                      order.customerName.isNotEmpty
                          ? order.customerName
                          : 'Customer',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0D1512)),
                    ),
                  ],
                ),
                if (s?.deliveryAddress.isNotEmpty == true) ...[
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on_rounded,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          s!.deliveryAddress,
                          style: const TextStyle(
                              fontSize: 13, color: Color(0xFF5A5C56)),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Items ────────────────────────────────────────────────────────
          if (s != null && s.items.isNotEmpty) ...[
            Row(
              children: [
                const Text(
                  'Items',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0D1512)),
                ),
                const Spacer(),
                Text(
                  '${s.items.length} ITEM${s.items.length == 1 ? '' : 'S'}',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...s.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ItemCard(item: item, fmt: fmt),
                )),
            const SizedBox(height: 8),
          ],

          // ── Earnings card ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'EARNINGS SUMMARY',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white70,
                      letterSpacing: 0.8),
                ),
                const SizedBox(height: 14),
                if (s != null) ...[
                  _EarningsRow(
                      label: 'Items Subtotal',
                      value: '₦${fmt(s.itemsSubtotal)}'),
                  const SizedBox(height: 8),
                  _EarningsRow(
                      label: 'Delivery Fee',
                      value: s.deliveryFee > 0
                          ? '₦${fmt(s.deliveryFee)}'
                          : '—'),
                  const SizedBox(height: 8),
                  _EarningsRow(
                      label: 'Service Fee',
                      value:
                          s.serviceFee > 0 ? '₦${fmt(s.serviceFee)}' : '—'),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(color: Colors.white24, height: 1),
                  ),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'YOUR EARNINGS',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white70,
                          letterSpacing: 0.6),
                    ),
                    Text(
                      '₦${fmt(order.earningsAmount)}',
                      style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Item card ──────────────────────────────────────────────────────────────────
class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item, required this.fmt});

  final OrderSummaryItem item;
  final String Function(double) fmt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 56,
              height: 56,
              child: item.photoUrl != null && item.photoUrl!.isNotEmpty
                  ? Image.network(item.photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder())
                  : _placeholder(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0D1512)),
                ),
                if (item.unit.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${item.quantity} × ${item.unit}',
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF9A9C97)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₦${fmt(item.price)}',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0D1512)),
              ),
              const SizedBox(height: 4),
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.primary, size: 18),
            ],
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
        color: const Color(0xFFE8EAE7),
        child: const Icon(Icons.shopping_basket_rounded,
            color: Color(0xFF9A9C97), size: 26),
      );
}

// ── Earnings row ───────────────────────────────────────────────────────────────
class _EarningsRow extends StatelessWidget {
  const _EarningsRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 13, color: Colors.white70)),
        Text(value,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white)),
      ],
    );
  }
}

// ── Error view ─────────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded,
                size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 16),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
