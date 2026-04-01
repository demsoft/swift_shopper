import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class OrderSummaryScreen extends StatelessWidget {
  const OrderSummaryScreen({
    super.key,
    this.orderId = '#SS-28105',
    this.date = '12 Feb',
  });

  final String orderId;
  final String date;

  static const _items = [
    _SummaryItem(
      name: 'Fresh Vine Tomatoes',
      desc: '500g Pack',
      price: 4500,
      quantity: 3,
      imagePath: 'assets/images/screen1.png',
    ),
    _SummaryItem(
      name: 'Long Grain Rice',
      desc: '5kg Mama Gold',
      price: 12200,
      quantity: 1,
      imagePath: 'assets/images/screen2.png',
    ),
    _SummaryItem(
      name: 'Vegetable Oil',
      desc: '3 Litre Bottle',
      price: 8800,
      quantity: 1,
      imagePath: 'assets/images/screen4.png',
    ),
  ];

  static const double _deliveryFee = 1200;
  static const double _serviceFee = 350;

  double get _subtotal =>
      _items.fold(0, (sum, item) => sum + item.price * item.quantity);
  double get _total => _subtotal + _deliveryFee + _serviceFee;

  String _fmt(double v) => v
      .toStringAsFixed(0)
      .replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );

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
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSuccessCard(),
                    const SizedBox(height: 14),
                    _buildShopperCard(),
                    const SizedBox(height: 10),
                    _buildDeliveryCard(),
                    const SizedBox(height: 24),
                    _buildItemsSection(),
                    const SizedBox(height: 24),
                    _buildFinancialSummary(),
                    const SizedBox(height: 20),
                    _buildReorderButton(),
                    const SizedBox(height: 14),
                    _buildDownloadReceipt(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── HEADER ────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF202123),
              size: 20,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Order Summary',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0D1512),
                  ),
                ),
                Text(
                  '$orderId • $date',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF9A9C97),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── SUCCESS CARD ──────────────────────────────────────────────────────────
  Widget _buildSuccessCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 28),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.5),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 14,
                ),
                SizedBox(width: 6),
                Text(
                  'DELIVERED SUCCESSFULLY',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Thank you for\nyour order!',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Your groceries were delivered to Victoria Island by Ademola on Tuesday afternoon.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.85),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── SHOPPER CARD ──────────────────────────────────────────────────────────
  Widget _buildShopperCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFE8A060),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              'assets/images/account.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.person,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Ademola',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0D1512),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F4EA),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'COMPLETED',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFE8A020),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      '4.9 (240+ orders)',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                      ),
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

  // ── DELIVERY CARD ─────────────────────────────────────────────────────────
  Widget _buildDeliveryCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4F0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'DELIVERY TO',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF9A9C97),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                '22 Victoria Island, Lagos',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0D1512),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── ITEMS SECTION ─────────────────────────────────────────────────────────
  Widget _buildItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Items Purchased',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0D1512),
          ),
        ),
        const SizedBox(height: 12),
        ..._items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ItemCard(item: item),
          ),
        ),
      ],
    );
  }

  // ── FINANCIAL SUMMARY ─────────────────────────────────────────────────────
  Widget _buildFinancialSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Financial Summary',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0D1512),
          ),
        ),
        const SizedBox(height: 16),
        _FinancialRow(label: 'Subtotal', amount: '₦ ${_fmt(_subtotal)}'),
        const SizedBox(height: 12),
        _FinancialRow(label: 'Delivery Fee', amount: '₦ ${_fmt(_deliveryFee)}'),
        const SizedBox(height: 12),
        _FinancialRow(label: 'Service Fee', amount: '₦ ${_fmt(_serviceFee)}'),
        const SizedBox(height: 16),
        // Total row
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: const Color(0xFFE6F4EA),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Text(
                'TOTAL PAID',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Text(
                '₦ ${_fmt(_total)}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── REORDER BUTTON ────────────────────────────────────────────────────────
  Widget _buildReorderButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(28),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text(
              'Reorder These Items',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── DOWNLOAD RECEIPT ──────────────────────────────────────────────────────
  Widget _buildDownloadReceipt() {
    return Center(
      child: GestureDetector(
        onTap: () {},
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              color: Color(0xFF6B7280),
              size: 16,
            ),
            SizedBox(width: 6),
            Text(
              'Download PDF Receipt',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// SUMMARY ITEM DATA
// ===========================================================================
class _SummaryItem {
  const _SummaryItem({
    required this.name,
    required this.desc,
    required this.price,
    required this.quantity,
    required this.imagePath,
  });

  final String name;
  final String desc;
  final double price;
  final int quantity;
  final String imagePath;
}

// ===========================================================================
// ITEM CARD
// ===========================================================================
class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item});

  final _SummaryItem item;

  String _fmt(double v) => v
      .toStringAsFixed(0)
      .replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
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
          // Image with quantity badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  item.imagePath,
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8EAE7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.image_outlined,
                      color: Color(0xFFB0B2AD),
                      size: 30,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: -6,
                left: -6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${item.quantity}x',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          // Name + desc
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
                const SizedBox(height: 3),
                Text(
                  item.desc,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9A9C97),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Price + checkmark
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₦ ${_fmt(item.price)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0D1512),
                ),
              ),
              const SizedBox(height: 6),
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// FINANCIAL ROW
// ===========================================================================
class _FinancialRow extends StatelessWidget {
  const _FinancialRow({required this.label, required this.amount});

  final String label;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
        ),
        const Spacer(),
        Text(
          amount,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0D1512),
          ),
        ),
      ],
    );
  }
}
