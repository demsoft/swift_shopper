import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../models/home_models.dart';
import '../providers/home_provider.dart';
import '../../shared/data/swift_shopper_repository.dart';

class ShoppingCompletedScreen extends ConsumerStatefulWidget {
  const ShoppingCompletedScreen({super.key, required this.job});

  final ActiveJobData job;

  @override
  ConsumerState<ShoppingCompletedScreen> createState() =>
      _ShoppingCompletedScreenState();
}

class _ShoppingCompletedScreenState
    extends ConsumerState<ShoppingCompletedScreen> {
  bool _sending = false;

  String _fmt(double v) => v
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  Future<void> _confirmAndSend() async {
    setState(() => _sending = true);
    try {
      final repo = ref.read(swiftShopperRepositoryProvider);
      await repo.startDelivery(orderId: widget.job.orderId);
      ref.invalidate(activeJobProvider);
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start delivery: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    final foundItems = job.items.where((i) => i.status == 1).toList();
    final unavailableItems = job.items.where((i) => i.status == 2).toList();
    final allItems = job.items;

    final subtotal = foundItems.fold<double>(
      0,
      (sum, i) => sum + (i.foundPrice ?? i.estimatedPrice),
    );
    final shopperFee = job.shopperFee;
    final deliveryFee = job.deliveryFee;
    final serviceFee = job.serviceFee;
    final finalTotal = subtotal + shopperFee + deliveryFee + serviceFee;

    // Resolve store photo from markets providers
    String? storePhotoUrl;
    void resolvePhoto(List<MarketData> markets) {
      for (final m in markets) {
        if (m.name.toLowerCase() == job.storeName.toLowerCase() &&
            m.photoUrl != null) {
          storePhotoUrl = m.photoUrl;
          return;
        }
      }
    }
    ref.watch(supermarketsProvider).whenData(resolvePhoto);
    if (storePhotoUrl == null) {
      ref.watch(openMarketsProvider).whenData(resolvePhoto);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F1),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ───────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 16, 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Color(0xFF202123), size: 20),
                  ),
                  const Expanded(
                    child: Text(
                      'Order Summary',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0D1512),
                      ),
                    ),
                  ),
                  const Icon(Icons.more_vert_rounded,
                      color: Color(0xFF9A9C97), size: 22),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Completion badge ──────────────────────────────────────
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_rounded,
                                color: Colors.white, size: 40),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Shopping Completed',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0D1512),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${foundItems.length} of ${allItems.length} items successfully picked',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF9A9C97),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Store card ────────────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A3A28),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: storePhotoUrl != null
                                ? Image.network(
                                    storePhotoUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                        Icons.storefront_rounded,
                                        color: Colors.white38,
                                        size: 30),
                                  )
                                : const Icon(Icons.storefront_rounded,
                                    color: Colors.white38, size: 30),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  job.storeName,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0D1512),
                                  ),
                                ),
                                if (job.storeAddress.isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on_rounded,
                                          size: 12,
                                          color: Color(0xFF9A9C97)),
                                      const SizedBox(width: 3),
                                      Expanded(
                                        child: Text(
                                          job.storeAddress,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF9A9C97),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'ACTIVE\nJOB',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Picked items header ───────────────────────────────────
                    Row(
                      children: [
                        const Text(
                          'Picked Items',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0D1512),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${foundItems.length}/${allItems.length} FOUND',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // ── Item list ─────────────────────────────────────────────
                    ...allItems.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _ItemRow(item: item),
                        )),

                    if (unavailableItems.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline_rounded,
                                  color: Color(0xFFE8A020), size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${unavailableItems.length} item${unavailableItems.length > 1 ? 's' : ''} could not be found.',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF7A5800),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // ── Billing breakdown ─────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F6F4),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'BILLING BREAKDOWN',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF9A9C97),
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _BillingRow(
                            label: 'Subtotal (${foundItems.length} items)',
                            value: '₦${_fmt(subtotal)}',
                          ),
                          const SizedBox(height: 10),
                          const SizedBox(height: 10),
                          _BillingRow(
                            label: 'Personal Shopper Fee',
                            value: shopperFee > 0 ? '₦${_fmt(shopperFee)}' : '—',
                          ),
                          const SizedBox(height: 10),
                          _BillingRow(
                            label: 'Delivery Fee',
                            value: deliveryFee > 0 ? '₦${_fmt(deliveryFee)}' : '—',
                          ),
                          const SizedBox(height: 10),
                          _BillingRow(
                            label: 'Service Charge',
                            value: serviceFee > 0 ? '₦${_fmt(serviceFee)}' : '—',
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: Divider(height: 1, color: Color(0xFFE0E0E0)),
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                'Final Total',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0D1512),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF8C00),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'FINAL',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '₦${_fmt(finalTotal)}',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF0D1512),
                                    ),
                                  ),
                                  const Text(
                                    'SECURE PAYMENT PENDING',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // ── Confirm button ────────────────────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: _sending ? null : _confirmAndSend,
                      icon: _sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded,
                              color: Colors.white, size: 18),
                      label: const Text(
                        'Confirm & Send to Customer',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'By clicking confirm, you verify that all prices are\naccurate and match the printed store receipt.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Color(0xFF9A9C97)),
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

// ── Item row ──────────────────────────────────────────────────────────────────
class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});

  final ActiveJobItem item;

  String _fmt(double v) => v
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  @override
  Widget build(BuildContext context) {
    final isFound = item.status == 1;
    final isUnavailable = item.status == 2;
    final price = isFound ? (item.foundPrice ?? item.estimatedPrice) : 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Photo or placeholder
          GestureDetector(
            onTap: item.photoUrl != null
                ? () => _openPhoto(context, item.photoUrl!, item.name)
                : null,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: item.photoUrl != null
                        ? Image.network(item.photoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholder(isUnavailable))
                        : _placeholder(isUnavailable),
                  ),
                ),
                if (item.photoUrl != null)
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt_rounded,
                          color: Colors.white, size: 10),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isUnavailable
                        ? const Color(0xFFB0B2AD)
                        : const Color(0xFF0D1512),
                  ),
                ),
                const SizedBox(height: 3),
                if (isUnavailable)
                  const Text(
                    'NOT FOUND / SUBSTITUTED',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFE8A020),
                    ),
                  )
                else
                  Text(
                    '${item.quantity} unit${item.quantity > 1 ? 's' : ''} • ₦${_fmt(item.estimatedPrice)} each',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9A9C97),
                    ),
                  ),
                if (item.photoUrl != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.camera_alt_outlined,
                          size: 12, color: AppColors.primary),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () =>
                            _openPhoto(context, item.photoUrl!, item.name),
                        child: const Text(
                          'View Captured Receipt',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isUnavailable ? '₦0' : '₦${_fmt(price)}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: isUnavailable
                  ? const Color(0xFFB0B2AD)
                  : const Color(0xFF0D1512),
            ),
          ),
        ],
      ),
    );
  }

  void _openPhoto(BuildContext context, String url, String name) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => _PhotoViewScreen(url: url, itemName: name),
    ));
  }

  Widget _placeholder(bool isUnavailable) {
    return Container(
      color: isUnavailable
          ? const Color(0xFFEEEEEE)
          : const Color(0xFFE8EAE7),
      child: Icon(
        Icons.shopping_basket_rounded,
        color: isUnavailable
            ? const Color(0xFFB0B2AD)
            : const Color(0xFF9A9C97),
        size: 26,
      ),
    );
  }
}

// ── Billing row ───────────────────────────────────────────────────────────────
class _BillingRow extends StatelessWidget {
  const _BillingRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
        Text(value,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0D1512))),
      ],
    );
  }
}

// ── Full-screen photo viewer ───────────────────────────────────────────────────
class _PhotoViewScreen extends StatelessWidget {
  const _PhotoViewScreen({required this.url, required this.itemName});

  final String url;
  final String itemName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(url, fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.broken_image_rounded,
                            color: Colors.white54, size: 56),
                      )),
            ),
          ),
          SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(itemName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
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
