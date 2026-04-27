import '../utils/converter.dart';

class TelemetryData {
  final double soilTemperature;
  final double soilMoisture;
  final double soilPh;
  final double airTemperature;
  final double airHumidity;
  final double light;
  final DateTime receivedAt;

  const TelemetryData({
    required this.soilTemperature,
    required this.soilMoisture,
    required this.soilPh,
    required this.airTemperature,
    required this.airHumidity,
    required this.light,
    required this.receivedAt,
  });

  factory TelemetryData.fromMap(Map<String, dynamic> map) {
    return TelemetryData(
      soilTemperature: Converter.toDouble(map['soilTemperature']),
      soilMoisture: Converter.toDouble(map['soilMoisture']),
      soilPh: Converter.toDouble(map['soilPh']),
      airTemperature: Converter.toDouble(map['airTemperature']),
      airHumidity: Converter.toDouble(map['airHumidity']),
      light: Converter.toDouble(map['light']),
      receivedAt: DateTime.now(),
    );
  }
}
