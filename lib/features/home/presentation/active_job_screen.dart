import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../chat/presentation/chat_screen.dart';
import '../../shared/data/swift_shopper_repository.dart';
import '../models/home_models.dart';
import '../providers/home_provider.dart';
import 'scan_item_sheet.dart';

// ===========================================================================
// ACTIVE JOB SCREEN — loads real data from /api/orders/shopper/active-job
// ===========================================================================
class ActiveJobScreen extends ConsumerStatefulWidget {
  const ActiveJobScreen({super.key, this.initialJob});

  /// If provided (e.g. from the accept-request flow), shown immediately
  /// without waiting for the network fetch.
  final ActiveJobData? initialJob;

  @override
  ConsumerState<ActiveJobScreen> createState() => _ActiveJobScreenState();
}

class _ActiveJobScreenState extends ConsumerState<ActiveJobScreen> {
  @override
  void initState() {
    super.initState();
    // Only refresh from API if we don't already have job data passed in
    if (widget.initialJob == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.invalidate(activeJobProvider);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final initialJob = widget.initialJob;
    final jobAsync = ref.watch(activeJobProvider);

    // Resolve which job to show:
    // 1. If provider has real data, always prefer it.
    // 2. If provider is loading or returned null, fall back to initialJob.
    ActiveJobData? resolvedJob;
    bool isLoading = false;
    Object? error;

    if (jobAsync is AsyncData<ActiveJobData?>) {
      resolvedJob = jobAsync.value ?? initialJob;
    } else if (jobAsync is AsyncError<ActiveJobData?>) {
      if (initialJob != null) {
        resolvedJob = initialJob;
      } else {
        error = (jobAsync as AsyncError).error;
      }
    } else {
      // AsyncLoading
      if (initialJob != null) {
        resolvedJob = initialJob;
      } else {
        isLoading = true;
      }
    }

    Widget body;
    if (isLoading) {
      body = const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    } else if (error != null) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildBackHeader(context),
              const SizedBox(height: 40),
              const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textSecondary),
              const SizedBox(height: 16),
              Text(
                'Could not load job.\n$error',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => ref.invalidate(activeJobProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    } else if (resolvedJob == null) {
      body = const _NoActiveJobView();
    } else {
      body = _ActiveJobView(job: resolvedJob);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F1),
      body: SafeArea(
        child: body,
      ),
    );
  }
}

// ── No active job state ──────────────────────────────────────────────────────
class _NoActiveJobView extends StatelessWidget {
  const _NoActiveJobView();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildBackHeader(context),
        const Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.work_off_outlined, size: 56, color: AppColors.textSecondary),
                SizedBox(height: 16),
                Text(
                  'No Active Job',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Accept a request to start a new job.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

Widget _buildBackHeader(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(8, 12, 16, 4),
    child: Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF202123), size: 20),
        ),
        const Expanded(
          child: Text(
            'ACTIVE JOB',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0D1512),
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(width: 40),
      ],
    ),
  );
}

// ── Main job view ────────────────────────────────────────────────────────────
class _ActiveJobView extends ConsumerStatefulWidget {
  const _ActiveJobView({required this.job});

  final ActiveJobData job;

  @override
  ConsumerState<_ActiveJobView> createState() => _ActiveJobViewState();
}

class _ActiveJobViewState extends ConsumerState<_ActiveJobView> {
  bool _finishing = false;
  String? _finishError;

  String _fmt(double v) => v
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  Future<void> _finishShopping() async {
    setState(() {
      _finishing = true;
      _finishError = null;
    });
    try {
      final repo = ref.read(swiftShopperRepositoryProvider);
      await repo.finishShopping(orderId: widget.job.orderId);
      ref.invalidate(activeJobProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _finishError = e.toString();
        _finishing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    final foundCount = job.items.where((i) => i.status == 1).length;
    final totalCount = job.items.length;
    final progress = totalCount > 0 ? foundCount / totalCount : 0.0;

    return Column(
      children: [
        _buildBackHeader(context),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Store card
                _StoreCard(storeName: job.storeName, storeAddress: job.storeAddress),
                const SizedBox(height: 12),
                // Customer row
                _CustomerRow(customerName: job.customerName, customerAvatarUrl: job.customerAvatarUrl, deliveryAddress: job.deliveryAddress, orderId: job.orderId),
                const SizedBox(height: 24),
                // Shopping list header
                Row(
                  children: [
                    const Text(
                      'Shopping List',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF0D1512)),
                    ),
                    const Spacer(),
                    Text(
                      '$foundCount / $totalCount ITEMS FOUND',
                      style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700,
                        color: AppColors.primary, letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: const Color(0xFFD9DDD7),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
                const SizedBox(height: 14),
                // Items
                ...job.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _JobItemCard(orderId: job.orderId, item: item),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        // Bottom bar
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'ESTIMATED TOTAL',
                    style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary, letterSpacing: 0.6,
                    ),
                  ),
                  Text(
                    '₦${_fmt(job.estimatedTotal)}',
                    style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w900,
                      color: Color(0xFF0D1512),
                    ),
                  ),
                ],
              ),
              if (_finishError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _finishError!,
                  style: const TextStyle(fontSize: 12, color: Color(0xFFE53935)),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _finishing ? null : _finishShopping,
                  icon: _finishing
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                  label: Text(
                    _finishing ? 'Finishing...' : 'Finish Shopping',
                    style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StoreCard extends ConsumerWidget {
  const _StoreCard({required this.storeName, required this.storeAddress});
  final String storeName;
  final String storeAddress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Resolve photo from markets providers
    String? photoUrl;
    void resolve(List<MarketData> markets) {
      for (final m in markets) {
        if (m.name.toLowerCase() == storeName.toLowerCase() && m.photoUrl != null) {
          photoUrl = m.photoUrl;
          return;
        }
      }
    }
    ref.watch(supermarketsProvider).whenData(resolve);
    if (photoUrl == null) ref.watch(openMarketsProvider).whenData(resolve);

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 160,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (photoUrl != null)
                    Image.network(
                      photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFF2A3A28),
                        child: const Center(
                          child: Icon(Icons.storefront_rounded, color: Colors.white38, size: 56),
                        ),
                      ),
                    )
                  else
                    Container(
                      color: const Color(0xFF2A3A28),
                      child: const Center(
                        child: Icon(Icons.storefront_rounded, color: Colors.white38, size: 56),
                      ),
                    ),
                  // Gradient overlay so the badge is readable
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.45)],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'DESTINATION',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        storeName.isEmpty ? 'Store' : storeName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0D1512)),
                      ),
                      if (storeAddress.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          storeAddress,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF9A9C97)),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: const Color(0xFFE6F4EA), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 22),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerRow extends StatefulWidget {
  const _CustomerRow({required this.customerName, this.customerAvatarUrl, required this.deliveryAddress, required this.orderId});
  final String customerName;
  final String? customerAvatarUrl;
  final String deliveryAddress;
  final String orderId;

  @override
  State<_CustomerRow> createState() => _CustomerRowState();
}

class _CustomerRowState extends State<_CustomerRow> {
  late final DateTime _startTime;
  late final Stream<Duration> _elapsed;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _elapsed = Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now().difference(_startTime));
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFFE8EAE7),
            backgroundImage: widget.customerAvatarUrl != null
                ? NetworkImage(widget.customerAvatarUrl!)
                : null,
            child: widget.customerAvatarUrl == null
                ? const Icon(Icons.person_outline_rounded, color: Color(0xFF9A9C97), size: 22)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.customerName.isEmpty ? 'Customer' : widget.customerName,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0D1512)),
                ),
                if (widget.deliveryAddress.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    widget.deliveryAddress,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF9A9C97)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ChatScreen(
                        orderId: widget.orderId,
                        otherPersonName: widget.customerName,
                        otherPersonRole: 'CUSTOMER',
                        otherPersonAvatarUrl: widget.customerAvatarUrl,
                      ),
              ),
            ),
            child: Container(
              width: 38, height: 38,
              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              child: const Icon(Icons.chat_rounded, color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 10),
          StreamBuilder<Duration>(
            stream: _elapsed,
            initialData: Duration.zero,
            builder: (context, snap) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer_outlined, size: 14, color: AppColors.primary),
                const SizedBox(width: 3),
                Text(
                  _fmt(snap.data ?? Duration.zero),
                  style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _JobItemCard extends ConsumerWidget {
  const _JobItemCard({required this.orderId, required this.item});
  final String orderId;
  final ActiveJobItem item;

  String _fmt(double v) => v
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  String get _description {
    final parts = <String>[];
    if (item.description.isNotEmpty) parts.add(item.description);
    if (item.unit.isNotEmpty) parts.add('${item.quantity} ${item.unit}');
    return parts.join(' • ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFound = item.status == 1;
    final isUnavailable = item.status == 2;
    final isPending = !isFound && !isUnavailable;

    final borderColor = isFound
        ? AppColors.primary
        : isUnavailable
            ? const Color(0xFFE53935)
            : Colors.transparent;

    final displayPrice = isFound
        ? (item.foundPrice ?? item.estimatedPrice)
        : item.estimatedPrice;

    final priceLabel = isFound ? 'FOUND PRICE' : isPending ? 'ACTUAL PRICE' : 'EST. PRICE';
    final priceLabelColor = isFound ? AppColors.primary : const Color(0xFF9A9C97);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Coloured left accent bar
              if (isFound || isUnavailable)
                Container(width: 4, color: borderColor),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(isFound || isUnavailable ? 10 : 14, 14, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row: status icon + name/desc + price ──────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status indicator
                _StatusCircle(isFound: isFound, isUnavailable: isUnavailable),
                const SizedBox(width: 12),
                // Name + tags
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0D1512),
                        ),
                      ),
                      if (isUnavailable) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'UNAVAILABLE',
                            style: TextStyle(
                              fontSize: 10, fontWeight: FontWeight.w800,
                              color: Color(0xFFE53935), letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        _description,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF9A9C97)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Price column
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '₦',
                          style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700,
                            color: isFound ? const Color(0xFF0D1512) : const Color(0xFF0D1512),
                          ),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          _fmt(displayPrice),
                          style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0D1512),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      priceLabel,
                      style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w700,
                        color: priceLabelColor, letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // ── Bottom row: photo + action button ─────────────────────────
            if (isFound) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  // Thumbnail
                  if (item.photoUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        item.photoUrl!,
                        width: 44, height: 44,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _photoPlaceholder(),
                      ),
                    )
                  else
                    _photoPlaceholder(),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: () => showScanItemSheet(
                      context: context, ref: ref,
                      orderId: orderId, item: item,
                    ),
                    icon: const Icon(Icons.camera_alt_outlined, size: 15),
                    label: const Text('Retake Photo', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0D1512),
                      side: const BorderSide(color: Color(0xFFD0D3CF)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ] else if (isUnavailable) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => showScanItemSheet(
                    context: context, ref: ref,
                    orderId: orderId, item: item,
                  ),
                  icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                  label: const Text(
                    'SUGGEST REPLACEMENT',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.4),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0D1512),
                    side: const BorderSide(color: Color(0xFFD0D3CF)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => showScanItemSheet(
                    context: context, ref: ref,
                    orderId: orderId, item: item,
                  ),
                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 16, color: AppColors.primary),
                  label: const Text(
                    'SCAN ITEM',
                    style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700,
                      color: AppColors.primary, letterSpacing: 0.4,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _photoPlaceholder() {
    return Container(
      width: 44, height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0EE),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.image_outlined, color: Color(0xFF9A9C97), size: 22),
    );
  }
}

class _StatusCircle extends StatelessWidget {
  const _StatusCircle({required this.isFound, required this.isUnavailable});
  final bool isFound;
  final bool isUnavailable;

  @override
  Widget build(BuildContext context) {
    if (isFound) {
      return Container(
        width: 28, height: 28,
        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
        child: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
      );
    }
    if (isUnavailable) {
      return Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE53935), width: 2),
        ),
        child: const Icon(Icons.block_rounded, color: Color(0xFFE53935), size: 16),
      );
    }
    // Pending
    return Container(
      width: 28, height: 28,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFD0D3CF), width: 2),
      ),
    );
  }
}
