import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:iot_gardener/domain/entities/telemetry_data.dart';
import 'package:iot_gardener/domain/repositories/mqtt_telemetry_repository.dart';
import 'package:iot_gardener/domain/usecases/mqtt_device.dart';

class _FakeMqttTelemetryRepository implements MqttTelemetryRepository {
  final _telemetryController = StreamController<TelemetryData>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();

  bool connectCalled = false;
  bool disconnectCalled = false;
  bool disposeCalled = false;
  bool connectResult;

  _FakeMqttTelemetryRepository({this.connectResult = true});

  void emitTelemetry(TelemetryData data) {
    _telemetryController.add(data);
  }

  void emitConnection(bool connected) {
    _connectionController.add(connected);
  }

  @override
  Stream<TelemetryData> get telemetryStream => _telemetryController.stream;

  @override
  Stream<bool> get connectionStream => _connectionController.stream;

  @override
  Future<bool> connect() async {
    connectCalled = true;
    return connectResult;
  }

  @override
  Future<void> disconnect() async {
    disconnectCalled = true;
  }

  @override
  Future<void> dispose() async {
    disposeCalled = true;
    await _telemetryController.close();
    await _connectionController.close();
  }
}

void main() {
  group('MqttDevice', () {
    test('delegates connect result to repository', () async {
      final repo = _FakeMqttTelemetryRepository(connectResult: false);
      final device = MqttDevice(repo);

      final result = await device.connect();

      expect(result, isFalse);
      expect(repo.connectCalled, isTrue);
    });

    test('delegates disconnect and dispose', () async {
      final repo = _FakeMqttTelemetryRepository();
      final device = MqttDevice(repo);

      await device.disconnect();
      await device.dispose();

      expect(repo.disconnectCalled, isTrue);
      expect(repo.disposeCalled, isTrue);
    });

    test('forwards repository stream events', () async {
      final repo = _FakeMqttTelemetryRepository();
      final device = MqttDevice(repo);
      final telemetry = TelemetryData(
        soilMoisture: 10,
        airHumidity: 20,
        soilPh: 6.5,
        temperature: 22,
        light: 500,
        receivedAt: DateTime(2026, 1, 1),
      );

      final telemetryExpectation =
          expectLater(device.telemetryStream, emits(telemetry));
      final connectionExpectation =
          expectLater(device.connectionStream, emits(true));

      repo.emitTelemetry(telemetry);
      repo.emitConnection(true);

      await telemetryExpectation;
      await connectionExpectation;
    });
  });
}
