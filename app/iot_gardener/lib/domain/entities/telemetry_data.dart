class TelemetryData {
  final double soilMoisture;
  final double airHumidity;
  final double soilPh;
  final double temperature;
  final double light;
  final DateTime receivedAt;

  const TelemetryData({
    required this.soilMoisture,
    required this.airHumidity,
    required this.soilPh,
    required this.temperature,
    required this.light,
    required this.receivedAt,
  });

  factory TelemetryData.fromMap(Map<String, dynamic> map) {
    return TelemetryData(
      soilMoisture: _toDouble(map['soilMoisture']),
      airHumidity: _toDouble(map['airHumidity']),
      soilPh: _toDouble(map['soilPh']),
      temperature: _toDouble(map['temperature']),
      light: _toDouble(map['light']),
      receivedAt: DateTime.now(),
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? 0;
    }
    return 0;
  }
}
