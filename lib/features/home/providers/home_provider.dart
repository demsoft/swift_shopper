import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../auth/providers/auth_provider.dart';
import '../../shared/data/swift_shopper_repository.dart';
import '../models/home_models.dart';

final quickActionsProvider = Provider<List<QuickAction>>((ref) {
  return const [
    QuickAction(
      title: AppStrings.sendShopper,
      icon: Icons.delivery_dining_outlined,
    ),
    QuickAction(
      title: AppStrings.groceries,
      icon: Icons.shopping_basket_outlined,
    ),
    QuickAction(title: AppStrings.marketItems, icon: Icons.storefront_outlined),
  ];
});

final activeOrdersProvider = FutureProvider<List<ActiveOrder>>((ref) async {
  final repository = ref.read(swiftShopperRepositoryProvider);
  final authUser = ref.read(authProvider).user;
  final userId = authUser == null || authUser.isShopper ? null : authUser.userId;
  return repository.getActiveOrders(customerId: userId);
});

final recentRequestsProvider = FutureProvider<List<RecentRequest>>((ref) async {
  final repository = ref.read(swiftShopperRepositoryProvider);
  final authUser = ref.read(authProvider).user;
  final userId = authUser == null || authUser.isShopper ? null : authUser.userId;
  return repository.getRecentRequests(customerId: userId);
});

final activeJobProvider = FutureProvider<ActiveJobData?>((ref) async {
  final repository = ref.read(swiftShopperRepositoryProvider);
  return repository.getActiveJob();
});

final shopperOrderHistoryProvider = FutureProvider<List<ShopperOrderData>>((ref) async {
  final repository = ref.read(swiftShopperRepositoryProvider);
  return repository.getShopperOrderHistory();
});

final orderTrackingProvider =
    FutureProvider.family<OrderTrackingData?, String>((ref, orderId) async {
  return ref.read(swiftShopperRepositoryProvider).getOrderTracking(orderId: orderId);
});

final orderItemsProvider =
    FutureProvider.family<List<ActiveJobItem>, String>((ref, orderId) async {
  return ref.read(swiftShopperRepositoryProvider).getOrderItems(orderId: orderId);
});

final supermarketsProvider = FutureProvider<List<MarketData>>((ref) async {
  final repository = ref.read(swiftShopperRepositoryProvider);
  return repository.getMarkets(type: 'Supermarket');
});

final openMarketsProvider = FutureProvider<List<MarketData>>((ref) async {
  final repository = ref.read(swiftShopperRepositoryProvider);
  return repository.getMarkets(type: 'Local Open Market');
});
