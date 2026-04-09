import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import 'package:http/http.dart' as http;

import '../../../core/theme/app_colors.dart';
import '../../home/providers/home_provider.dart';
import '../providers/create_request_provider.dart';
import 'order_success_screen.dart';

class ReviewRequestScreen extends ConsumerStatefulWidget {
  const ReviewRequestScreen({
    super.key,
    required this.budget,
    required this.deliveryAddress,
    required this.deliveryLatitude,
    required this.deliveryLongitude,
    required this.deliveryNotes,
    required this.storeName,
    required this.storeLocation,
    this.storeImagePath,
    required this.marketLatitude,
    required this.marketLongitude,
  });

  final double budget;
  final String deliveryAddress;
  final double deliveryLatitude;
  final double deliveryLongitude;
  final String deliveryNotes;
  final String storeName;
  final String storeLocation;
  final String? storeImagePath;
  final double? marketLatitude;
  final double? marketLongitude;

  @override
  ConsumerState<ReviewRequestScreen> createState() =>
      _ReviewRequestScreenState();
}

class _ReviewRequestScreenState extends ConsumerState<ReviewRequestScreen> {
  static const double _serviceCharge = 1500;
  static const double _bufferRate = 0.10;
  static const double _deliveryFeePerKm = 200;
  static const double _deliveryFeeMinimum = 500;

  double? _resolvedMarketLat;
  double? _resolvedMarketLng;
  bool _geocoding = false;

  @override
  void initState() {
    super.initState();
    _resolvedMarketLat = widget.marketLatitude;
    _resolvedMarketLng = widget.marketLongitude;
    if (_resolvedMarketLat == null || _resolvedMarketLng == null) {
      _geocodeMarket();
    }
  }

  Future<void> _geocodeMarket() async {
    setState(() => _geocoding = true);
    try {
      final query = '${widget.storeName}, ${widget.storeLocation}';
      final url =
          'https://photon.komoot.io/api/?q=${Uri.encodeQueryComponent(query)}&limit=1&lang=en&bbox=2.6769,4.2725,14.6801,13.8856';
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        final features = json['features'] as List<dynamic>? ?? [];
        if (features.isNotEmpty) {
          final coords = features[0]['geometry']?['coordinates'] as List<dynamic>?;
          final lng = (coords?[0] as num?)?.toDouble();
          final lat = (coords?[1] as num?)?.toDouble();
          if (lat != null && lng != null && mounted) {
            setState(() {
              _resolvedMarketLat = lat;
              _resolvedMarketLng = lng;
            });
          }
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _geocoding = false);
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _degreesToRadians(double degrees) => degrees * (pi / 180.0);

  double _getDeliveryFee() {
    if (_resolvedMarketLat == null ||
        _resolvedMarketLng == null ||
        widget.deliveryLatitude == 0 ||
        widget.deliveryLongitude == 0) {
      return _deliveryFeeMinimum;
    }
    final distanceKm = _calculateDistance(
      _resolvedMarketLat!,
      _resolvedMarketLng!,
      widget.deliveryLatitude,
      widget.deliveryLongitude,
    );
    return max(distanceKm * _deliveryFeePerKm, _deliveryFeeMinimum);
  }

  double _fixedTotal(double deliveryFee) =>
      widget.budget + deliveryFee + _serviceCharge;

  double _flexibleBuffer() => widget.budget * _bufferRate;
  double _flexibleTotal(double deliveryFee) =>
      widget.budget + deliveryFee + _serviceCharge + _flexibleBuffer();

  String _formatAmount(double amount) {
    final formatted = amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    return '₦$formatted';
  }

  Future<void> _submit(BuildContext context) async {
    final state = ref.read(createRequestProvider);
    final itemsSnapshot = state.items.toList();
    final marketType = state.marketType;
    final deliveryFee = _getDeliveryFee();

    if (itemsSnapshot.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least one item before submitting.'),
        ),
      );
      return;
    }

    try {
      final isFlexible = ref.read(createRequestProvider).isFlexible;
      final totalBudget =
          isFlexible ? _flexibleTotal(deliveryFee) : _fixedTotal(deliveryFee);

      await ref
          .read(createRequestProvider.notifier)
          .submitRequest(
            preferredStore: widget.storeName,
            budget: totalBudget,
            deliveryAddress: widget.deliveryAddress.isNotEmpty
                ? widget.deliveryAddress
                : widget.storeLocation,
            deliveryNotes: widget.deliveryNotes,
          );

      if (!context.mounted) return;
      ref.invalidate(activeOrdersProvider);
      ref.invalidate(recentRequestsProvider);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => OrderSuccessScreen(
            orderType: marketType == MarketType.supermarket
                ? 'Supermarket Order'
                : 'Open Market Order',
            totalAmount: totalBudget,
            storeName: widget.storeName,
            storeLocation: widget.storeLocation,
            items: itemsSnapshot,
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createRequestProvider);
    final items = state.items;
    final isSubmitting = state.isSubmitting;
    final isFlexible = state.isFlexible;
    final deliveryFee = _getDeliveryFee();
    final fixedTotal = _fixedTotal(deliveryFee);
    final flexibleTotal = _flexibleTotal(deliveryFee);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2EF),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Review & Post',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF202123),
                          ),
                        ),
                        if (_geocoding)
                          const Text(
                            'Calculating delivery fee...',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                            ),
                          )
                        else
                          const Text(
                            'Review your order',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF9A9C97),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),

                    // ── DESTINATION SUMMARY ──
                    const _SectionLabel('DESTINATION SUMMARY'),
                    const SizedBox(height: 12),
                    _DestinationCard(
                      storeName: widget.storeName,
                      storeLocation: widget.storeLocation,
                      imagePath: widget.storeImagePath,
                    ),
                    const SizedBox(height: 28),

                    // ── SHOPPING LIST ──
                    Row(
                      children: [
                        _SectionLabel(
                          'SHOPPING LIST (${items.length} ITEM${items.length == 1 ? '' : 'S'})',
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).pop();
                          },
                          child: const Text(
                            'Edit List',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(items.length, (i) {
                      final item = items[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ItemReviewCard(item: item, index: i),
                      );
                    }),
                    const SizedBox(height: 28),

                    // ── BILLING SUMMARY ──
                    _BillingSummary(
                      isFlexible: isFlexible,
                      itemsTotal: widget.budget,
                      deliveryFee: deliveryFee,
                      serviceCharge: _serviceCharge,
                      buffer: _flexibleBuffer(),
                      fixedTotal: fixedTotal,
                      flexibleTotal: flexibleTotal,
                      formatAmount: _formatAmount,
                    ),

                    // ── DELIVERY NOTES ──
                    if (widget.deliveryNotes.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      const _SectionLabel('DELIVERY NOTES'),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(width: 5, color: AppColors.primary),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text(
                                    '"${widget.deliveryNotes}"',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontStyle: FontStyle.italic,
                                      color: Color(0xFF5A5C56),
                                      height: 1.55,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    // ── ESCROW NOTICE ──
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Icon(
                          Icons.shield_rounded,
                          color: AppColors.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Your payment is held in escrow until delivery is confirmed.',
                            style: TextStyle(
                              fontSize: 12,
                              color: const Color(
                                0xFF5A5C56,
                              ).withValues(alpha: 0.85),
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

            // Bottom button
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F2EF),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: GestureDetector(
                onTap: (isSubmitting || _geocoding) ? null : () => _submit(context),
                child: Container(
                  height: 58,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B5E35),
                    borderRadius: BorderRadius.circular(29),
                  ),
                  alignment: Alignment.center,
                  child:
                      isSubmitting
                          ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                          : const Text(
                            'Confirm & Post Request',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
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
// SECTION LABEL
// ===========================================================================
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Color(0xFF9A9C97),
        letterSpacing: 0.8,
      ),
    );
  }
}

// ===========================================================================
// DESTINATION CARD
// ===========================================================================
class _DestinationCard extends StatelessWidget {
  const _DestinationCard({
    required this.storeName,
    required this.storeLocation,
    this.imagePath,
  });

  final String storeName;
  final String storeLocation;
  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 200,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Store image
            if (imagePath != null)
              (imagePath!.startsWith('http'))
                  ? Image.network(
                    imagePath!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _StorePlaceholder(),
                  )
                  : Image.asset(
                    imagePath!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _StorePlaceholder(),
                  )
            else
              _StorePlaceholder(),
            // Dark gradient overlay at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 80,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.55),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Store name pill
            Positioned(
              bottom: 14,
              left: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      color: AppColors.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$storeName, $storeLocation',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
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

class _StorePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFD5DAD4),
      child: const Icon(
        Icons.storefront_rounded,
        color: Color(0xFF9A9C97),
        size: 48,
      ),
    );
  }
}

// ===========================================================================
// ITEM REVIEW CARD
// ===========================================================================
class _ItemReviewCard extends StatelessWidget {
  const _ItemReviewCard({required this.item, required this.index});

  final dynamic item;
  final int index;

  static const _icons = [
    Icons.eco_rounded,
    Icons.shopping_basket_rounded,
    Icons.local_grocery_store_rounded,
    Icons.rice_bowl_rounded,
    Icons.set_meal_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final icon = _icons[index % _icons.length];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
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
                    color: Color(0xFF202123),
                  ),
                ),
                if ((item.unit as String).isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.unit as String,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9A9C97),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F2EF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'x${item.quantity}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF5A5C56),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// FEE ROW
// ===========================================================================
class _FeeRow extends StatelessWidget {
  const _FeeRow({
    required this.label,
    required this.amount,
    required this.amountColor,
  });

  final String label;
  final String amount;
  final Color amountColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Color(0xFF5A5C56)),
        ),
        const Spacer(),
        Text(
          amount,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: amountColor,
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// BILLING SUMMARY
// ===========================================================================
class _BillingSummary extends StatelessWidget {
  const _BillingSummary({
    required this.isFlexible,
    required this.itemsTotal,
    required this.deliveryFee,
    required this.serviceCharge,
    required this.buffer,
    required this.fixedTotal,
    required this.flexibleTotal,
    required this.formatAmount,
  });

  final bool isFlexible;
  final double itemsTotal;
  final double deliveryFee;
  final double serviceCharge;
  final double buffer;
  final double fixedTotal;
  final double flexibleTotal;
  final String Function(double) formatAmount;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder:
          (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(anim),
              child: child,
            ),
          ),
      child:
          isFlexible
              ? _FlexibleBilling(
                key: const ValueKey('flexible'),
                itemsTotal: itemsTotal,
                deliveryFee: deliveryFee,
                serviceCharge: serviceCharge,
                buffer: buffer,
                total: flexibleTotal,
                formatAmount: formatAmount,
              )
              : _FixedBilling(
                key: const ValueKey('fixed'),
                itemsTotal: itemsTotal,
                deliveryFee: deliveryFee,
                serviceCharge: serviceCharge,
                total: fixedTotal,
                formatAmount: formatAmount,
              ),
    );
  }
}

// ── Fixed billing ─────────────────────────────────────────────────────────────
class _FixedBilling extends StatelessWidget {
  const _FixedBilling({
    super.key,
    required this.itemsTotal,
    required this.deliveryFee,
    required this.serviceCharge,
    required this.total,
    required this.formatAmount,
  });

  final double itemsTotal;
  final double deliveryFee;
  final double serviceCharge;
  final double total;
  final String Function(double) formatAmount;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('BILLING SUMMARY · FIXED MODE'),
          const SizedBox(height: 4),
          const Text(
            'All prices are final and will not change.',
            style: TextStyle(fontSize: 12, color: Color(0xFF7A7C77)),
          ),
          const SizedBox(height: 16),
          _FeeRow(
            label: 'Items Total',
            amount: formatAmount(itemsTotal),
            amountColor: const Color(0xFF202123),
          ),
          const SizedBox(height: 12),
          _FeeRow(
            label: 'Delivery Fee',
            amount: formatAmount(deliveryFee),
            amountColor: const Color(0xFF202123),
          ),
          const SizedBox(height: 12),
          _FeeRow(
            label: 'Service Charge',
            amount: formatAmount(serviceCharge),
            amountColor: const Color(0xFFD4860A),
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFEEF0ED), height: 1),
          const SizedBox(height: 16),
          const Text(
            'FINAL TOTAL',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                formatAmount(total),
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF202123),
                  height: 1,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F4EA),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'GUARANTEED PRICE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Flexible billing ──────────────────────────────────────────────────────────
class _FlexibleBilling extends StatelessWidget {
  const _FlexibleBilling({
    super.key,
    required this.itemsTotal,
    required this.deliveryFee,
    required this.serviceCharge,
    required this.buffer,
    required this.total,
    required this.formatAmount,
  });

  final double itemsTotal;
  final double deliveryFee;
  final double serviceCharge;
  final double buffer;
  final double total;
  final String Function(double) formatAmount;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('BILLING SUMMARY · FLEXIBLE MODE'),
          const SizedBox(height: 4),
          const Text(
            'Item prices may change during shopping. Any unused balance is refunded to your wallet.',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF7A7C77),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          _FeeRow(
            label: 'Estimated Items Total',
            amount: formatAmount(itemsTotal),
            amountColor: const Color(0xFF202123),
          ),
          const SizedBox(height: 12),
          _FeeRow(
            label: 'Delivery Fee',
            amount: formatAmount(deliveryFee),
            amountColor: const Color(0xFF202123),
          ),
          const SizedBox(height: 12),
          _FeeRow(
            label: 'Service Charge',
            amount: formatAmount(serviceCharge),
            amountColor: const Color(0xFFD4860A),
          ),
          const SizedBox(height: 12),
          _FeeRow(
            label: 'Buffer (10%)',
            amount: formatAmount(buffer),
            amountColor: const Color(0xFFD4860A),
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFEEF0ED), height: 1),
          const SizedBox(height: 16),
          const Text(
            'TOTAL AMOUNT TO FUND',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                formatAmount(total),
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF202123),
                  height: 1,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDF0E0),
                  border: Border.all(
                    color: const Color(0xFFD4860A),
                    width: 1.2,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'REFUNDABLE BALANCE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFD4860A),
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
