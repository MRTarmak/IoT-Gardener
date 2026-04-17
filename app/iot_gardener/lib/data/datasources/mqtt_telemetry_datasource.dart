import 'dart:async';
import 'dart:convert';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import '../../domain/entities/mqtt_connection_params.dart';
import '../../domain/entities/telemetry_data.dart';

class MqttTelemetryDatasource {
  MqttServerClient? _client;
  StreamSubscription<List<MqttReceivedMessage<MqttMessage?>>>? _subscription;

  final _telemetryController = StreamController<TelemetryData>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();

  Stream<TelemetryData> get telemetryStream => _telemetryController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;

  Future<bool> connect(MqttConnectionParams params) async {
    await disconnect();

    final client = MqttServerClient(params.host, params.clientId)
      ..port = params.port
      ..keepAlivePeriod = 30
      ..secure = false
      ..logging(on: false)
      ..autoReconnect = true;

    client.connectionMessage = MqttConnectMessage()
        .withClientIdentifier(params.clientId)
        .startClean()
        .withWillQos(MqttQos.atMostOnce);

    try {
      await client.connect();

      if (client.connectionStatus?.state != MqttConnectionState.connected) {
        _connectionController.add(false);
        client.disconnect();
        return false;
      }

      client.subscribe(params.topic, MqttQos.atLeastOnce);

      _subscription = client.updates?.listen((messages) {
        if (messages.isEmpty) return;

        final message = messages.first.payload;
        if (message is! MqttPublishMessage) return;

        final payload = MqttPublishPayload.bytesToStringAsString(
          message.payload.message,
        );

        try {
          final decoded = jsonDecode(payload);
          if (decoded is Map<String, dynamic>) {
            _telemetryController.add(TelemetryData.fromMap(decoded));
          }
        } catch (_) {
          // Ignore malformed payloads.
        }
      });

      _client = client;
      _connectionController.add(true);
      return true;
    } catch (_) {
      _connectionController.add(false);
      client.disconnect();
      return false;
    }
  }

  Future<void> disconnect() async {
    await _subscription?.cancel();
    _subscription = null;
    _client?.disconnect();
    _client = null;
    _connectionController.add(false);
  }

  Future<void> dispose() async {
    await disconnect();
    await _telemetryController.close();
    await _connectionController.close();
  }
}
