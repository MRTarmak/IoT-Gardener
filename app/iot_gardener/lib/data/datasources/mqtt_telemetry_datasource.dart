import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/services.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import '../../domain/entities/telemetry_data.dart';

class MqttTelemetryDatasource {
  static String get _mqEndpoint => dotenv.env['MQ_ENDPOINT'] ?? '';
  static int get _mqPort => int.tryParse(dotenv.env['MQ_PORT'] ?? '') ?? 0;
  static String get _mqUsername => dotenv.env['MQ_USERNAME'] ?? '';
  static String get _mqPassword => dotenv.env['MQ_PASSWORD'] ?? '';
  static String get _pemPath => dotenv.env['MQ_CERT_PATH'] ?? '';

  static const String _topic = '/gardener/telemetry';

  MqttServerClient? _client;
  StreamSubscription<List<MqttReceivedMessage<MqttMessage?>>>? _subscription;

  final _telemetryController = StreamController<TelemetryData>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();

  Stream<TelemetryData> get telemetryStream => _telemetryController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;

  Future<bool> connect() async {
    await disconnect();

    if (_mqEndpoint.isEmpty ||
        _mqPort <= 0 ||
        _mqUsername.isEmpty ||
        _mqPassword.isEmpty ||
        _topic.isEmpty ||
        _pemPath.isEmpty) {
      _connectionController.add(false);
      return false;
    }

    late final SecurityContext securityContext;
    try {
      final certBytes = (await rootBundle.load(_pemPath)).buffer.asUint8List();
      securityContext = SecurityContext.defaultContext;
      securityContext.setTrustedCertificatesBytes(certBytes);
    } catch (_) {
      _connectionController.add(false);
      return false;
    }

    final client = MqttServerClient(_mqEndpoint, _mqUsername)
      ..port = _mqPort
      ..keepAlivePeriod = 30
      ..secure = true
      ..securityContext = securityContext
      ..logging(on: false)
      ..autoReconnect = true;

    client.connectionMessage = MqttConnectMessage()
        .withClientIdentifier(_mqUsername)
        .authenticateAs(_mqUsername, _mqPassword)
        .startClean()
        .withWillQos(MqttQos.atMostOnce);

    try {
      await client.connect();

      if (client.connectionStatus?.state != MqttConnectionState.connected) {
        _connectionController.add(false);
        client.disconnect();
        return false;
      }

      client.subscribe(_topic, MqttQos.atLeastOnce);

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
