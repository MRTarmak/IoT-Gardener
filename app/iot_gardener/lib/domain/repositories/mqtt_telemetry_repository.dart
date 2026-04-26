import '../entities/mqtt_connection_params.dart';
import '../entities/telemetry_data.dart';

abstract class MqttTelemetryRepository {
  Stream<TelemetryData> get telemetryStream;
  Stream<bool> get connectionStream;

  Future<bool> connect(MqttConnectionParams params);
  Future<void> disconnect();
  Future<void> dispose();
}
