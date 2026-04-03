import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../models/home_models.dart';
import '../providers/home_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../chat/presentation/chat_screen.dart';

// item status ints from backend OrderItemStatus enum
// 0 = Pending, 1 = Found, 2 = Unavailable

class OrderDetailsScreen extends ConsumerStatefulWidget {
  const OrderDetailsScreen({super.key, required this.order});

  final ActiveOrder order;

  @override
  ConsumerState<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends ConsumerState<OrderDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(orderItemsProvider(widget.order.orderId));
    });
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final trackingAsync = ref.watch(orderTrackingProvider(order.orderId));
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2EF),
      body: SafeArea(
        child: trackingAsync.when(
          loading: () => Column(
            children: [
              _buildHeader(context, ref, shopperName: '', user: user),
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
            ],
          ),
          error: (e, _) => Column(
            children: [
              _buildHeader(context, ref, shopperName: '', user: user),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.wifi_off_rounded,
                            size: 48, color: AppColors.textSecondary),
                        const SizedBox(height: 12),
                        Text(e.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 13)),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () =>
                              ref.invalidate(orderTrackingProvider(order.orderId)),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          data: (tracking) {
            final shopperName =
                tracking?.shopperName ?? order.shopperName;
            final storeName = tracking?.storeName ?? order.title;
            final status = tracking?.currentStatus ?? order.status;
            final stepLabel = tracking?.stepLabel ?? '';
            final progressPercent = tracking?.progressPercent ?? 0;
            final progress = progressPercent / 100.0;
            final pickedCount = tracking?.pickedItemsCount ?? 0;
            final totalCount = tracking?.totalItemsCount ?? 0;
            final minsLeft = tracking?.estimatedDeliveryMinutes ?? 0;

            // Resolve photo: try order.storePhotoUrl first, then
            // search all loaded markets case-insensitively by store name
            final supermarkets =
                ref.watch(supermarketsProvider).valueOrNull ?? [];
            final openMarkets =
                ref.watch(openMarketsProvider).valueOrNull ?? [];
            final photoUrl = order.storePhotoUrl?.isNotEmpty == true
                ? order.storePhotoUrl
                : [...supermarkets, ...openMarkets]
                    .where((m) =>
                        m.name.toLowerCase() == storeName.toLowerCase())
                    .map((m) => m.photoUrl)
                    .firstWhere((u) => u != null && u.isNotEmpty,
                        orElse: () => null);

            return Column(
              children: [
                _buildHeader(context, ref,
                    shopperName: shopperName, user: user),
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () async =>
                        ref.invalidate(orderTrackingProvider(order.orderId)),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          _buildStoreImage(storeName, status, photoUrl),
                          const SizedBox(height: 16),
                          _buildStatusCard(
                            status: status,
                            stepLabel: stepLabel,
                            progress: progress,
                            progressPercent: progressPercent,
                            pickedCount: pickedCount,
                            totalCount: totalCount,
                            minsLeft: minsLeft,
                          ),
                          const SizedBox(height: 14),
                          if (shopperName.isNotEmpty)
                            _buildShopperCard(context, shopperName, tracking?.shopperAvatarUrl),
                          const SizedBox(height: 24),
                          _buildItemsSection(ref, order.orderId),
                          const SizedBox(height: 16),
                          _buildOrderSummaryCard(order),
                          const SizedBox(height: 16),
                          _buildGetHelp(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── HEADER ──────────────────────────────────────────────────────────────
  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref, {
    required String shopperName,
    required dynamic user,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 4),
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
              'Order Status',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 34),
        ],
      ),
    );
  }

  // ── STORE IMAGE ──────────────────────────────────────────────────────────
  Widget _buildStoreImage(String storeName, String status, String? photoUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 200,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            photoUrl != null && photoUrl.isNotEmpty
                ? Image.network(
                    photoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFF2A3A28),
                      child: const Icon(Icons.storefront_rounded,
                          color: Colors.white24, size: 72),
                    ),
                  )
                : Container(
                    color: const Color(0xFF2A3A28),
                    child: const Icon(Icons.storefront_rounded,
                        color: Colors.white24, size: 72),
                  ),
            // gradient overlay
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
            Positioned(
              bottom: 14,
              left: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      storeName.isNotEmpty
                          ? storeName.toUpperCase()
                          : 'SHOPPING IN PROGRESS',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF202123),
                        letterSpacing: 0.3,
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

  // ── STATUS CARD ──────────────────────────────────────────────────────────
  Widget _buildStatusCard({
    required String status,
    required String stepLabel,
    required double progress,
    required int progressPercent,
    required int pickedCount,
    required int totalCount,
    required int minsLeft,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                if (stepLabel.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    stepLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9A9C97),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    backgroundColor: const Color(0xFFE8EAE7),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$progressPercent% Processed',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9A9C97),
                      ),
                    ),
                    if (totalCount > 0)
                      Text(
                        '$pickedCount / $totalCount Items',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9A9C97),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (minsLeft > 0) ...[
            const SizedBox(width: 16),
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFF8C00),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$minsLeft',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                  const Text(
                    'MINS\nLEFT',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── SHOPPER CARD ─────────────────────────────────────────────────────────
  Widget _buildShopperCard(BuildContext context, String shopperName, String? shopperAvatarUrl) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
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
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFFE8A060),
            backgroundImage: shopperAvatarUrl != null && shopperAvatarUrl.isNotEmpty
                ? NetworkImage(shopperAvatarUrl)
                : null,
            child: shopperAvatarUrl == null || shopperAvatarUrl.isEmpty
                ? const Icon(Icons.person, color: Colors.white, size: 28)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shopperName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0D1512),
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Your Shopper',
                  style: TextStyle(fontSize: 13, color: Color(0xFF7A7C77)),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ChatScreen(
                        orderId: widget.order.orderId,
                        otherPersonName: shopperName,
                        otherPersonRole: 'EXPERT SHOPPER',
                        otherPersonAvatarUrl: shopperAvatarUrl,
                      ),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.mail_outline_rounded, color: Colors.white, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Message',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── ITEMS SECTION ────────────────────────────────────────────────────────
  Widget _buildItemsSection(WidgetRef ref, String orderId) {
    final itemsAsync = ref.watch(orderItemsProvider(orderId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Shopping List',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0D1512),
          ),
        ),
        const SizedBox(height: 14),
        itemsAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
          error: (e, _) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.wifi_off_rounded, color: AppColors.textSecondary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(e.toString(),
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13)),
                ),
                TextButton(
                  onPressed: () => ref.invalidate(orderItemsProvider(orderId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (items) {
            if (items.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.shopping_basket_outlined,
                        size: 36, color: AppColors.textSecondary),
                    SizedBox(height: 8),
                    Text('No items found',
                        style: TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              );
            }
            return Column(
              children: items
                  .map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _OrderItemCard(item: item),
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  // ── ORDER SUMMARY CARD ───────────────────────────────────────────────────
  Widget _buildOrderSummaryCard(ActiveOrder order) {
    final itemsSubtotal = order.itemsSubtotal;
    final estimatedItemsTotal = order.estimatedItemsTotal;
    final deliveryFee = order.deliveryFee;
    final serviceFee = order.serviceFee;
    final baseItems = itemsSubtotal > 0 ? itemsSubtotal : estimatedItemsTotal;
    final grandTotal = baseItems + deliveryFee + serviceFee;
    final isEstimate = itemsSubtotal == 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Breakdown rows
          _SummaryRow(
            label: isEstimate ? 'Items (estimated)' : 'Items subtotal',
            value: baseItems,
            isEstimate: isEstimate,
          ),
          const SizedBox(height: 8),
          _SummaryRow(label: 'Delivery fee', value: deliveryFee),
          const SizedBox(height: 8),
          _SummaryRow(label: 'Service fee', value: serviceFee),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Colors.white24, height: 1),
          ),
          // Grand total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isEstimate ? 'ESTIMATED TOTAL' : 'TOTAL',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white70,
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                grandTotal > 0
                    ? '₦${_fmtAmt(grandTotal)}'
                    : 'Calculating...',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmtAmt(double v) => v
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  // ── GET HELP ─────────────────────────────────────────────────────────────
  Widget _buildGetHelp() {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFFFFECEC),
          borderRadius: BorderRadius.circular(28),
        ),
        alignment: Alignment.center,
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.help_rounded, color: Color(0xFFD93025), size: 20),
            SizedBox(width: 8),
            Text(
              'Get Help',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFFD93025),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// SUMMARY ROW
// ===========================================================================
class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.isEstimate = false,
  });

  final String label;
  final double value;
  final bool isEstimate;

  String _fmt(double v) => v
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value > 0 ? '${isEstimate ? '~' : ''}₦${_fmt(value)}' : '—',
          style: const TextStyle(
            fontSize: 13,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// ORDER ITEM CARD
// ===========================================================================
class _OrderItemCard extends StatelessWidget {
  const _OrderItemCard({required this.item});

  final ActiveJobItem item;

  String _fmt(double v) => v
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  @override
  Widget build(BuildContext context) {
    // 0=Pending, 1=Found, 2=Unavailable
    final isPicked = item.status == 1;
    final isUnavailable = item.status == 2;

    final Color iconBg = isPicked
        ? const Color(0xFF2A4A2E)
        : isUnavailable
            ? const Color(0xFFEEEEEE)
            : const Color(0xFFE8EAE7);

    final Color iconColor = isPicked
        ? Colors.white
        : isUnavailable
            ? const Color(0xFFB0B2AD)
            : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isUnavailable
            ? Border.all(color: const Color(0xFFD9DDD7), width: 1)
            : null,
        boxShadow: !isUnavailable
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // icon or tappable photo
          GestureDetector(
            onTap: item.photoUrl != null && item.photoUrl!.isNotEmpty
                ? () => _openPhoto(context, item.photoUrl!)
                : null,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 60,
                    height: 60,
                    child: item.photoUrl != null && item.photoUrl!.isNotEmpty
                        ? Image.network(
                            item.photoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _iconBox(iconBg, iconColor),
                          )
                        : _iconBox(iconBg, iconColor),
                  ),
                ),
                if (item.photoUrl != null && item.photoUrl!.isNotEmpty)
                  Positioned(
                    bottom: -4,
                    right: -4,
                    child: Container(
                      width: 20, height: 20,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt_rounded,
                          color: Colors.white, size: 12),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // name + detail
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isUnavailable
                        ? const Color(0xFFB0B2AD)
                        : const Color(0xFF0D1512),
                  ),
                ),
                const SizedBox(height: 3),
                if (item.unit.isNotEmpty)
                  Text(
                    item.unit,
                    style: TextStyle(
                      fontSize: 12,
                      color: isUnavailable
                          ? const Color(0xFFB0B2AD)
                          : const Color(0xFF9A9C97),
                    ),
                  ),
                if (item.description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.description,
                    style: const TextStyle(fontSize: 11, color: Color(0xFFB0B2AD)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                // qty × unit price
                if (item.estimatedPrice > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.quantity > 1
                        ? '${item.quantity} × ~₦${_fmt(item.estimatedPrice)}'
                        : '~₦${_fmt(item.estimatedPrice)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isUnavailable
                          ? const Color(0xFFB0B2AD)
                          : const Color(0xFF9A9C97),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          // line total + status icon
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // show actual found price if available, else estimated line total
              if (item.foundPrice != null)
                Text(
                  '₦${_fmt(item.foundPrice!)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isUnavailable
                        ? const Color(0xFFB0B2AD)
                        : const Color(0xFF0D1512),
                  ),
                )
              else if (item.estimatedPrice > 0)
                Text(
                  '~₦${_fmt(item.estimatedPrice * item.quantity)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isUnavailable
                        ? const Color(0xFFB0B2AD)
                        : const Color(0xFF0D1512),
                  ),
                ),
              const SizedBox(height: 6),
              if (isPicked)
                const Icon(Icons.check_circle_rounded,
                    color: AppColors.primary, size: 22)
              else if (isUnavailable)
                const Icon(Icons.cancel_outlined,
                    color: Color(0xFFB0B2AD), size: 22)
              else
                const Icon(Icons.radio_button_unchecked_rounded,
                    color: Color(0xFFD0D2CD), size: 22),
            ],
          ),
        ],
      ),
    );
  }

  void _openPhoto(BuildContext context, String url) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _PhotoViewScreen(url: url, itemName: item.name),
      ),
    );
  }

  Widget _iconBox(Color bg, Color iconColor) {
    return Container(
      color: bg,
      child: Icon(Icons.shopping_basket_rounded, color: iconColor, size: 28),
    );
  }
}

// ===========================================================================
// FULL-SCREEN PHOTO VIEWER
// ===========================================================================
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
          // Pinch-to-zoom image
          Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                url,
                fit: BoxFit.contain,
                loadingBuilder: (_, child, progress) => progress == null
                    ? child
                    : const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                errorBuilder: (_, __, ___) => const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.broken_image_rounded,
                          color: Colors.white54, size: 56),
                      SizedBox(height: 12),
                      Text('Could not load photo',
                          style: TextStyle(color: Colors.white54)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Header
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      itemName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
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
