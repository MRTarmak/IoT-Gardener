import '../utils/converter.dart';

class MonitoringProfileParams {
  final String name;
  final (double, double) soilMoistureRange;
  final (double, double) airHumidityRange;
  final (double, double) soilPhRange;
  final (double, double) temperatureRange;
  final (double, double) lightRange;

  const MonitoringProfileParams({
    required this.name,
    required this.soilMoistureRange,
    required this.airHumidityRange,
    required this.soilPhRange,
    required this.temperatureRange,
    required this.lightRange,
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