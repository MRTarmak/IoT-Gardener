import '../entities/telemetry_data.dart';

abstract class MqttTelemetryRepository {
  Stream<TelemetryData> get telemetryStream;
  Stream<bool> get connectionStream;

  Future<bool> connect();
  Future<void> disconnect();
  Future<void> dispose();
}
