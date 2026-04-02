import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../chat/presentation/chat_screen.dart';
import '../models/home_models.dart';
import '../providers/home_provider.dart';

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
class _ActiveJobView extends StatelessWidget {
  const _ActiveJobView({required this.job});

  final ActiveJobData job;

  String _fmt(double v) => v
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  @override
  Widget build(BuildContext context) {
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
                _CustomerRow(customerName: job.customerName, deliveryAddress: job.deliveryAddress, orderId: job.orderId),
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
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 7,
                    backgroundColor: const Color(0xFFD9DDD7),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
                const SizedBox(height: 14),
                // Items
                ...job.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _JobItemCard(item: item),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        // Bottom bar
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'EST. TOTAL',
                      style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary, letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      '₦ ${_fmt(job.estimatedTotal)}',
                      style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w900,
                        color: Color(0xFF0D1512),
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(0, 50),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                ),
                child: const Text(
                  'FINISH SHOPPING',
                  style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w800,
                    color: Colors.white, letterSpacing: 0.3,
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

class _CustomerRow extends StatelessWidget {
  const _CustomerRow({required this.customerName, required this.deliveryAddress, required this.orderId});
  final String customerName;
  final String deliveryAddress;
  final String orderId;

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
          Container(
            width: 40, height: 40,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFE8EAE7)),
            child: const Icon(Icons.person_outline_rounded, color: Color(0xFF9A9C97), size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customerName.isEmpty ? 'Customer' : customerName,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0D1512)),
                ),
                if (deliveryAddress.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    deliveryAddress,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF9A9C97)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ChatScreen(shopperName: customerName, shopperRole: 'CUSTOMER'),
              ),
            ),
            child: Container(
              width: 38, height: 38,
              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              child: const Icon(Icons.chat_rounded, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _JobItemCard extends StatelessWidget {
  const _JobItemCard({required this.item});
  final ActiveJobItem item;

  String _fmt(double v) => v
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  @override
  Widget build(BuildContext context) {
    final isFound = item.status == 1;
    final isUnavailable = item.status == 2;
    final displayPrice = item.foundPrice ?? item.estimatedPrice;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          // Status icon / image
          Stack(
            clipBehavior: Clip.none,
            children: [
              item.photoUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        item.photoUrl!,
                        width: 58, height: 58,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _itemIconBox(isFound, isUnavailable),
                      ),
                    )
                  : _itemIconBox(isFound, isUnavailable),
              if (item.quantity > 1)
                Positioned(
                  top: -6, left: -6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${item.quantity}x',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0D1512)),
                ),
                const SizedBox(height: 2),
                Text(
                  item.unit.isNotEmpty ? item.unit : item.description,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF9A9C97)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₦ ${_fmt(displayPrice)}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0D1512)),
              ),
              const SizedBox(height: 4),
              _statusBadge(isFound, isUnavailable),
            ],
          ),
        ],
      ),
    );
  }

  Widget _itemIconBox(bool isFound, bool isUnavailable) {
    return Container(
      width: 58, height: 58,
      decoration: BoxDecoration(
        color: isFound
            ? const Color(0xFFE6F4EA)
            : isUnavailable
                ? const Color(0xFFFDECEC)
                : const Color(0xFFF0F0EE),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        isFound ? Icons.check_rounded : isUnavailable ? Icons.close_rounded : Icons.hourglass_empty_rounded,
        color: isFound ? AppColors.primary : isUnavailable ? AppColors.danger : AppColors.textSecondary,
        size: 26,
      ),
    );
  }

  Widget _statusBadge(bool isFound, bool isUnavailable) {
    final label = isFound ? 'FOUND' : isUnavailable ? 'N/A' : 'PENDING';
    final color = isFound ? AppColors.primary : isUnavailable ? AppColors.danger : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.3),
      ),
    );
  }
}
