import 'dart:async';
import 'package:flutter/material.dart';
import 'package:signalr_core/signalr_core.dart';
import '../config/api_config.dart';

class SignalRService extends ChangeNotifier {
  HubConnection? _hubConnection;
  final _messageController = StreamController<String>.broadcast();

  Stream<String> get messageStream => _messageController.stream;

  bool get isConnected => _hubConnection?.state == HubConnectionState.connected;

  Future<void> initSignalR() async {
    // If connected or connecting, do nothing
    if (_hubConnection?.state == HubConnectionState.connected ||
        _hubConnection?.state == HubConnectionState.connecting) {
      return;
    }

    final hubUrl = ApiConfig.hubUrl;
    debugPrint('Connecting to SignalR Hub: $hubUrl');

    _hubConnection = HubConnectionBuilder()
        .withUrl(hubUrl)
        .withAutomaticReconnect()
        .build();

    _hubConnection!.on("ReceiveOrderNotification", (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final message = arguments[0] as String;
        debugPrint('SignalR Notification: $message');
        _messageController.add(message);
      }
    });

    _hubConnection!.onclose((error) {
      debugPrint('SignalR Connection Closed: $error');
      notifyListeners();
    });

    try {
      await _hubConnection!.start();
      debugPrint('SignalR Connected!');
      notifyListeners();
    } catch (e) {
      debugPrint('Error connecting to SignalR: $e');
    }
  }

  Future<void> stop() async {
    await _hubConnection?.stop();
  }

  @override
  void dispose() {
    _messageController.close();
    stop();
    super.dispose();
  }
}
