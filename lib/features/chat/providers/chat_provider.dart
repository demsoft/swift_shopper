import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/data/swift_shopper_repository.dart';
import '../data/chat_realtime_provider.dart';
import '../models/chat_message.dart';

class ChatArgs {
  const ChatArgs({required this.orderId, required this.isShopper});
  final String orderId;
  final bool isShopper;

  @override
  bool operator ==(Object other) =>
      other is ChatArgs &&
      other.orderId == orderId &&
      other.isShopper == isShopper;

  @override
  int get hashCode => Object.hash(orderId, isShopper);
}

class ChatState {
  const ChatState({
    required this.messages,
    required this.isRealtimeConnected,
    this.isSending = false,
  });

  final List<ChatMessage> messages;
  final bool isRealtimeConnected;
  final bool isSending;

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isRealtimeConnected,
    bool? isSending,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isRealtimeConnected: isRealtimeConnected ?? this.isRealtimeConnected,
      isSending: isSending ?? this.isSending,
    );
  }
}

class ChatNotifier extends FamilyAsyncNotifier<ChatState, ChatArgs> {
  StreamSubscription<Map<String, dynamic>>? _messageSubscription;
  StreamSubscription<bool>? _connectionSubscription;
  Timer? _pollTimer;
  final _player = AudioPlayer();

  @override
  Future<ChatState> build(ChatArgs arg) async {
    final repository = ref.read(swiftShopperRepositoryProvider);
    final realtimeService = ref.read(signalRChatServiceProvider);

    ref.onDispose(() {
      _messageSubscription?.cancel();
      _connectionSubscription?.cancel();
      _pollTimer?.cancel();
      _player.dispose();
      unawaited(realtimeService.disconnect());
    });

    // SignalR: push new messages into state
    _messageSubscription?.cancel();
    _messageSubscription = realtimeService.messages.listen((payload) {
      final current = state.valueOrNull;
      if (current == null) return;

      final message = repository.mapChatMessage(payload);
      if (current.messages.any((m) => m.id == message.id)) return;

      // Play beep only for incoming messages (not sent by current user)
      final isIncoming = arg.isShopper
          ? message.sender == SenderType.customer
          : message.sender == SenderType.shopper;
      if (isIncoming) {
        unawaited(_player.play(AssetSource('sounds/message_beep.wav')));
      }

      state = AsyncData(
        current.copyWith(messages: [...current.messages, message]),
      );
    });

    // Track connection status
    _connectionSubscription?.cancel();
    _connectionSubscription = realtimeService.connectionStatus.listen((isLive) {
      final current = state.valueOrNull;
      if (current == null || current.isRealtimeConnected == isLive) return;
      state = AsyncData(current.copyWith(isRealtimeConnected: isLive));
    });

    // Polling fallback: re-fetch every 5 s to catch any messages
    // that SignalR may have missed
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      final current = state.valueOrNull;
      if (current == null) return;
      try {
        final refreshed =
            await repository.getChatMessages(orderId: arg.orderId);
        // Only update state if there are genuinely new messages
        if (refreshed.length != current.messages.length) {
          // Check if the newest message is incoming
          if (refreshed.isNotEmpty) {
            final newest = refreshed.last;
            final isIncoming = arg.isShopper
                ? newest.sender == SenderType.customer
                : newest.sender == SenderType.shopper;
            if (isIncoming) {
              unawaited(_player.play(AssetSource('sounds/message_beep.wav')));
            }
          }
          state = AsyncData(current.copyWith(messages: refreshed));
        }
      } catch (_) {}
    });

    List<ChatMessage> messages = const [];
    try {
      messages = await repository.getChatMessages(orderId: arg.orderId);
    } catch (_) {}

    try {
      await realtimeService.connect(orderId: arg.orderId);
    } catch (_) {}

    return ChatState(
      messages: messages,
      isRealtimeConnected: realtimeService.isConnected,
    );
  }

  Future<void> sendMediaMessage({
    required List<int> bytes,
    required String fileName,
    required String contentType,
    required bool isImage,
  }) async {
    final current = state.valueOrNull;
    if (current == null) return;

    state = AsyncData(current.copyWith(isSending: true));
    try {
      final repository = ref.read(swiftShopperRepositoryProvider);
      if (isImage) {
        await repository.sendImageMessage(
          bytes: bytes,
          fileName: fileName,
          contentType: contentType,
          orderId: arg.orderId,
          isShopper: arg.isShopper,
        );
      } else {
        await repository.sendFileMessage(
          bytes: bytes,
          fileName: fileName,
          contentType: contentType,
          orderId: arg.orderId,
          isShopper: arg.isShopper,
        );
      }
      final refreshed = await repository.getChatMessages(orderId: arg.orderId);
      state = AsyncData(current.copyWith(messages: refreshed, isSending: false));
    } catch (_) {
      final withoutSending = state.valueOrNull;
      if (withoutSending != null) {
        state = AsyncData(withoutSending.copyWith(isSending: false));
      }
      rethrow;
    }
  }

  Future<void> sendTextMessage(String text, {String? replyToText}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final current = state.valueOrNull;
    if (current == null) return;

    // Optimistically add the sent message to the local list immediately
    final optimisticMsg = ChatMessage(
      id: 'local-${DateTime.now().millisecondsSinceEpoch}',
      sender: arg.isShopper ? SenderType.shopper : SenderType.customer,
      type: MessageType.text,
      time: DateTime.now(),
      text: trimmed,
      replyToText: replyToText,
    );

    state = AsyncData(current.copyWith(
      messages: [...current.messages, optimisticMsg],
      isSending: true,
    ));

    try {
      final repository = ref.read(swiftShopperRepositoryProvider);
      await repository.sendTextMessage(
        text: trimmed,
        orderId: arg.orderId,
        isShopper: arg.isShopper,
      );

      // Replace optimistic message with the real one from server
      final refreshed = await repository.getChatMessages(orderId: arg.orderId);
      state = AsyncData(current.copyWith(messages: refreshed, isSending: false));
    } catch (_) {
      // Keep the optimistic message visible even if send failed
      final withoutSending = state.valueOrNull;
      if (withoutSending != null) {
        state = AsyncData(withoutSending.copyWith(isSending: false));
      }
    }
  }
}

final chatProvider =
    AsyncNotifierProviderFamily<ChatNotifier, ChatState, ChatArgs>(
  ChatNotifier.new,
);
