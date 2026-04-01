import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../../shared/data/swift_shopper_repository.dart';
import '../models/request_item.dart';

enum MarketType { supermarket, openMarket }

class CreateRequestState {
  const CreateRequestState({
    required this.items,
    required this.marketType,
    required this.isFlexible,
    required this.isSubmitting,
  });

  final List<RequestItem> items;
  final MarketType marketType;
  final bool isFlexible;
  final bool isSubmitting;

  double get itemsTotal =>
      items.fold(0.0, (sum, item) => sum + item.subtotal);

  CreateRequestState copyWith({
    List<RequestItem>? items,
    MarketType? marketType,
    bool? isFlexible,
    bool? isSubmitting,
  }) {
    return CreateRequestState(
      items: items ?? this.items,
      marketType: marketType ?? this.marketType,
      isFlexible: isFlexible ?? this.isFlexible,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

class CreateRequestNotifier extends Notifier<CreateRequestState> {
  @override
  CreateRequestState build() {
    return const CreateRequestState(
      items: [],
      marketType: MarketType.supermarket,
      isFlexible: true,
      isSubmitting: false,
    );
  }

  void addItemWithDetails({
    required String name,
    required String unit,
    required String description,
    required double price,
  }) {
    final nextId = DateTime.now().millisecondsSinceEpoch.toString();
    state = state.copyWith(
      items: [
        ...state.items,
        RequestItem(
          id: nextId,
          name: name,
          unit: unit,
          description: description,
          price: price,
        ),
      ],
    );
  }

  void removeItem(String id) {
    state = state.copyWith(
      items: state.items.where((item) => item.id != id).toList(),
    );
  }

  void incrementQuantity(String id) {
    state = state.copyWith(
      items: state.items
          .map(
            (item) =>
                item.id == id ? item.copyWith(quantity: item.quantity + 1) : item,
          )
          .toList(),
    );
  }

  void decrementQuantity(String id) {
    state = state.copyWith(
      items: state.items
          .map(
            (item) => item.id == id && item.quantity > 1
                ? item.copyWith(quantity: item.quantity - 1)
                : item,
          )
          .toList(),
    );
  }

  void setMarketType(MarketType type) {
    state = state.copyWith(marketType: type);
  }

  void toggleFlexible(bool value) {
    state = state.copyWith(isFlexible: value);
  }

  Future<bool> submitRequest({
    required String preferredStore,
    required double budget,
    required String deliveryAddress,
    String? deliveryNotes,
  }) async {
    final cleanItems =
        state.items.where((item) => item.name.trim().isNotEmpty).toList();
    if (cleanItems.isEmpty) return false;

    state = state.copyWith(isSubmitting: true);

    try {
      final repository = ref.read(swiftShopperRepositoryProvider);
      final authUser = ref.read(authProvider).user;
      final userId =
          authUser == null || authUser.isShopper ? null : authUser.userId;
      await repository.createRequest(
        items: cleanItems,
        preferredStore: preferredStore,
        isFixedStore: state.marketType == MarketType.supermarket,
        marketType: state.marketType == MarketType.supermarket ? 'Supermarket' : 'OpenMarket',
        budget: budget,
        deliveryAddress: deliveryAddress,
        deliveryNotes: deliveryNotes,
        customerId: userId,
      );

      state = const CreateRequestState(
        items: [],
        marketType: MarketType.supermarket,
        isFlexible: true,
        isSubmitting: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false);
      rethrow;
    }
  }
}

final createRequestProvider =
    NotifierProvider<CreateRequestNotifier, CreateRequestState>(
      CreateRequestNotifier.new,
    );
