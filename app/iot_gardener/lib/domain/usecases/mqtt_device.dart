import '../entities/mqtt_connection_params.dart';
import '../entities/telemetry_data.dart';
import '../repositories/mqtt_telemetry_repository.dart';

class MqttDevice {
  final MqttTelemetryRepository _repository;

  MqttDevice(this._repository);

  Stream<TelemetryData> get telemetryStream => _repository.telemetryStream;
  Stream<bool> get connectionStream => _repository.connectionStream;

  Future<bool> connect(MqttConnectionParams params) {
    return _repository.connect(params);
  }

  Future<void> disconnect() {
    return _repository.disconnect();
  }

  Future<void> dispose() {
    return _repository.dispose();
  }
}
