import '../utils/converter.dart';

class MonitoringProfileParams {
  final String name;
  final (double?, double?) soilTemperatureRange;
  final (double?, double?) soilMoistureRange;
  final (double?, double?) soilPhRange;
  final (double?, double?) airTemperatureRange;
  final (double?, double?) airHumidityRange;
  final (double?, double?) lightRange;

  const MonitoringProfileParams({
    required this.name,
    this.soilTemperatureRange = (null, null),
    this.soilMoistureRange = (null, null),
    this.soilPhRange = (null, null),
    this.airTemperatureRange = (null, null),
    this.airHumidityRange = (null, null),
    this.lightRange = (null, null),
  });

  factory MonitoringProfileParams.fromMap(Map<String, dynamic> map) {
    return MonitoringProfileParams(
      name: map['name'] ?? 'Unnamed Profile',
      soilTemperatureRange: Converter.toRange(map['soilTemperatureRange']),
      soilMoistureRange: Converter.toRange(map['soilMoistureRange']),
      soilPhRange: Converter.toRange(map['soilPhRange']),
      airTemperatureRange: Converter.toRange(map['airTemperatureRange']),
      airHumidityRange: Converter.toRange(map['airHumidityRange']),
      lightRange: Converter.toRange(map['lightRange']),
    );
  }
}