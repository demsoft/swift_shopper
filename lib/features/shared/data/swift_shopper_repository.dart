import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_env.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/network_providers.dart';
import '../../chat/models/chat_message.dart';
import '../../auth/models/auth_user.dart';
import '../../auth/models/signup_otp_challenge.dart';
import '../../create_request/models/request_item.dart';
import '../../home/models/home_models.dart';

// OrderStatus int → human-readable label
const _statusLabels = {
  0: 'Pending',
  1: 'Accepted',
  2: 'Shopping',
  3: 'Purchased',
  4: 'On The Way',
  5: 'Delivered',
  6: 'Cancelled',
};

class SwiftShopperRepository {
  SwiftShopperRepository({required this.apiClient});

  final ApiClient apiClient;

  // ── Auth ──────────────────────────────────────────────────────────────────

  Future<AuthUser> login({
    required String emailOrPhone,
    required String password,
  }) async {
    final data = await apiClient.post('/api/auth/login', {
      'emailOrPhoneNumber': emailOrPhone,
      'password': password,
    });

    if (data is! Map<String, dynamic>) {
      throw ApiException('Invalid login response');
    }

    final user = AuthUser.fromJson(data);
    if (user.accessToken == null || user.accessToken!.isEmpty) {
      throw ApiException('Missing access token in login response');
    }

    return user;
  }

  Future<SignupOtpChallenge> register({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    required bool asShopper,
  }) async {
    final path =
        asShopper ? '/api/auth/register/shopper' : '/api/auth/register/customer';

    final data = await apiClient.post(path, {
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'password': password,
    });

    if (data is! Map<String, dynamic>) {
      throw ApiException('Invalid registration response');
    }

    final challenge = SignupOtpChallenge.fromJson(data);
    if (challenge.userId.isEmpty) {
      throw ApiException('Invalid OTP challenge response');
    }

    return challenge;
  }

  Future<AuthUser> verifySignupOtp({
    required String userId,
    required String otpCode,
  }) async {
    final data = await apiClient.post('/api/auth/verify-otp', {
      'userId': userId,
      'otpCode': otpCode,
    });

    if (data is! Map<String, dynamic>) {
      throw ApiException('Invalid OTP verification response');
    }

    final user = AuthUser.fromJson(data);
    if (user.accessToken == null || user.accessToken!.isEmpty) {
      throw ApiException('Missing access token in OTP verification response');
    }

    return user;
  }

  Future<SignupOtpChallenge> resendSignupOtp({required String userId}) async {
    final data = await apiClient.post('/api/auth/resend-otp', {'userId': userId});

    if (data is! Map<String, dynamic>) {
      throw ApiException('Invalid resend OTP response');
    }

    final challenge = SignupOtpChallenge.fromJson(data);
    if (challenge.userId.isEmpty) {
      throw ApiException('Invalid resend OTP challenge');
    }

    return challenge;
  }

  // ── Customer: Orders ──────────────────────────────────────────────────────

  Future<List<ActiveOrder>> getActiveOrders({String? customerId}) async {
    final data = await apiClient.get(
      '/api/orders/active/${customerId ?? AppEnv.customerId}',
    );

    if (data is! List) return const [];

    return data.map((item) {
      final map = item as Map<String, dynamic>;
      final statusInt = map['status'] is int ? map['status'] as int : 0;
      return ActiveOrder(
        orderId: map['id']?.toString() ?? '',
        title: map['storeName']?.toString() ?? 'Order',
        store: map['shopperName']?.toString() ?? 'Shopper Pending',
        status: _statusLabels[statusInt] ?? 'Pending',
        shopperName: map['shopperName']?.toString() ?? '',
        total: ((map['itemsSubtotal'] as num? ?? 0) +
                (map['deliveryFee'] as num? ?? 0) +
                (map['serviceFee'] as num? ?? 0))
            .toDouble(),
      );
    }).toList();
  }

  Future<List<RecentRequest>> getRecentRequests({String? customerId}) async {
    final data = await apiClient.get(
      '/api/requests/recent/${customerId ?? AppEnv.customerId}',
    );

    if (data is! List) return const [];

    return data.map((item) {
      final map = item as Map<String, dynamic>;
      final items = map['items'] as List? ?? [];
      return RecentRequest(
        title: map['preferredStore']?.toString() ?? 'Shopping Request',
        date: _friendlyDate(map['createdAt']?.toString()),
        itemsCount: items.length,
      );
    }).toList();
  }

  Future<List<ActiveJobItem>> getOrderItems({required String orderId}) async {
    final data = await apiClient.get('/api/orders/$orderId/items');
    if (data is! List) return const [];
    return data.map((item) {
      final m = item as Map<String, dynamic>;
      return ActiveJobItem(
        id: (m['id'] as num? ?? 0).toInt(),
        name: m['name']?.toString() ?? '',
        unit: m['unit']?.toString() ?? '',
        description: m['description']?.toString() ?? '',
        quantity: (m['quantity'] as num? ?? 1).toInt(),
        estimatedPrice: (m['estimatedPrice'] as num? ?? 0).toDouble(),
        foundPrice: m['foundPrice'] != null ? (m['foundPrice'] as num).toDouble() : null,
        status: (m['status'] as num? ?? 0).toInt(),
        photoUrl: m['photoUrl']?.toString(),
      );
    }).toList();
  }

  Future<OrderTrackingData?> getOrderTracking({required String orderId}) async {
    final data = await apiClient.get('/api/orders/$orderId/tracking');

    if (data is! Map<String, dynamic>) return null;

    final statusInt = data['currentStatus'] is int ? data['currentStatus'] as int : 0;
    return OrderTrackingData(
      orderId: orderId,
      shopperName: data['shopperName']?.toString() ?? 'Shopper',
      storeName: data['storeName']?.toString() ?? '',
      currentStatus: _statusLabels[statusInt] ?? 'Shopping',
      stepLabel: data['stepLabel']?.toString() ?? '',
      progressPercent: (data['progressPercent'] as num? ?? 0).toInt(),
      pickedItemsCount: (data['pickedItemsCount'] as num? ?? 0).toInt(),
      totalItemsCount: (data['totalItemsCount'] as num? ?? 1).toInt(),
      estimatedDeliveryMinutes: (data['estimatedDeliveryMinutes'] as num? ?? 0).toInt(),
    );
  }

  Future<OrderSummaryData?> getOrderSummary({required String orderId}) async {
    final data = await apiClient.get('/api/orders/$orderId/summary');

    if (data is! Map<String, dynamic>) return null;

    final rawItems = data['items'] as List? ?? [];
    final items = rawItems.map((i) {
      final m = i as Map<String, dynamic>;
      return OrderSummaryItem(
        name: m['name']?.toString() ?? '',
        unit: m['unit']?.toString() ?? '',
        quantity: (m['quantity'] as num? ?? 1).toInt(),
        price: (m['price'] as num? ?? 0).toDouble(),
        photoUrl: m['photoUrl']?.toString(),
      );
    }).toList();

    final deliveredAt = DateTime.tryParse(data['deliveredAt']?.toString() ?? '')?.toLocal();
    final dateStr = deliveredAt != null
        ? '${deliveredAt.day}/${deliveredAt.month}/${deliveredAt.year}'
        : '';

    return OrderSummaryData(
      orderId: orderId,
      storeName: data['storeName']?.toString() ?? '',
      storeAddress: data['storeAddress']?.toString() ?? '',
      shopperName: data['shopperName']?.toString() ?? '',
      deliveryAddress: data['deliveryAddress']?.toString() ?? '',
      deliveredAt: dateStr,
      items: items,
      itemsSubtotal: (data['itemsSubtotal'] as num? ?? 0).toDouble(),
      deliveryFee: (data['deliveryFee'] as num? ?? 0).toDouble(),
      serviceFee: (data['serviceFee'] as num? ?? 0).toDouble(),
      totalPaid: (data['totalPaid'] as num? ?? 0).toDouble(),
    );
  }

  // ── Customer: Create Request ───────────────────────────────────────────────

  Future<void> createRequest({
    required List<RequestItem> items,
    required String preferredStore,
    required bool isFixedStore,
    required double budget,
    required String deliveryAddress,
    String? customerId,
    String marketType = 'Supermarket',
    String? deliveryNotes,
  }) async {
    await apiClient.post('/api/requests', {
      'customerId': customerId ?? AppEnv.customerId,
      'preferredStore': preferredStore,
      'marketType': marketType == 'Supermarket' ? 0 : 1,
      'isFixedStore': isFixedStore,
      'budget': budget,
      'deliveryAddress': deliveryAddress,
      if (deliveryNotes != null && deliveryNotes.isNotEmpty)
        'deliveryNotes': deliveryNotes,
      'items': items
          .map((item) => {
                'name': item.name,
                'quantity': item.quantity,
                'unit': item.unit,
                'description': item.description,
                'maxPrice': item.maxPrice,
              })
          .toList(),
    });
  }

  // ── Shopper: Active Job ────────────────────────────────────────────────────

  Future<ActiveJobData?> getActiveJob() async {
    final data = await apiClient.get('/api/orders/shopper/active-job');

    if (data == null || data is! Map<String, dynamic>) return null;

    final rawItems = data['items'] as List? ?? [];
    final items = rawItems.map((i) {
      final m = i as Map<String, dynamic>;
      return ActiveJobItem(
        id: (m['id'] as num? ?? 0).toInt(),
        name: m['name']?.toString() ?? '',
        unit: m['unit']?.toString() ?? '',
        description: m['description']?.toString() ?? '',
        quantity: (m['quantity'] as num? ?? 1).toInt(),
        estimatedPrice: (m['estimatedPrice'] as num? ?? 0).toDouble(),
        foundPrice: m['foundPrice'] != null
            ? (m['foundPrice'] as num).toDouble()
            : null,
        status: (m['status'] as num? ?? 0).toInt(),
        photoUrl: m['photoUrl']?.toString(),
      );
    }).toList();

    return ActiveJobData(
      orderId: data['orderId']?.toString() ?? '',
      requestId: data['requestId']?.toString() ?? '',
      storeName: data['storeName']?.toString() ?? '',
      storeAddress: data['storeAddress']?.toString() ?? '',
      customerName: data['customerName']?.toString() ?? '',
      deliveryAddress: data['deliveryAddress']?.toString() ?? '',
      deliveryNotes: data['deliveryNotes']?.toString() ?? '',
      status: (data['status'] as num? ?? 0).toInt(),
      pickedItemsCount: (data['pickedItemsCount'] as num? ?? 0).toInt(),
      totalItemsCount: (data['totalItemsCount'] as num? ?? 0).toInt(),
      estimatedTotal: (data['estimatedTotal'] as num? ?? 0).toDouble(),
      items: items,
    );
  }

  Future<List<ShopperOrderData>> getShopperOrderHistory() async {
    final data = await apiClient.get('/api/orders/shopper/history');

    if (data is! List) return const [];

    return data.map((item) {
      final map = item as Map<String, dynamic>;
      final completedAt = DateTime.tryParse(map['completedAt']?.toString() ?? '')?.toLocal();
      final dateStr = completedAt != null
          ? '${completedAt.day}/${completedAt.month}/${completedAt.year}'
          : 'Recently';

      return ShopperOrderData(
        orderId: map['orderId']?.toString() ?? '',
        storeName: map['storeName']?.toString() ?? '',
        customerName: map['customerName']?.toString() ?? '',
        completedAt: dateStr,
        earningsAmount: (map['earningsAmount'] as num? ?? 0).toDouble(),
        status: (map['status'] as num? ?? 5).toInt(),
        itemsCount: (map['itemsCount'] as num? ?? 0).toInt(),
      );
    }).toList();
  }

  // ── Public Markets ────────────────────────────────────────────────────────

  Future<List<MarketData>> getMarkets({String? type}) async {
    final path = type != null
        ? '/api/markets?type=${Uri.encodeComponent(type)}'
        : '/api/markets';
    final data = await apiClient.get(path);
    if (data is! List) return const [];
    return data.map((item) {
      final m = item as Map<String, dynamic>;
      final rawCats = m['categories'];
      final cats = rawCats is List
          ? rawCats.map((e) => e.toString()).toList()
          : <String>[];
      return MarketData(
        marketId: m['marketId']?.toString() ?? '',
        name: m['name']?.toString() ?? '',
        type: m['type']?.toString() ?? '',
        address: m['address']?.toString() ?? '',
        openingTime: m['openingTime']?.toString() ?? '',
        closingTime: m['closingTime']?.toString() ?? '',
        photoUrl: m['photoUrl']?.toString(),
        latitude: (m['latitude'] as num?)?.toDouble(),
        longitude: (m['longitude'] as num?)?.toDouble(),
        categories: cats,
      );
    }).toList();
  }

  // ── Location ──────────────────────────────────────────────────────────────

  Future<void> updateUserLocation({
    required double latitude,
    required double longitude,
  }) async {
    await apiClient.post('/api/users/me/location', {
      'latitude': latitude,
      'longitude': longitude,
    });
  }

  // ── Avatar upload ──────────────────────────────────────────────────────────

  Future<String?> uploadAvatar({
    required List<int> bytes,
    required String fileName,
  }) async {
    final data = await apiClient.uploadFile(
      path: '/api/users/me/avatar',
      bytes: bytes,
      fileName: fileName,
      contentType: 'image/jpeg',
    );

    if (data is Map<String, dynamic>) {
      return data['avatarUrl']?.toString();
    }
    return null;
  }

  // ── Chat ──────────────────────────────────────────────────────────────────

  Future<List<ChatMessage>> getChatMessages({String? orderId}) async {
    final data = await apiClient.get(
      '/api/orders/${orderId ?? AppEnv.orderId}/chat',
    );

    if (data is! List) return const [];

    return data.map(mapChatMessage).toList();
  }

  ChatMessage mapChatMessage(dynamic item) {
    final map = Map<String, dynamic>.from(item as Map);
    final senderRaw = map['sender']?.toString().toLowerCase() ?? 'shopper';
    final sender = senderRaw == 'customer' ? SenderType.customer : SenderType.shopper;

    final typeRaw = map['type']?.toString().toLowerCase() ?? 'text';
    final type = typeRaw == 'image' ? MessageType.image : MessageType.text;

    return ChatMessage(
      id: map['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
      sender: sender,
      type: type,
      time: DateTime.tryParse(map['sentAt']?.toString() ?? '') ?? DateTime.now(),
      text: map['text']?.toString(),
      imageUrl: map['imageUrl']?.toString(),
    );
  }

  Future<void> sendTextMessage({required String text, String? orderId}) async {
    await apiClient.post(
      '/api/orders/${orderId ?? AppEnv.orderId}/chat/messages',
      {'sender': 'customer', 'type': 'text', 'text': text, 'imageUrl': null},
    );
  }

  Future<void> sendPriceDecision({
    required int decision,
    String? note,
    String? orderId,
  }) async {
    await apiClient.post(
      '/api/orders/${orderId ?? AppEnv.orderId}/chat/price-decision',
      {'decision': decision, 'note': note},
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _friendlyDate(String? iso) {
    if (iso == null) return 'Recently';
    final value = DateTime.tryParse(iso)?.toLocal();
    if (value == null) return 'Recently';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(value.year, value.month, value.day);
    final difference = today.difference(date).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    return '${value.day}/${value.month}/${value.year}';
  }
}

final swiftShopperRepositoryProvider = Provider<SwiftShopperRepository>((ref) {
  final client = ref.watch(httpClientProvider);
  return SwiftShopperRepository(apiClient: ApiClient(client: client));
});
