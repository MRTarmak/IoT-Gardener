import '../utils/converter.dart';

class MonitoringProfileParams {
  final String name;
  final (double?, double?) soilMoistureRange;
  final (double?, double?) airHumidityRange;
  final (double?, double?) soilPhRange;
  final (double?, double?) temperatureRange;
  final (double?, double?) lightRange;

  const MonitoringProfileParams({
    required this.name,
    this.soilMoistureRange = (null, null),
    this.airHumidityRange = (null, null),
    this.soilPhRange = (null, null),
    this.temperatureRange = (null, null),
    this.lightRange = (null, null),
  });

  factory MonitoringProfileParams.fromMap(Map<String, dynamic> map) {
    return MonitoringProfileParams(
      name: map['name'] ?? 'Unnamed Profile',
      soilMoistureRange: Converter.toRange(map['soilMoistureRange']),
      airHumidityRange: Converter.toRange(map['airHumidityRange']),
      soilPhRange: Converter.toRange(map['soilPhRange']),
      temperatureRange: Converter.toRange(map['temperatureRange']),
      lightRange: Converter.toRange(map['lightRange']),
    );
  }
}