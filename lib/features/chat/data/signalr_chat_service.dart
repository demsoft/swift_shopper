import 'dart:async';

import 'package:logging/logging.dart';
import 'package:signalr_netcore/signalr_client.dart';

import '../../../core/config/app_env.dart';

class SignalRChatService {
  SignalRChatService() : _logger = Logger('SignalR.Chat');

  final Logger _logger;
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<bool> _connectionStatusController =
      StreamController<bool>.broadcast();

  HubConnection? _connection;
  String? _joinedOrderId;

  Stream<Map<String, dynamic>> get messages => _messageController.stream;
  Stream<bool> get connectionStatus => _connectionStatusController.stream;

  bool get isConnected => _connection?.state == HubConnectionState.Connected;

  Future<void> connect({required String orderId}) async {
    if (isConnected && _joinedOrderId == orderId) {
      return;
    }

    await disconnect();

    final connection =
        HubConnectionBuilder()
            .withUrl(
              AppEnv.signalRHubUrl,
              options: HttpConnectionOptions(logger: _logger),
            )
            .withAutomaticReconnect(retryDelays: [0, 2000, 5000, 10000])
            .configureLogging(_logger)
            .build();

    connection.on('messageReceived', _handleMessageReceived);
    connection.on('priceDecisionReceived', _handleMessageReceived);
    connection.onclose(({error}) {
      _emitConnectionStatus(false);
    });
    connection.onreconnecting(({error}) {
      _emitConnectionStatus(false);
    });
    connection.onreconnected(({connectionId}) {
      _emitConnectionStatus(true);
      if (_joinedOrderId != null) {
        unawaited(_joinRoom(connection, _joinedOrderId!));
      }
    });

    await connection.start();
    await _joinRoom(connection, orderId);

    _connection = connection;
    _joinedOrderId = orderId;
    _emitConnectionStatus(true);
  }

  Future<void> disconnect() async {
    final connection = _connection;
    final joinedOrderId = _joinedOrderId;

    _connection = null;
    _joinedOrderId = null;
    _emitConnectionStatus(false);

    if (connection == null) {
      return;
    }

    try {
      if (joinedOrderId != null &&
          connection.state == HubConnectionState.Connected) {
        await connection.invoke(
          'LeaveOrderRoom',
          args: <Object>[joinedOrderId],
        );
      }
    } catch (_) {}

    connection.off('messageReceived');
    connection.off('priceDecisionReceived');

    try {
      await connection.stop();
    } catch (_) {}
  }

  Future<void> dispose() async {
    await disconnect();
    await _messageController.close();
    await _connectionStatusController.close();
  }

  void _handleMessageReceived(List<Object?>? arguments) {
    if (arguments == null || arguments.isEmpty) {
      return;
    }

    final payload = arguments.first;
    if (payload is Map) {
      final mapped = payload.map(
        (key, value) => MapEntry(key.toString(), value),
      );
      _messageController.add(mapped);
    }
  }

  Future<void> _joinRoom(HubConnection connection, String orderId) async {
    await connection.invoke('JoinOrderRoom', args: <Object>[orderId]);
  }

  void _emitConnectionStatus(bool isConnected) {
    if (!_connectionStatusController.isClosed) {
      _connectionStatusController.add(isConnected);
    }
  }
}
