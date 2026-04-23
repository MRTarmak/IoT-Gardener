import '../../domain/entities/monitoring_profile_params.dart';

class MonitoringProfileMapper {
  static Map<String, dynamic> toMap(MonitoringProfileParams params) {
    return {
      'name': params.name,
      'soilMoistureRange': [
        params.soilMoistureRange.$1,
        params.soilMoistureRange.$2,
      ],
      'airHumidityRange': [
        params.airHumidityRange.$1,
        params.airHumidityRange.$2,
      ],
      'soilPhRange': [params.soilPhRange.$1, params.soilPhRange.$2],
      'soilTemperatureRange': [
        params.soilTemperatureRange.$1,
        params.soilTemperatureRange.$2,
      ],
      'airTemperatureRange': [
        params.airTemperatureRange.$1,
        params.airTemperatureRange.$2,
      ],
      'lightRange': [params.lightRange.$1, params.lightRange.$2],
    };
  }
}
