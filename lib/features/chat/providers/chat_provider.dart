import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/data/swift_shopper_repository.dart';
import '../data/chat_realtime_provider.dart';
import '../models/chat_message.dart';

class ChatState {
  const ChatState({
    required this.otherPersonName,
    required this.status,
    required this.messages,
    required this.isRealtimeConnected,
    this.isSending = false,
  });

  final String otherPersonName;
  final String status;
  final List<ChatMessage> messages;
  final bool isRealtimeConnected;
  final bool isSending;

  ChatState copyWith({
    String? otherPersonName,
    String? status,
    List<ChatMessage>? messages,
    bool? isRealtimeConnected,
    bool? isSending,
  }) {
    return ChatState(
      otherPersonName: otherPersonName ?? this.otherPersonName,
      status: status ?? this.status,
      messages: messages ?? this.messages,
      isRealtimeConnected: isRealtimeConnected ?? this.isRealtimeConnected,
      isSending: isSending ?? this.isSending,
    );
  }
}

class ChatNotifier extends FamilyAsyncNotifier<ChatState, String> {
  StreamSubscription<Map<String, dynamic>>? _messageSubscription;
  StreamSubscription<bool>? _connectionSubscription;

  @override
  Future<ChatState> build(String orderId) async {
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
      if (current == null) return;

      final message = repository.mapChatMessage(payload);
      if (current.messages.any((m) => m.id == message.id)) return;

      state = AsyncData(
        current.copyWith(messages: [...current.messages, message]),
      );
    });

    _connectionSubscription?.cancel();
    _connectionSubscription = realtimeService.connectionStatus.listen((isLive) {
      final current = state.valueOrNull;
      if (current == null || current.isRealtimeConnected == isLive) return;
      state = AsyncData(current.copyWith(isRealtimeConnected: isLive));
    });

    List<ChatMessage> messages = const [];
    try {
      messages = await repository.getChatMessages(orderId: orderId);
    } catch (_) {}

    try {
      await realtimeService.connect(orderId: orderId);
    } catch (_) {}

    return ChatState(
      otherPersonName: '',
      status: '',
      messages: messages,
      isRealtimeConnected: realtimeService.isConnected,
    );
  }

  Future<void> sendTextMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final current = state.valueOrNull;
    if (current == null) return;

    state = AsyncData(current.copyWith(isSending: true));

    try {
      final repository = ref.read(swiftShopperRepositoryProvider);
      final realtimeService = ref.read(signalRChatServiceProvider);
      await repository.sendTextMessage(text: trimmed, orderId: arg);

      if (!realtimeService.isConnected) {
        final refreshed = await repository.getChatMessages(orderId: arg);
        state = AsyncData(
          current.copyWith(messages: refreshed, isSending: false),
        );
      } else {
        state = AsyncData(current.copyWith(isSending: false));
      }
    } catch (_) {
      state = AsyncData(current.copyWith(isSending: false));
    }
  }

  Future<void> sendPriceDecision(int decision) async {
    try {
      final repository = ref.read(swiftShopperRepositoryProvider);
      await repository.sendPriceDecision(decision: decision, orderId: arg);
    } catch (_) {}
  }
}

final chatProvider =
    AsyncNotifierProviderFamily<ChatNotifier, ChatState, String>(
  ChatNotifier.new,
);
