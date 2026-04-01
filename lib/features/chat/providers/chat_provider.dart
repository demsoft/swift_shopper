import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_env.dart';
import '../../home/models/home_models.dart';
import '../../shared/data/swift_shopper_repository.dart';
import '../data/chat_realtime_provider.dart';
import '../models/chat_message.dart';

class ChatState {
  const ChatState({
    required this.shopperName,
    required this.status,
    required this.messages,
    required this.isRealtimeConnected,
  });

  final String shopperName;
  final String status;
  final List<ChatMessage> messages;
  final bool isRealtimeConnected;

  ChatState copyWith({
    String? shopperName,
    String? status,
    List<ChatMessage>? messages,
    bool? isRealtimeConnected,
  }) {
    return ChatState(
      shopperName: shopperName ?? this.shopperName,
      status: status ?? this.status,
      messages: messages ?? this.messages,
      isRealtimeConnected: isRealtimeConnected ?? this.isRealtimeConnected,
    );
  }
}

class ChatNotifier extends AsyncNotifier<ChatState> {
  StreamSubscription<Map<String, dynamic>>? _messageSubscription;
  StreamSubscription<bool>? _connectionSubscription;

  @override
  Future<ChatState> build() async {
    final repository = ref.read(swiftShopperRepositoryProvider);
    final realtimeService = ref.read(signalRChatServiceProvider);

    ref.onDispose(() {
      _messageSubscription?.cancel();
      _connectionSubscription?.cancel();
      unawaited(realtimeService.disconnect());
    });

    _messageSubscription?.cancel();
    _messageSubscription = realtimeService.messages.listen((payload) {
      final current = state.valueOrNull;
      if (current == null) {
        return;
      }

      final message = repository.mapChatMessage(payload);
      if (current.messages.any((item) => item.id == message.id)) {
        return;
      }

      state = AsyncData(
        current.copyWith(
          messages: _ensurePriceCard([...current.messages, message]),
        ),
      );
    });

    _connectionSubscription?.cancel();
    _connectionSubscription = realtimeService.connectionStatus.listen((isLive) {
      final current = state.valueOrNull;
      if (current == null || current.isRealtimeConnected == isLive) {
        return;
      }

      state = AsyncData(current.copyWith(isRealtimeConnected: isLive));
    });

    OrderTrackingData? tracking;
    List<ChatMessage> messages = const [];

    try {
      tracking = await repository.getOrderTracking(orderId: AppEnv.orderId);
    } catch (_) {}

    try {
      messages = await repository.getChatMessages();
    } catch (_) {}

    try {
      await realtimeService.connect(orderId: AppEnv.orderId);
    } catch (_) {}

    return ChatState(
      shopperName: tracking?.shopperName ?? 'Amina (Shopper)',
      status: tracking?.currentStatus ?? 'Shopping',
      messages: _ensurePriceCard(messages),
      isRealtimeConnected: realtimeService.isConnected,
    );
  }

  Future<void> sendTextMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return;
    }

    try {
      final repository = ref.read(swiftShopperRepositoryProvider);
      final realtimeService = ref.read(signalRChatServiceProvider);
      await repository.sendTextMessage(text: trimmed);

      if (!realtimeService.isConnected) {
        final current = state.valueOrNull;
        if (current == null) {
          return;
        }

        final refreshed = await repository.getChatMessages();
        state = AsyncData(
          current.copyWith(messages: _ensurePriceCard(refreshed)),
        );
      }
    } catch (_) {}
  }

  Future<void> respondToPriceAction(String actionLabel) async {
    final payload = _decisionPayload(actionLabel);

    try {
      final repository = ref.read(swiftShopperRepositoryProvider);
      final realtimeService = ref.read(signalRChatServiceProvider);
      await repository.sendPriceDecision(
        decision: payload.decision,
        note: payload.note,
      );

      if (!realtimeService.isConnected) {
        final current = state.valueOrNull;
        if (current == null) {
          return;
        }

        final refreshed = await repository.getChatMessages(
          orderId: AppEnv.orderId,
        );
        state = AsyncData(
          current.copyWith(messages: _ensurePriceCard(refreshed)),
        );
      }
    } catch (_) {}
  }

  List<ChatMessage> _ensurePriceCard(List<ChatMessage> messages) {
    final hasPriceCard = messages.any(
      (item) => item.type == MessageType.priceCard,
    );
    if (hasPriceCard) {
      return messages;
    }

    return [
      ...messages,
      ChatMessage(
        id: 'local-price-card',
        sender: SenderType.shopper,
        type: MessageType.priceCard,
        time: DateTime.now(),
        priceCardData: const PriceCardData(
          itemName: 'Organic Olive Oil (500ml)',
          imageUrl:
              'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?w=900',
          price: 14.99,
        ),
      ),
    ];
  }

  _PriceDecisionPayload _decisionPayload(String actionLabel) {
    final text = actionLabel.toLowerCase();
    if (text.contains('accept')) {
      return const _PriceDecisionPayload(decision: 1, note: 'Accepted');
    }
    if (text.contains('reject')) {
      return const _PriceDecisionPayload(decision: 3, note: 'Rejected');
    }
    return const _PriceDecisionPayload(
      decision: 2,
      note: 'Can we lower the price?',
    );
  }
}

class _PriceDecisionPayload {
  const _PriceDecisionPayload({required this.decision, this.note});

  final int decision;
  final String? note;
}

final chatProvider = AsyncNotifierProvider<ChatNotifier, ChatState>(
  ChatNotifier.new,
);
