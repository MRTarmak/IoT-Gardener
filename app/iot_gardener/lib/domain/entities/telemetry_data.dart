import '../utils/converter.dart';

class TelemetryData {
  final double soilMoisture;
  final double airHumidity;
  final double soilPh;
  final double soilTemperature;
  final double airTemperature;
  final double light;
  final DateTime receivedAt;

  const TelemetryData({
    required this.soilMoisture,
    required this.airHumidity,
    required this.soilPh,
    required this.soilTemperature,
    required this.airTemperature,
    required this.light,
    required this.receivedAt,
  });

  factory TelemetryData.fromMap(Map<String, dynamic> map) {
    return TelemetryData(
      soilMoisture: Converter.toDouble(map['soilMoisture']),
      airHumidity: Converter.toDouble(map['airHumidity']),
      soilPh: Converter.toDouble(map['soilPh']),
      soilTemperature: Converter.toDouble(map['soilTemperature']),
      airTemperature: Converter.toDouble(map['airTemperature']),
      light: Converter.toDouble(map['light']),
      receivedAt: DateTime.now(),
    );
  }
}
