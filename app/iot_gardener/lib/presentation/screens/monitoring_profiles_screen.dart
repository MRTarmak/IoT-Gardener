import 'package:flutter/material.dart';

import '../../domain/entities/monitoring_profile_params.dart';

class MonitoringProfilesScreen extends StatefulWidget {
  final Future<List<MonitoringProfileParams>> Function() getProfiles;
  final Future<void> Function(MonitoringProfileParams params) onAddProfile;
  final Future<void> Function(String name) onDeleteProfile;
  final void Function({MonitoringProfileParams? profile}) onSelectProfile;
  final String? selectedProfileName;

  const MonitoringProfilesScreen({
    super.key,
    required this.getProfiles,
    required this.onAddProfile,
    required this.onDeleteProfile,
    required this.onSelectProfile,
    this.selectedProfileName,
  });

  @override
  State<MonitoringProfilesScreen> createState() =>
      _MonitoringProfilesScreenState();
}

class _MonitoringProfilesScreenState extends State<MonitoringProfilesScreen> {
  late Future<List<MonitoringProfileParams>> _profilesFuture;

  @override
  void initState() {
    super.initState();
    _refreshProfiles();
  }

  void _refreshProfiles() {
    if (!mounted) return;
    setState(() {
      _profilesFuture = widget.getProfiles();
    });
  }

  Future<void> _onDelete(String name) async {
    await widget.onDeleteProfile(name);
    if (!mounted) return;
    _refreshProfiles();
  }

  Future<void> _onAdd() async {
    final newProfile = await _showAddProfileDialog();
    if (newProfile == null) return;

    await widget.onAddProfile(newProfile);
    if (!mounted) return;
    _refreshProfiles();
  }

  double? _parseOptionalDouble(String value) {
    final normalized = value.trim().replaceAll(',', '.');
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  Future<MonitoringProfileParams?> _showAddProfileDialog() async {
    final formKey = GlobalKey<FormState>();

    final nameController = TextEditingController();

    final soilMinController = TextEditingController();
    final soilMaxController = TextEditingController();
    final airMinController = TextEditingController();
    final airMaxController = TextEditingController();
    final phMinController = TextEditingController();
    final phMaxController = TextEditingController();
    final tempMinController = TextEditingController();
    final tempMaxController = TextEditingController();
    final lightMinController = TextEditingController();
    final lightMaxController = TextEditingController();

    String? rangeOrderError;
    String? boundsError;
    String? atLeastOneParamError;

    final result = await showDialog<MonitoringProfileParams>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            String? numberValidator(String? value) {
              if (value == null || value.trim().isEmpty) return null;
              return _parseOptionalDouble(value) == null
                  ? 'Введите число'
                  : null;
            }

            return AlertDialog(
              title: const Text('Новый профиль'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Название профиля *',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Введите название';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Заполните хотя бы одну границу любого параметра.',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                      const SizedBox(height: 12),
                      _buildRangeFields(
                        label: 'Влажность почвы (%)',
                        minController: soilMinController,
                        maxController: soilMaxController,
                        validator: numberValidator,
                      ),
                      _buildRangeFields(
                        label: 'Влажность воздуха (%)',
                        minController: airMinController,
                        maxController: airMaxController,
                        validator: numberValidator,
                      ),
                      _buildRangeFields(
                        label: 'Кислотность почвы (pH)',
                        minController: phMinController,
                        maxController: phMaxController,
                        validator: numberValidator,
                      ),
                      _buildRangeFields(
                        label: 'Температура (°C)',
                        minController: tempMinController,
                        maxController: tempMaxController,
                        validator: numberValidator,
                      ),
                      _buildRangeFields(
                        label: 'Освещенность (лк)',
                        minController: lightMinController,
                        maxController: lightMaxController,
                        validator: numberValidator,
                      ),
                      if (rangeOrderError != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          rangeOrderError!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                      if (boundsError != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          boundsError!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                      if (atLeastOneParamError != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          atLeastOneParamError!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Отмена'),
                ),
                FilledButton(
                  onPressed: () {
                    final isValid = formKey.currentState?.validate() ?? false;
                    if (!isValid) return;

                    final soilMin = _parseOptionalDouble(
                      soilMinController.text,
                    );
                    final soilMax = _parseOptionalDouble(
                      soilMaxController.text,
                    );
                    final airMin = _parseOptionalDouble(airMinController.text);
                    final airMax = _parseOptionalDouble(airMaxController.text);
                    final phMin = _parseOptionalDouble(phMinController.text);
                    final phMax = _parseOptionalDouble(phMaxController.text);
                    final tempMin = _parseOptionalDouble(
                      tempMinController.text,
                    );
                    final tempMax = _parseOptionalDouble(
                      tempMaxController.text,
                    );
                    final lightMin = _parseOptionalDouble(
                      lightMinController.text,
                    );
                    final lightMax = _parseOptionalDouble(
                      lightMaxController.text,
                    );

                    bool invalidRange(double? min, double? max) {
                      return min != null && max != null && min > max;
                    }

                    if (invalidRange(soilMin, soilMax) ||
                        invalidRange(airMin, airMax) ||
                        invalidRange(phMin, phMax) ||
                        invalidRange(tempMin, tempMax) ||
                        invalidRange(lightMin, lightMax)) {
                      setDialogState(() {
                        rangeOrderError =
                            'Максимальное значение не может быть меньше минимального';
                      });
                      return;
                    }

                    if (rangeOrderError != null) {
                      setDialogState(() {
                        rangeOrderError = null;
                      });
                    }

                    String? invalidBoundsMessage() {
                      bool outOfRange(double? value, double min, double max) {
                        return value != null && (value < min || value > max);
                      }

                      bool belowMin(double? value, double min) {
                        return value != null && value < min;
                      }

                      if (outOfRange(soilMin, 0, 100) ||
                          outOfRange(soilMax, 0, 100)) {
                        return 'Влажность почвы должна быть в диапазоне 0..100%';
                      }

                      if (outOfRange(airMin, 0, 100) ||
                          outOfRange(airMax, 0, 100)) {
                        return 'Влажность воздуха должна быть в диапазоне 0..100%';
                      }

                      if (outOfRange(phMin, 0, 14) ||
                          outOfRange(phMax, 0, 14)) {
                        return 'Кислотность pH должна быть в диапазоне 0..14';
                      }

                      if (belowMin(tempMin, -273.15) ||
                          belowMin(tempMax, -273.15)) {
                        return 'Температура не может быть ниже -273.15°C';
                      }

                      if (belowMin(lightMin, 0) || belowMin(lightMax, 0)) {
                        return 'Освещенность не может быть отрицательной';
                      }

                      return null;
                    }

                    final invalidBounds = invalidBoundsMessage();
                    if (invalidBounds != null) {
                      setDialogState(() {
                        boundsError = invalidBounds;
                      });
                      return;
                    }

                    if (boundsError != null) {
                      setDialogState(() {
                        boundsError = null;
                      });
                    }

                    final hasAtLeastOneParam = [
                      soilMin,
                      soilMax,
                      airMin,
                      airMax,
                      phMin,
                      phMax,
                      tempMin,
                      tempMax,
                      lightMin,
                      lightMax,
                    ].any((value) => value != null);

                    if (!hasAtLeastOneParam) {
                      setDialogState(() {
                        atLeastOneParamError =
                            'Укажите хотя бы одну границу любого параметра';
                      });
                      return;
                    }

                    if (atLeastOneParamError != null) {
                      setDialogState(() {
                        atLeastOneParamError = null;
                      });
                    }

                    Navigator.of(context).pop(
                      MonitoringProfileParams(
                        name: nameController.text.trim(),
                        soilMoistureRange: (soilMin, soilMax),
                        airHumidityRange: (airMin, airMax),
                        soilPhRange: (phMin, phMax),
                        temperatureRange: (tempMin, tempMax),
                        lightRange: (lightMin, lightMax),
                      ),
                    );
                  },
                  child: const Text('Добавить'),
                ),
              ],
            );
          },
        );
      },
    );

    return result;
  }

  Widget _buildRangeFields({
    required String label,
    required TextEditingController minController,
    required TextEditingController maxController,
    required String? Function(String?) validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: minController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Мин',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: validator,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: maxController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Макс',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: validator,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }

  String? _formatRange((double?, double?) range, String unit) {
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

  String _buildProfileDetails(MonitoringProfileParams profile) {
    final parts = <String>[];

    final soil = _formatRange(profile.soilMoistureRange, '%');
    if (soil != null) parts.add('Почва: $soil');

    final air = _formatRange(profile.airHumidityRange, '%');
    if (air != null) parts.add('Воздух: $air');

    final ph = _formatRange(profile.soilPhRange, '');
    if (ph != null) parts.add('pH: $ph');

    final temp = _formatRange(profile.temperatureRange, '°C');
    if (temp != null) parts.add('Темп: $temp');

    final light = _formatRange(profile.lightRange, ' лк');
    if (light != null) parts.add('Свет: $light');

    if (parts.isEmpty) {
      return 'Границы не заданы';
    }

    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Профили мониторинга',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: FutureBuilder<List<MonitoringProfileParams>>(
              future: _profilesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Ошибка загрузки профилей'));
                }
                final profiles = snapshot.data ?? [];
                if (profiles.isEmpty) {
                  return const Center(child: Text('Нет профилей'));
                }
                return ListView.builder(
                  itemCount: profiles.length,
                  itemBuilder: (context, index) {
                    final profile = profiles[index];
                    final isSelected =
                        widget.selectedProfileName == profile.name;

                    return Card(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primaryContainer
                          : null,
                      child: ListTile(
                        title: Text(profile.name),
                        subtitle: Text(_buildProfileDetails(profile)),
                        selected: isSelected,
                        onTap: () => {
                          if (isSelected)
                            widget.onSelectProfile(profile: null)
                          else
                            widget.onSelectProfile(profile: profile),
                        },
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _onDelete(profile.name),
                          tooltip: 'Удалить',
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Добавить профиль'),
          ),
        ],
      ),
    );
  }
}
