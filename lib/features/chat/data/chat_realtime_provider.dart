import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'signalr_chat_service.dart';

final signalRChatServiceProvider = Provider<SignalRChatService>((ref) {
  final service = SignalRChatService();
  ref.onDispose(() {
    unawaited(service.dispose());
  });
  return service;
});
