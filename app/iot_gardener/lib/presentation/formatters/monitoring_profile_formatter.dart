import '../../domain/entities/monitoring_profile_params.dart';

class MonitoringProfileFormatter {
  static String formatProfileDetails(MonitoringProfileParams profile) {
    final parts = <String>[];

    final soil = _formatRange(profile.soilMoistureRange, '%');
    if (soil != null) parts.add('Почва: $soil');

    final air = _formatRange(profile.airHumidityRange, '%');
    if (air != null) parts.add('Воздух: $air');

    final ph = _formatRange(profile.soilPhRange, '');
    if (ph != null) parts.add('pH: $ph');

    final soilTemp = _formatRange(profile.soilTemperatureRange, '°C');
    if (soilTemp != null) parts.add('Темп. почвы: $soilTemp');

    final airTemp = _formatRange(profile.airTemperatureRange, '°C');
    if (airTemp != null) parts.add('Темп. воздуха: $airTemp');

    final light = _formatRange(profile.lightRange, ' лк');
    if (light != null) parts.add('Свет: $light');

    if (parts.isEmpty) {
      return 'Границы не заданы';
    }

    return parts.join(' · ');
  }

  static String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }

  static String? _formatRange((double?, double?) range, String unit) {
    final min = range.$1;
    final max = range.$2;

    if (min == null && max == null) return null;

    if (min != null && max != null) {
      return '${_formatNumber(min)}$unit - ${_formatNumber(max)}$unit';
    }
    if (min != null) {
      return '>= ${_formatNumber(min)}$unit';
    }
    return '<= ${_formatNumber(max!)}$unit';
  }
}
