import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/foundation.dart';
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
  static const String _logName = 'MqttTelemetryDatasource';

  MqttServerClient? _client;
  StreamSubscription<List<MqttReceivedMessage<MqttMessage?>>>? _subscription;

  final _telemetryController = StreamController<TelemetryData>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();

  Stream<TelemetryData> get telemetryStream => _telemetryController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;

  void _emitConsoleLog(String severity, String message) {
    debugPrint('[MQTT][$severity] $message');
  }

  void _logInfo(String message) {
    developer.log(message, name: _logName);
    _emitConsoleLog('INFO', message);
  }

  void _logWarning(String message) {
    developer.log(message, name: _logName, level: 900);
    _emitConsoleLog('WARN', message);
  }

  void _logError(String message, Object error, StackTrace stackTrace) {
    developer.log(
      message,
      name: _logName,
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
    _emitConsoleLog('ERROR', '$message | $error');
  }

  String _trimPayloadForLogs(String payload) {
    const maxLength = 300;
    if (payload.length <= maxLength) {
      return payload;
    }
    return '${payload.substring(0, maxLength)}...';
  }

  Future<bool> connect() async {
    _logInfo('Starting MQTT connection flow.');
    await disconnect();

    if (_mqEndpoint.isEmpty ||
        _mqPort <= 0 ||
        _mqUsername.isEmpty ||
        _mqPassword.isEmpty ||
        _topic.isEmpty ||
        _pemPath.isEmpty) {
      _logWarning(
        'MQTT config is invalid. endpoint="$_mqEndpoint", '
        'port=$_mqPort, usernameSet=${_mqUsername.isNotEmpty}, '
        'passwordSet=${_mqPassword.isNotEmpty}, topic="$_topic", '
        'pemPath="$_pemPath".',
      );
      _connectionController.add(false);
      return false;
    }

    late final SecurityContext securityContext;
    try {
      final certBytes = (await rootBundle.load(_pemPath)).buffer.asUint8List();
      securityContext = SecurityContext.defaultContext;
      securityContext.setTrustedCertificatesBytes(certBytes);
      _logInfo(
        'TLS certificate loaded successfully from "$_pemPath" '
        '(${certBytes.length} bytes).',
      );
    } catch (e, st) {
      _logError('Failed to load TLS certificate from "$_pemPath".', e, st);
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

    client.onConnected = () {
      _logInfo('Client callback: connected.');
    };
    client.onDisconnected = () {
      _logWarning('Client callback: disconnected.');
    };
    client.onSubscribed = (topic) {
      _logInfo('Client callback: subscribed to "$topic".');
    };
    client.onSubscribeFail = (topic) {
      _logWarning('Client callback: failed to subscribe to "$topic".');
    };
    client.pongCallback = () {
      _logInfo('Client callback: received PING response (PONG).');
    };

    client.connectionMessage = MqttConnectMessage()
        .withClientIdentifier(_mqUsername)
        .authenticateAs(_mqUsername, _mqPassword)
        .startClean()
        .withWillQos(MqttQos.atMostOnce);

    try {
      _logInfo('Connecting to MQTT broker "$_mqEndpoint:$_mqPort".');
      await client.connect();

      if (client.connectionStatus?.state != MqttConnectionState.connected) {
        _logWarning(
          'MQTT connect returned non-connected state: '
          '${client.connectionStatus?.state}, '
          'reason=${client.connectionStatus?.returnCode}.',
        );
        _connectionController.add(false);
        client.disconnect();
        return false;
      }

      _logInfo('Connected. Subscribing to topic "$_topic".');
      client.subscribe(_topic, MqttQos.atLeastOnce);

      _subscription = client.updates?.listen(
        (messages) {
          if (messages.isEmpty) {
            _logWarning('Received MQTT update batch with no messages.');
            return;
          }

          _logInfo('Received MQTT update batch. messages=${messages.length}.');

          final message = messages.first.payload;
          if (message is! MqttPublishMessage) {
            _logWarning(
              'Skipping MQTT message because payload type is '
              '${message.runtimeType}, expected MqttPublishMessage.',
            );
            return;
          }

          final payload = MqttPublishPayload.bytesToStringAsString(
            message.payload.message,
          );
          final topic = messages.first.topic;
          _logInfo(
            'Incoming publish. topic="$topic", '
            'payloadLength=${payload.length}, payload="${_trimPayloadForLogs(payload)}".',
          );

          try {
            final decoded = jsonDecode(payload);
            if (decoded is Map<String, dynamic>) {
              final telemetry = TelemetryData.fromMap(decoded);
              _telemetryController.add(telemetry);
              _logInfo(
                'Telemetry parsed and emitted: '
                'soilMoisture=${telemetry.soilMoisture}, '
                'airHumidity=${telemetry.airHumidity}, '
                'soilPh=${telemetry.soilPh}, '
                'soilTemperature=${telemetry.soilTemperature}, '
                'airTemperature=${telemetry.airTemperature}, '
                'light=${telemetry.light}.',
              );
            } else {
              _logWarning(
                'Skipping payload because JSON root is ${decoded.runtimeType}, '
                'expected Map<String, dynamic>.',
              );
            }
          } catch (e, st) {
            _logError('Failed to decode or map telemetry payload.', e, st);
          }
        },
        onError: (Object e, StackTrace st) {
          _logError('MQTT updates stream emitted an error.', e, st);
        },
        onDone: () {
          _logWarning('MQTT updates stream closed.');
        },
      );

      if (_subscription == null) {
        _logWarning('MQTT client updates stream is null after subscribe call.');
      }

      _client = client;
      _connectionController.add(true);
      _logInfo('MQTT connection flow finished successfully.');
      return true;
    } catch (e, st) {
      _logError('MQTT connection flow failed with exception.', e, st);
      _connectionController.add(false);
      client.disconnect();
      return false;
    }
  }

  Future<void> disconnect() async {
    _logInfo('Disconnect requested.');
    await _subscription?.cancel();
    _subscription = null;
    _client?.disconnect();
    _client = null;
    _connectionController.add(false);
    _logInfo('Disconnect completed.');
  }

  Future<void> dispose() async {
    _logInfo('Dispose requested.');
    await disconnect();
    await _telemetryController.close();
    await _connectionController.close();
    _logInfo('Dispose completed.');
  }
}
