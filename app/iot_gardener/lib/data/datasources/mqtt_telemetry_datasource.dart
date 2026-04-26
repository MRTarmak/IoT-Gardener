import '../../domain/entities/mqtt_connection_params.dart';
import '../../domain/entities/telemetry_data.dart';

abstract class MqttTelemetryDatasource {
  Stream<TelemetryData> get telemetryStream;
  Stream<bool> get connectionStream;

  Future<bool> connect(MqttConnectionParams params);
  Future<void> disconnect();
  Future<void> dispose();
}
