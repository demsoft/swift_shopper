import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../home/models/home_models.dart';
import '../../home/presentation/order_details_screen.dart';
import '../../home/providers/home_provider.dart';

// ignore_for_file: unused_element

// ===========================================================================
// Entry point – routes to the correct view based on role
// ===========================================================================
class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    if (user?.isShopper == true) {
      return const _ShopperOrderHistoryScreen();
    }
    return const _CustomerOrdersScreen();
  }
}

// ===========================================================================
// CUSTOMER ORDERS SCREEN
// ===========================================================================
class _CustomerOrdersScreen extends ConsumerWidget {
  const _CustomerOrdersScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authProvider).user;
    final activeOrdersAsync = ref.watch(activeOrdersProvider);
    final recentRequestsAsync = ref.watch(recentRequestsProvider);

    final firstName = _firstName(user?.fullName);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2EF),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(activeOrdersProvider);
            ref.invalidate(recentRequestsProvider);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              // ── Header ──────────────────────────────────────────────
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty
                        ? Image.network(
                            user.avatarUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.person, color: Colors.white, size: 24),
                          )
                        : const Icon(Icons.person, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      firstName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.notifications_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // ── Active Orders ────────────────────────────────────────
              activeOrdersAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
                error: (e, _) => _SectionError(
                  label: 'Active Orders',
                  message: e.toString(),
                  onRetry: () => ref.invalidate(activeOrdersProvider),
                ),
                data: (activeOrders) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Active Orders',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (activeOrders.isNotEmpty)
                            Text(
                              '${activeOrders.length} LIVE',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (activeOrders.isEmpty)
                        _EmptyState(
                          icon: Icons.shopping_cart_outlined,
                          message: 'No active orders right now.',
                        )
                      else
                        ...activeOrders.map((order) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ActiveOrderCard(
                            order: order,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => OrderDetailsScreen(order: order),
                              ),
                            ),
                          ),
                        )),
                    ],
                  );
                },
              ),
              const SizedBox(height: 28),

              // ── Recent Requests / Order History ──────────────────────
              recentRequestsAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
                error: (e, _) => _SectionError(
                  label: 'Recent Requests',
                  message: e.toString(),
                  onRetry: () => ref.invalidate(recentRequestsProvider),
                ),
                data: (requests) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recent Requests',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (requests.isEmpty)
                        _EmptyState(
                          icon: Icons.receipt_long_outlined,
                          message: 'No requests yet.\nSubmit your first shopping request!',
                        )
                      else
                        ...requests.map((request) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _RecentRequestCard(request: request),
                        )),
                    ],
                  );
                },
              ),
              const SizedBox(height: 8),

              // ── Support card ─────────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_long_rounded,
                      size: 38,
                      color: AppColors.textSecondary.withValues(alpha: 0.35),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Need help with a previous order?',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () {},
                      child: Text(
                        'Contact Support',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _firstName(String? fullName) {
    final value = (fullName ?? '').trim();
    if (value.isEmpty) return 'User';
    return value.split(RegExp(r'\s+')).first;
  }
}

// ---------------------------------------------------------------------------
// Section error widget
// ---------------------------------------------------------------------------
class _SectionError extends StatelessWidget {
  const _SectionError({required this.label, required this.message, required this.onRetry});
  final String label;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Container(
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
                child: Text(
                  message,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ),
              TextButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state widget
// ---------------------------------------------------------------------------
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: AppColors.textSecondary.withValues(alpha: 0.35)),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Customer – Active Order Card
// ---------------------------------------------------------------------------
class _ActiveOrderCard extends StatelessWidget {
  const _ActiveOrderCard({required this.order, this.onTap});

  final ActiveOrder order;
  final VoidCallback? onTap;

  static double _statusProgress(String status) {
    switch (status.toLowerCase()) {
      case 'accepted': return 0.2;
      case 'shopping': return 0.45;
      case 'purchased': return 0.7;
      case 'on the way': return 0.85;
      case 'delivered': return 1.0;
      default: return 0.05; // pending
    }
  }

  static String _progressLabel(String status) {
    switch (status.toLowerCase()) {
      case 'accepted': return 'SHOPPER ASSIGNED';
      case 'shopping': return 'SHOPPING IN PROGRESS';
      case 'purchased': return 'ITEMS PURCHASED';
      case 'on the way': return 'ON THE WAY';
      case 'delivered': return 'DELIVERED';
      default: return 'FINDING A SHOPPER';
    }
  }

  String _fmtTotal(double v) =>
      '₦${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = order.status;
    final progress = _statusProgress(status);
    final progressLabel = _progressLabel(status);
    final shopperLabel = order.shopperName.isNotEmpty ? order.shopperName : 'Pending';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order ID + status badge
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ORDER ID',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          letterSpacing: 1.4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        order.orderId.startsWith('#') ? order.orderId : '#${order.orderId}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F4EA),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.circle, size: 8, color: AppColors.primary),
                      const SizedBox(width: 5),
                      Text(
                        status.toUpperCase(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.primaryDark,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            // Shopper + Total row
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8EAE7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_outline_rounded,
                    color: AppColors.textSecondary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SHOPPER',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        shopperLabel,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (order.total > 0) ...[
                  Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryDark,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.receipt_outlined,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOTAL',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        _fmtTotal(order.total),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            // Progress
            Row(
              children: [
                Expanded(
                  child: Text(
                    progressLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      letterSpacing: 1.3,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                color: AppColors.primary,
                backgroundColor: AppColors.border,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Customer – Recent Request Card
// ---------------------------------------------------------------------------
class _RecentRequestCard extends StatelessWidget {
  const _RecentRequestCard({required this.request});

  final RecentRequest request;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F2EF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.shopping_bag_rounded, color: AppColors.textSecondary, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${request.date} • ${request.itemsCount} item${request.itemsCount == 1 ? '' : 's'}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFE6F4EA),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'SUBMITTED',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 10,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// SHOPPER ORDER HISTORY SCREEN  (live data)
// ===========================================================================

class _ShopperOrderHistoryScreen extends ConsumerWidget {
  const _ShopperOrderHistoryScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(shopperOrderHistoryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F1),
      body: SafeArea(
        child: Column(
          children: [
            _ShopperHeader(),
            Expanded(
              child: historyAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (e, _) => Center(
                  child: Text('$e', style: const TextStyle(color: AppColors.textSecondary)),
                ),
                data: (orders) => ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  children: [
                    const SizedBox(height: 16),
                    const _EarningsBanner(),
                    const SizedBox(height: 24),
                    _SectionHeader(),
                    const SizedBox(height: 12),
                    if (orders.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Text(
                            'No orders yet.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      )
                    else
                      ...orders.map(
                        (order) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ShopperOrderCard(order: order),
                        ),
                      ),
                    const SizedBox(height: 8),
                    const _EndOfHistoryCard(),
                    const SizedBox(height: 8),
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

class _ShopperHeader extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authProvider).user;
    final fullName = (user?.fullName ?? '').trim();
    final firstName = fullName.isEmpty
        ? 'User'
        : fullName.split(RegExp(r'\s+')).first;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.accentSoft.withValues(alpha: 0.35),
              shape: BoxShape.circle,
            ),
            clipBehavior: Clip.antiAlias,
            child: user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty
                ? Image.network(
                    user.avatarUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.person, color: AppColors.primaryDark),
                  )
                : const Icon(Icons.person, color: AppColors.primaryDark),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              firstName,
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.filter_list_rounded),
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}

class _EarningsBanner extends StatelessWidget {
  const _EarningsBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TOTAL SHOPPING EARNINGS',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.75),
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '₦142,800',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 34,
                ),
              ),
            ],
          ),
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_basket_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            'Recent Shopping\nJobs',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFD6EDD9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'OCTOBER\n2023',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _ShopperOrderCard extends StatelessWidget {
  const _ShopperOrderCard({required this.order});

  final ShopperOrderData order;

  String _fmtAmount(double v) => '₦${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCancelled = order.isCancelled;

    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isCancelled ? const Color(0xFFEEEEEE) : const Color(0xFFD6EDD9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.storefront_rounded,
              size: 20,
              color: isCancelled ? AppColors.textSecondary : AppColors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${order.completedAt} • ${order.storeName.toUpperCase()}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  order.customerName,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (isCancelled) ...[
                  const SizedBox(height: 4),
                  const Text(
                    'Order cancelled',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isCancelled ? const Color(0xFFFDECEC) : const Color(0xFFD6EDD9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isCancelled ? 'CANCELLED' : 'COMPLETED',
                  style: TextStyle(
                    color: isCancelled ? AppColors.danger : AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isCancelled ? '—' : _fmtAmount(order.earningsAmount),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: isCancelled ? AppColors.textPrimary : AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// _ItemAvatars kept as dead code placeholder to avoid churn; suppress lint above.
class _ItemAvatars extends StatelessWidget {
  const _ItemAvatars({required this.colors, required this.extra});

  final List<Color> colors;
  final int extra;

  @override
  Widget build(BuildContext context) {
    const size = 30.0;
    const overlap = 10.0;

    final displayed = colors.take(3).toList();
    final totalWidth =
        displayed.isEmpty
            ? 0.0
            : size + (displayed.length - 1) * (size - overlap);

    return SizedBox(
      height: size,
      width: totalWidth + (extra > 0 ? 36 : 0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ...List.generate(displayed.length, (i) {
            return Positioned(
              left: i * (size - overlap),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: displayed[i],
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            );
          }),
          if (extra > 0)
            Positioned(
              left: displayed.length * (size - overlap),
              child: Container(
                height: size,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEEEEE),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  '+$extra',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EndOfHistoryCard extends StatelessWidget {
  const _EndOfHistoryCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        const SizedBox(height: 8),
        Icon(
          Icons.shopping_basket_outlined,
          size: 40,
          color: AppColors.textSecondary.withValues(alpha: 0.35),
        ),
        const SizedBox(height: 12),
        Text(
          'End of recent history',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Keep shopping to unlock Gold Tier rewards.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {},
          child: Text(
            'ARCHIVE',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}
