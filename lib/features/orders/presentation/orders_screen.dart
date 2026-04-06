import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../home/models/home_models.dart';
import '../../home/presentation/active_job_screen.dart';
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
    final activeOrdersAsync = ref.watch(activeOrdersProvider);
    final recentRequestsAsync = ref.watch(recentRequestsProvider);

    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2EF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF0F2EF),
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'My Orders',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0D1512),
          ),
        ),
        centerTitle: true,
        leading: canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Color(0xFF0D1512), size: 20),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(activeOrdersProvider);
          ref.invalidate(recentRequestsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            const SizedBox(height: 8),

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
                          child: _RecentRequestCard(
                            request: request,
                            onTap: () {
                              if (request.orderId.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Order not yet assigned to a shopper.'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                                return;
                              }
                              final order = ActiveOrder(
                                orderId: request.orderId,
                                title: request.title,
                                store: request.store,
                                status: request.status,
                                estimatedItemsTotal: request.itemsSubtotal > 0
                                    ? request.itemsSubtotal
                                    : request.budget,
                                itemsSubtotal: request.itemsSubtotal,
                                deliveryFee: request.deliveryFee,
                                serviceFee: request.serviceFee,
                              );
                              Navigator.of(context).push(MaterialPageRoute<void>(
                                builder: (_) => OrderDetailsScreen(order: order),
                              ));
                            },
                          ),
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
                CircleAvatar(
                  radius: 23,
                  backgroundColor: const Color(0xFFE8EAE7),
                  backgroundImage: order.shopperAvatarUrl != null && order.shopperAvatarUrl!.isNotEmpty
                      ? NetworkImage(order.shopperAvatarUrl!)
                      : null,
                  child: order.shopperAvatarUrl == null || order.shopperAvatarUrl!.isEmpty
                      ? const Icon(
                          Icons.person_outline_rounded,
                          color: AppColors.textSecondary,
                          size: 22,
                        )
                      : null,
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
class _RecentRequestCard extends ConsumerWidget {
  const _RecentRequestCard({required this.request, required this.onTap});

  final RecentRequest request;
  final VoidCallback onTap;

  // Status label → badge colour pair
  static _StatusStyle _statusStyle(String status) {
    switch (status) {
      case 'Accepted':  return const _StatusStyle(Color(0xFFE8F5E9), Color(0xFF2E7D32));
      case 'Shopping':  return const _StatusStyle(Color(0xFFE3F2FD), Color(0xFF1565C0));
      case 'Ready':     return const _StatusStyle(Color(0xFFFFF8E1), Color(0xFFF57F17));
      case 'Delivering':return const _StatusStyle(Color(0xFFE8F5E9), AppColors.primary);
      case 'Delivered': return const _StatusStyle(Color(0xFFF5F5F5), Color(0xFF757575));
      case 'Cancelled': return const _StatusStyle(Color(0xFFFFEBEE), Color(0xFFC62828));
      default:          return const _StatusStyle(Color(0xFFE6F4EA), AppColors.primary); // Submitted / Pending
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // Resolve store photo: direct URL first, then match by name in loaded markets
    String? photoUrl = request.storePhotoUrl;
    if (photoUrl == null || photoUrl.isEmpty) {
      void tryMarkets(List<MarketData> markets) {
        for (final m in markets) {
          if (m.name.toLowerCase() == request.store.toLowerCase() &&
              m.photoUrl != null &&
              m.photoUrl!.isNotEmpty) {
            photoUrl = m.photoUrl;
            return;
          }
        }
      }
      ref.watch(supermarketsProvider).whenData(tryMarkets);
      if (photoUrl == null) ref.watch(openMarketsProvider).whenData(tryMarkets);
    }

    final style = _statusStyle(request.status);

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: photoUrl != null && photoUrl!.isNotEmpty
                  ? Image.network(
                      photoUrl!,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _fallbackIcon(),
                    )
                  : _fallbackIcon(),
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
                color: style.bg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                request.status.toUpperCase(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: style.fg,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackIcon() => Container(
        width: 56,
        height: 56,
        decoration: const BoxDecoration(color: Color(0xFFF0F2EF)),
        child: const Icon(Icons.shopping_bag_rounded,
            color: AppColors.textSecondary, size: 28),
      );
}

class _StatusStyle {
  const _StatusStyle(this.bg, this.fg);
  final Color bg;
  final Color fg;
}

// ===========================================================================
// SHOPPER ORDERS SCREEN
// ===========================================================================

class _ShopperOrderHistoryScreen extends ConsumerStatefulWidget {
  const _ShopperOrderHistoryScreen();

  @override
  ConsumerState<_ShopperOrderHistoryScreen> createState() =>
      _ShopperOrderHistoryScreenState();
}

class _ShopperOrderHistoryScreenState
    extends ConsumerState<_ShopperOrderHistoryScreen> {
  int _selectedTab = 0; // 0 = Active Jobs, 1 = Completed

  @override
  Widget build(BuildContext context) {
    final jobAsync = ref.watch(activeJobProvider);
    final historyAsync = ref.watch(shopperOrderHistoryProvider);

    // Resolve store photo for active job
    final supermarketsAsync = ref.watch(supermarketsProvider);
    final openMarketsAsync = ref.watch(openMarketsProvider);

    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'My Orders',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0D1512),
          ),
        ),
        centerTitle: true,
        leading: canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Color(0xFF0D1512), size: 20),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(activeJobProvider);
          ref.invalidate(shopperOrderHistoryProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            const SizedBox(height: 8),

              // ── Tab bar ──────────────────────────────────────────────
              _TabRow(
                selectedIndex: _selectedTab,
                onTabSelected: (i) => setState(() => _selectedTab = i),
              ),
              const SizedBox(height: 24),

              // ── Active Jobs tab ──────────────────────────────────────
              if (_selectedTab == 0) ...[
                const Text(
                  'CURRENT SESSION',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFE07B39),
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Active Job',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0D1512),
                  ),
                ),
                const SizedBox(height: 16),
                jobAsync.when(
                  loading: () => const _JobCardSkeleton(),
                  error: (_, __) => const _NoActiveJobCard(),
                  data: (job) {
                    if (job == null) return const _NoActiveJobCard();
                    String? photoUrl;
                    void resolvePhoto(List<MarketData> markets) {
                      for (final m in markets) {
                        if (m.name.toLowerCase() ==
                                job.storeName.toLowerCase() &&
                            m.photoUrl != null) {
                          photoUrl = m.photoUrl;
                          return;
                        }
                      }
                    }
                    supermarketsAsync.whenData(resolvePhoto);
                    if (photoUrl == null) openMarketsAsync.whenData(resolvePhoto);
                    return _ActiveJobCard(job: job, photoUrl: photoUrl);
                  },
                ),
                const SizedBox(height: 32),
              ],

              // ── Earnings history (both tabs) ─────────────────────────
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'EARNINGS HISTORY',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                            letterSpacing: 1.0,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Recent Deliveries',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0D1512),
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: const Text(
                      'View All',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              historyAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Text('$e',
                        style: const TextStyle(
                            color: AppColors.textSecondary)),
                  ),
                ),
                data: (orders) {
                  if (orders.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Text(
                          'No completed deliveries yet.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: orders
                        .map((o) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _DeliveryHistoryCard(order: o),
                            ))
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab row
// ---------------------------------------------------------------------------
class _TabRow extends StatelessWidget {
  const _TabRow({required this.selectedIndex, required this.onTabSelected});

  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _TabPill(
          label: 'Active Jobs',
          selected: selectedIndex == 0,
          onTap: () => onTabSelected(0),
        ),
        const SizedBox(width: 10),
        _TabPill(
          label: 'Completed',
          selected: selectedIndex == 1,
          onTap: () => onTabSelected(1),
        ),
      ],
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill(
      {required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : const Color(0xFFEEEEEE),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Active job card
// ---------------------------------------------------------------------------
class _ActiveJobCard extends StatelessWidget {
  const _ActiveJobCard({required this.job, this.photoUrl});

  final ActiveJobData job;
  final String? photoUrl;

  String _fmt(double v) =>
      '₦${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

  @override
  Widget build(BuildContext context) {
    final picked = job.pickedItemsCount;
    final total = job.totalItemsCount;
    final progress = total > 0 ? picked / total : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Store row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Store thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: photoUrl != null
                      ? Image.network(photoUrl!,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _storeIconBox())
                      : _storeIconBox(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.storeName,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0D1512),
                        ),
                      ),
                      if (job.storeAddress.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          job.storeAddress,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 2,
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
                      _fmt(job.estimatedTotal),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFE07B39),
                      ),
                    ),
                    const Text(
                      'EST. EARNINGS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Timer + items row
            Row(
              children: [
                const Icon(Icons.timer_outlined,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                const Text(
                  'In progress',
                  style: TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
                const Spacer(),
                Text(
                  '$picked/$total items picked',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                color: AppColors.primary,
                backgroundColor: const Color(0xFFE0E0E0),
              ),
            ),
            const SizedBox(height: 16),

            // Continue button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ActiveJobScreen(initialJob: job),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Continue Shopping',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _storeIconBox() => Container(
        width: 60,
        height: 60,
        color: const Color(0xFFE8F5E9),
        child: const Icon(Icons.storefront_rounded,
            color: AppColors.primary, size: 28),
      );
}

// ---------------------------------------------------------------------------
// No active job card
// ---------------------------------------------------------------------------
class _NoActiveJobCard extends StatelessWidget {
  const _NoActiveJobCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(Icons.work_off_outlined,
              size: 40,
              color: AppColors.textSecondary.withValues(alpha: 0.4)),
          const SizedBox(height: 10),
          const Text(
            'No active job',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Accept a request from the Home tab.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Job card skeleton (loading)
// ---------------------------------------------------------------------------
class _JobCardSkeleton extends StatelessWidget {
  const _JobCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Delivery history card
// ---------------------------------------------------------------------------
class _DeliveryHistoryCard extends ConsumerWidget {
  const _DeliveryHistoryCard({required this.order});

  final ShopperOrderData order;

  String _fmt(double v) =>
      '₦${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDelivered = order.status == 5;
    final statusLabel = isDelivered ? 'DELIVERED' : 'COMPLETED';

    // Resolve store photo from loaded markets
    String? photoUrl;
    void tryMarkets(List<MarketData> markets) {
      for (final m in markets) {
        if (m.name.toLowerCase() == order.storeName.toLowerCase() &&
            m.photoUrl != null &&
            m.photoUrl!.isNotEmpty) {
          photoUrl = m.photoUrl;
          return;
        }
      }
    }
    ref.watch(supermarketsProvider).whenData(tryMarkets);
    if (photoUrl == null) ref.watch(openMarketsProvider).whenData(tryMarkets);

    return Container(
      padding: const EdgeInsets.all(14),
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
          // Store thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: photoUrl != null
                ? Image.network(
                    photoUrl!,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _fallbackIcon(),
                  )
                : _fallbackIcon(),
          ),
          const SizedBox(width: 12),

          // Store name + date + items
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.storeName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0D1512),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${order.completedAt}  •  ${order.itemsCount} Items',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Amount + status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _fmt(order.earningsAmount),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0D1512),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.circle,
                      size: 8, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    statusLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fallbackIcon() => Container(
        width: 56,
        height: 56,
        decoration: const BoxDecoration(color: Color(0xFFEEEEEE)),
        child: const Icon(Icons.storefront_rounded,
            color: AppColors.textSecondary, size: 26),
      );
}
