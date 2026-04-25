import '../entities/monitoring_profile_params.dart';

class MonitoringProfileValidator {
  static String? validate(MonitoringProfileParams params) {
    final hasAtLeastOneParam = [
      params.soilMoistureRange.$1,
      params.soilMoistureRange.$2,
      params.airHumidityRange.$1,
      params.airHumidityRange.$2,
      params.soilPhRange.$1,
      params.soilPhRange.$2,
      params.soilTemperatureRange.$1,
      params.soilTemperatureRange.$2,
      params.airTemperatureRange.$1,
      params.airTemperatureRange.$2,
      params.lightRange.$1,
      params.lightRange.$2,
    ].any((value) => value != null);

    if (!hasAtLeastOneParam) {
      return 'Укажите хотя бы одну границу любого параметра';
    }

    bool invalidRange((double?, double?) range) {
      final min = range.$1;
      final max = range.$2;
      return min != null && max != null && min > max;
    }

    if (invalidRange(params.soilMoistureRange) ||
        invalidRange(params.airHumidityRange) ||
        invalidRange(params.soilPhRange) ||
        invalidRange(params.soilTemperatureRange) ||
        invalidRange(params.airTemperatureRange) ||
        invalidRange(params.lightRange)) {
      return 'Максимальное значение не может быть меньше минимального';
    }

    bool outOfRange(double? value, double min, double max) {
      return value != null && (value < min || value > max);
    }

    bool belowMin(double? value, double min) {
      return value != null && value < min;
    }

    if (outOfRange(params.soilMoistureRange.$1, 0, 100) ||
        outOfRange(params.soilMoistureRange.$2, 0, 100)) {
      return 'Влажность почвы должна быть в диапазоне 0..100%';
    }

    if (outOfRange(params.airHumidityRange.$1, 0, 100) ||
        outOfRange(params.airHumidityRange.$2, 0, 100)) {
      return 'Влажность воздуха должна быть в диапазоне 0..100%';
    }

    if (outOfRange(params.soilPhRange.$1, 0, 14) ||
        outOfRange(params.soilPhRange.$2, 0, 14)) {
      return 'Кислотность pH должна быть в диапазоне 0..14';
    }

    if (belowMin(params.soilTemperatureRange.$1, -273.15) ||
        belowMin(params.soilTemperatureRange.$2, -273.15)) {
      return 'Температура почвы не может быть ниже -273.15°C';
    }

    if (belowMin(params.airTemperatureRange.$1, -273.15) ||
        belowMin(params.airTemperatureRange.$2, -273.15)) {
      return 'Температура воздуха не может быть ниже -273.15°C';
    }

    if (belowMin(params.lightRange.$1, 0) ||
        belowMin(params.lightRange.$2, 0)) {
      return 'Освещенность не может быть отрицательной';
    }

    return null;
  }
}
