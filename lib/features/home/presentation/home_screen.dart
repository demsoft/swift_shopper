import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/home_models.dart';
import '../providers/home_provider.dart';
import '../../create_request/presentation/create_request_screen.dart';
import 'order_details_screen.dart';
import 'active_job_screen.dart';

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
                  recentRequestsAsync: recentRequestsAsync,
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
    final activeOrders = activeOrdersAsync.valueOrNull ?? const <ActiveOrder>[];
    final primaryOrder = activeOrders.isNotEmpty
        ? activeOrders.first
        : const ActiveOrder(
            orderId: '',
            title: 'Spar Supermarket',
            store: 'Order #SS-2940 • 3 Items',
            status: 'IN PROGRESS',
          );

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
        _CustomerOrderCard(
          order: primaryOrder,
          amountText: '₦8,400',
          onTap: () => onTrackOrder(primaryOrder),
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
class _ShopperHomeView extends StatelessWidget {
  const _ShopperHomeView({
    required this.firstName,
    required this.avatarUrl,
    required this.activeOrdersAsync,
    required this.recentRequestsAsync,
  });

  final String firstName;
  final String? avatarUrl;
  final AsyncValue<List<ActiveOrder>> activeOrdersAsync;
  final AsyncValue<List<RecentRequest>> recentRequestsAsync;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final requests = recentRequestsAsync.valueOrNull ?? const <RecentRequest>[];
    final requestCards = requests.take(2).toList().isEmpty
        ? const [
            RecentRequest(
              title: 'Prince Ebeano',
              date: 'Lekki Phase 1 • 1.2km',
              itemsCount: 8,
            ),
            RecentRequest(
              title: 'Spar Market',
              date: 'Victoria Island • 2.8km',
              itemsCount: 15,
            ),
          ]
        : requests.take(2).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _TopHeader(firstName: firstName, avatarUrl: avatarUrl),
        const SizedBox(height: 16),
        const _EarningsCard(),
        const SizedBox(height: 14),
        const _ShopperStatsRow(),
        const SizedBox(height: 24),
        Text(
          'Active Shopping',
          style: theme.textTheme.titleLarge?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        const _ActiveShoppingCard(),
        const SizedBox(height: 24),
        _SectionHeader(
          title: 'New Requests',
          action: 'See All',
          actionColor: AppColors.primary,
          onTap: () {},
        ),
        const SizedBox(height: 12),
        ...requestCards.map(
          (r) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _RequestCard(request: r),
          ),
        ),
      ],
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
  const _CustomerOrderCard({
    required this.order,
    required this.amountText,
    this.onTap,
  });

  final ActiveOrder order;
  final String amountText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                child: Image.asset(
                  'assets/images/order.png',
                  width: 76,
                  height: 76,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: AppColors.accentSurface,
                    ),
                    child: const Icon(
                      Icons.local_mall_rounded,
                      color: AppColors.primaryDark,
                      size: 36,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      order.store,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                amountText,
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
                'PICKING ITEMS',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              Text(
                order.status.toUpperCase(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: const LinearProgressIndicator(
              value: 0.65,
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
// Shopper: Active Shopping Card
// ---------------------------------------------------------------------------
class _ActiveShoppingCard extends StatelessWidget {
  const _ActiveShoppingCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
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
                  'Shoprite, Ikeja Mall',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'IN PROGRESS',
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
            'Order #SS-2940 • 12 items',
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
                '75%',
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
              value: 0.75,
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
                  builder: (_) => const ActiveJobScreen(),
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
    );
  }
}

// ---------------------------------------------------------------------------
// Shopper: Request Card
// ---------------------------------------------------------------------------
class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request});
  final RecentRequest request;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLarge = request.itemsCount > 10;
    final price = isLarge ? '₦5,150' : '₦3,400';
    final tag2 = isLarge ? 'HEAVY LOAD' : 'FAST TRACK';
    final image = isLarge
        ? 'assets/images/screen2.png'
        : 'assets/images/screen1.png';

    return Container(
      padding: const EdgeInsets.all(12),
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
        children: [
          // Store image with price badge
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                Image.asset(
                  image,
                  width: 110,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 110,
                    height: 100,
                    color: AppColors.accentSurface,
                    child: const Icon(
                      Icons.storefront_rounded,
                      color: AppColors.primaryDark,
                      size: 40,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    color: AppColors.warning,
                    child: Text(
                      price,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${request.date} away',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _PillLabel(label: '${request.itemsCount} ITEMS'),
                    _PillLabel(label: tag2),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Arrow button
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F2EF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textPrimary,
              size: 22,
            ),
          ),
        ],
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
