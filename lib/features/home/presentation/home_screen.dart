import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/home_models.dart';
import '../providers/home_provider.dart';
import '../../create_request/presentation/create_request_screen.dart';
import 'order_details_screen.dart';
import 'active_job_screen.dart';
import 'request_detail_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final isShopper = user?.isShopper ?? false;
    final firstName = _firstName(user?.fullName);
    final avatarUrl = user?.avatarUrl;
    final activeOrdersAsync = ref.watch(activeOrdersProvider);
    final recentRequestsAsync = ref.watch(recentRequestsProvider);
    final supermarketsAsync = ref.watch(supermarketsProvider);
    final openMarketsAsync = ref.watch(openMarketsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2EF),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(activeOrdersProvider);
            ref.invalidate(recentRequestsProvider);
            ref.invalidate(supermarketsProvider);
            ref.invalidate(openMarketsProvider);
          },
          child: isShopper
              ? _ShopperHomeView(
                  firstName: firstName,
                  avatarUrl: avatarUrl,
                  activeOrdersAsync: activeOrdersAsync,
                )
              : _CustomerHomeView(
                  firstName: firstName,
                  avatarUrl: avatarUrl,
                  activeOrdersAsync: activeOrdersAsync,
                  recentRequestsAsync: recentRequestsAsync,
                  supermarketsAsync: supermarketsAsync,
                  openMarketsAsync: openMarketsAsync,
                  onTrackOrder: (order) {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => OrderDetailsScreen(order: order),
                      ),
                    );
                  },
                  onCreateRequest: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const CreateRequestScreen(),
                      ),
                    );
                  },
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

// ===========================================================================
// CUSTOMER HOME VIEW
// ===========================================================================
class _CustomerHomeView extends StatelessWidget {
  const _CustomerHomeView({
    required this.firstName,
    required this.avatarUrl,
    required this.activeOrdersAsync,
    required this.recentRequestsAsync,
    required this.supermarketsAsync,
    required this.openMarketsAsync,
    required this.onTrackOrder,
    required this.onCreateRequest,
  });

  final String firstName;
  final String? avatarUrl;
  final AsyncValue<List<ActiveOrder>> activeOrdersAsync;
  final AsyncValue<List<RecentRequest>> recentRequestsAsync;
  final AsyncValue<List<MarketData>> supermarketsAsync;
  final AsyncValue<List<MarketData>> openMarketsAsync;
  final ValueChanged<ActiveOrder> onTrackOrder;
  final VoidCallback onCreateRequest;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _TopHeader(firstName: firstName, avatarUrl: avatarUrl),
        const SizedBox(height: 16),
        _BalanceCard(onCreateRequest: onCreateRequest),
        const SizedBox(height: 14),
        _NewRequestBanner(onTap: onCreateRequest),
        const SizedBox(height: 24),
        _SectionHeader(
          title: 'Active Orders',
          action: 'Track All',
          actionColor: AppColors.primary,
          onTap: () {},
        ),
        const SizedBox(height: 12),
        activeOrdersAsync.when(
          loading: () => const _OrderCardSkeleton(),
          error: (_, __) => const _OrderCardEmpty(),
          data: (orders) {
            if (orders.isEmpty) return const _OrderCardEmpty();
            final latest = orders.first;
            return _CustomerOrderCard(
              order: latest,
              onTap: () => onTrackOrder(latest),
            );
          },
        ),
        const SizedBox(height: 24),
        _SectionHeader(
          title: 'Supermarkets',
          action: 'SEE ALL',
          actionColor: AppColors.warning,
          onTap: () {},
        ),
        const SizedBox(height: 14),
        _MarketHorizontalList(marketsAsync: supermarketsAsync),
        const SizedBox(height: 24),
        _SectionHeader(
          title: 'Popular Markets',
          action: 'SEE ALL',
          actionColor: AppColors.warning,
          onTap: () {},
        ),
        const SizedBox(height: 12),
        _MarketVerticalList(marketsAsync: openMarketsAsync),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ===========================================================================
// SHOPPER HOME VIEW
// ===========================================================================
class _ShopperHomeView extends ConsumerWidget {
  const _ShopperHomeView({
    required this.firstName,
    required this.avatarUrl,
    required this.activeOrdersAsync,
  });

  final String firstName;
  final String? avatarUrl;
  final AsyncValue<List<ActiveOrder>> activeOrdersAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availableAsync = ref.watch(availableRequestsProvider);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        ref.invalidate(availableRequestsProvider);
        ref.invalidate(activeJobProvider);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _TopHeader(firstName: firstName, avatarUrl: avatarUrl),
          const SizedBox(height: 16),
          const _EarningsCard(),
          const SizedBox(height: 14),
          const _ShopperStatsRow(),
          const SizedBox(height: 24),
          const _ActiveShoppingSection(),
          const SizedBox(height: 24),
          _SectionHeader(
            title: 'New Requests',
            action: 'See All',
            actionColor: AppColors.primary,
            onTap: () {},
          ),
          const SizedBox(height: 12),
          availableAsync.when(
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
                    onPressed: () => ref.invalidate(availableRequestsProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            data: (requests) {
              if (requests.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.inbox_rounded,
                          size: 40,
                          color: AppColors.textSecondary.withValues(alpha: 0.4)),
                      const SizedBox(height: 10),
                      const Text(
                        'No new requests right now.\nCheck back soon!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 14),
                      ),
                    ],
                  ),
                );
              }
              return Column(
                children: requests
                    .map((r) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _RequestCard(
                    request: r,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => RequestDetailScreen(request: r),
                      ),
                    ),
                  ),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// SHARED WIDGETS
// ===========================================================================

class _TopHeader extends StatelessWidget {
  const _TopHeader({required this.firstName, this.avatarUrl});
  final String firstName;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primaryDark,
          ),
          clipBehavior: Clip.antiAlias,
          child: avatarUrl != null && avatarUrl!.isNotEmpty
              ? Image.network(
                  avatarUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 26,
                  ),
                )
              : Image.asset(
                  'assets/images/account.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            firstName,
            style: theme.textTheme.titleLarge?.copyWith(
              color: AppColors.primaryDark,
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
            size: 22,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Customer: Balance Card
// ---------------------------------------------------------------------------
class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.onCreateRequest});
  final VoidCallback onCreateRequest;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E35), AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.30),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'AVAILABLE BALANCE',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {},
                child: Text(
                  'History',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '₦14,250.00',
            style: theme.textTheme.headlineLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 36,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onCreateRequest,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryDark,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 15,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Top Up',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Icon(
                  Icons.payments_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Customer: New Request Banner
// ---------------------------------------------------------------------------
class _NewRequestBanner extends StatelessWidget {
  const _NewRequestBanner({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0D2B1E), Color(0xFF1A3D2B)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_cart_checkout_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'New Shopping Request',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Request a personal shopper now',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white,
              size: 26,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Customer: Active Order Card
// ---------------------------------------------------------------------------
class _CustomerOrderCard extends StatelessWidget {
  const _CustomerOrderCard({required this.order, this.onTap});

  final ActiveOrder order;
  final VoidCallback? onTap;

  String _fmtTotal(double v) => '₦${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = order.totalItemsCount > 0
        ? order.pickedItemsCount / order.totalItemsCount
        : 0.0;
    final photoUrl = order.storePhotoUrl;

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
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 76,
                    height: 76,
                    child: photoUrl != null && photoUrl.isNotEmpty
                        ? Image.network(
                            photoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholder(),
                          )
                        : _placeholder(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.title.isNotEmpty ? order.title : 'Order',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        order.orderId,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (order.total > 0)
                  Text(
                    _fmtTotal(order.total),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  order.status.toUpperCase(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
                const Spacer(),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
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

  Widget _placeholder() => Container(
        color: AppColors.accentSurface,
        child: const Icon(Icons.local_mall_rounded,
            color: AppColors.primaryDark, size: 36),
      );
}

// ---------------------------------------------------------------------------
// Active order skeleton (loading state)
// ---------------------------------------------------------------------------
class _OrderCardSkeleton extends StatelessWidget {
  const _OrderCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Center(
        child: CircularProgressIndicator(
            color: AppColors.primary, strokeWidth: 2),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// No active orders state
// ---------------------------------------------------------------------------
class _OrderCardEmpty extends StatelessWidget {
  const _OrderCardEmpty();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(Icons.shopping_cart_outlined,
              size: 36,
              color: AppColors.textSecondary.withValues(alpha: 0.4)),
          const SizedBox(height: 8),
          const Text(
            'No active orders',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Customer: Supermarkets horizontal scroll
// ---------------------------------------------------------------------------
class _MarketHorizontalList extends StatelessWidget {
  const _MarketHorizontalList({required this.marketsAsync});
  final AsyncValue<List<MarketData>> marketsAsync;

  @override
  Widget build(BuildContext context) {
    return marketsAsync.when(
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)),
      ),
      error: (_, __) => const SizedBox(
        height: 60,
        child: Center(child: Text('Could not load', style: TextStyle(color: AppColors.textSecondary))),
      ),
      data: (markets) {
        if (markets.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: markets.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (_, i) => _MarketHorizontalCard(market: markets[i]),
          ),
        );
      },
    );
  }
}

class _MarketHorizontalCard extends StatelessWidget {
  const _MarketHorizontalCard({required this.market});
  final MarketData market;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: market.photoUrl != null && market.photoUrl!.isNotEmpty
                  ? Image.network(market.photoUrl!, fit: BoxFit.cover, width: double.infinity,
                      errorBuilder: (_, __, ___) => _MarketImagePlaceholder())
                  : _MarketImagePlaceholder(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(market.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                        color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('Open ${market.openingTime} – ${market.closingTime}',
                    style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Customer: Open markets vertical list
// ---------------------------------------------------------------------------
class _MarketVerticalList extends StatelessWidget {
  const _MarketVerticalList({required this.marketsAsync});
  final AsyncValue<List<MarketData>> marketsAsync;

  @override
  Widget build(BuildContext context) {
    return marketsAsync.when(
      loading: () => const SizedBox(
        height: 60,
        child: Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (markets) {
        if (markets.isEmpty) return const SizedBox.shrink();
        return Column(
          children: markets
              .map((m) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _MarketVerticalCard(market: m),
                  ))
              .toList(),
        );
      },
    );
  }
}

class _MarketVerticalCard extends StatelessWidget {
  const _MarketVerticalCard({required this.market});
  final MarketData market;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          ClipOval(
            child: SizedBox(
              width: 72,
              height: 72,
              child: market.photoUrl != null && market.photoUrl!.isNotEmpty
                  ? Image.network(market.photoUrl!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _MarketImagePlaceholder())
                  : _MarketImagePlaceholder(),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(market.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(market.address, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                if (market.categories.isNotEmpty)
                  Text(market.categories.take(2).join(' • '),
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.primary, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MarketImagePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        color: AppColors.accentSurface,
        child: const Icon(Icons.storefront_rounded, color: AppColors.primaryDark, size: 32),
      );
}

// ---------------------------------------------------------------------------
// Shopper: Earnings Card
// ---------------------------------------------------------------------------
class _EarningsCard extends StatelessWidget {
  const _EarningsCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E35), AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "TODAY'S EARNINGS",
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.75),
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '₦ 14,250.00',
            style: theme.textTheme.displayMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 40,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shopper: Stats Row
// ---------------------------------------------------------------------------
class _ShopperStatsRow extends StatelessWidget {
  const _ShopperStatsRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _MetricCard(
            icon: Icons.star_rounded,
            iconColor: AppColors.warning,
            label: 'RATING',
            value: '4.9',
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _MetricCard(
            icon: Icons.local_shipping_rounded,
            iconColor: AppColors.primary,
            label: 'TRIPS',
            value: '1,240',
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _MetricCard(
            icon: Icons.access_time_filled_rounded,
            iconColor: AppColors.primary,
            label: 'ON-TIME',
            value: '98%',
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 14),
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
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 26),
          const SizedBox(height: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shopper: Active Shopping Section (live from API)
// ---------------------------------------------------------------------------
class _ActiveShoppingSection extends ConsumerWidget {
  const _ActiveShoppingSection();

  static String _statusLabel(int status) {
    switch (status) {
      case 1: return 'ACCEPTED';
      case 2: return 'SHOPPING';
      case 3: return 'PURCHASED';
      case 4: return 'ON THE WAY';
      default: return 'IN PROGRESS';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobAsync = ref.watch(activeJobProvider);
    final theme = Theme.of(context);

    return jobAsync.when(
      loading: () => const SizedBox(
        height: 160,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (job) {
        if (job == null) return const SizedBox.shrink();

        final picked = job.pickedItemsCount;
        final total = job.totalItemsCount;
        final progress = total > 0 ? picked / total : 0.0;
        final pct = (progress * 100).round();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Active Shopping',
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ActiveJobScreen(initialJob: job),
                ),
              ),
              child: Container(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2820),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          job.storeName,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _statusLabel(job.status),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Order #${job.orderId.length > 8 ? job.orderId.substring(0, 8).toUpperCase() : job.orderId} • $total items',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.65),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        'Progress',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$picked / $total items  ($pct%)',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      color: AppColors.primary,
                      backgroundColor: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ActiveJobScreen(initialJob: job),
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: Text(
                        'Return to Job',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Shopper: Request Card
// ---------------------------------------------------------------------------
class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request, this.onTap});
  final AvailableRequestData request;
  final VoidCallback? onTap;

  String _fmtBudget(double v) =>
      '₦${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = request.itemNames.take(3).join(', ');

    return GestureDetector(
      onTap: onTap,
      child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon box
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.accentSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.storefront_rounded,
              color: AppColors.primaryDark,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.preferredStore,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  request.deliveryAddress,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (preview.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _PillLabel(label: '${request.itemsCount} ITEMS'),
                    _PillLabel(label: request.marketType.toUpperCase()),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Budget + arrow
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (request.budget > 0)
                Text(
                  _fmtBudget(request.budget),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              const SizedBox(height: 8),
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: Color(0xFFF0F2EF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textPrimary,
                  size: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }
}

class _PillLabel extends StatelessWidget {
  const _PillLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2EF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared: Section Header
// ---------------------------------------------------------------------------
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.action,
    required this.actionColor,
    required this.onTap,
  });

  final String title;
  final String action;
  final Color actionColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Text(
            action,
            style: theme.textTheme.titleSmall?.copyWith(
              color: actionColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
