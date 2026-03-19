import '../../domain/entities/mqtt_connection_params.dart';
import '../../domain/entities/telemetry_data.dart';
import '../../domain/repositories/mqtt_telemetry_repository.dart';
import '../datasources/mqtt_telemetry_datasource.dart';

class MqttTelemetryRepositoryImpl implements MqttTelemetryRepository {
  final MqttTelemetryDatasource datasource;

  MqttTelemetryRepositoryImpl(this.datasource);

  @override
  Stream<TelemetryData> get telemetryStream => datasource.telemetryStream;

  @override
  Stream<bool> get connectionStream => datasource.connectionStream;

  @override
  Future<bool> connect(MqttConnectionParams params) {
    return datasource.connect(params);
  }

  @override
  Future<void> disconnect() {
    return datasource.disconnect();
  }

  @override
  Future<void> dispose() {
    return datasource.dispose();
  }
}
