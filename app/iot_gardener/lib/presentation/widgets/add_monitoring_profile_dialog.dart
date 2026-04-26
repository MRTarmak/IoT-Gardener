import 'package:flutter/material.dart';

import '../../domain/entities/monitoring_profile_params.dart';
import '../../domain/validators/monitoring_profile_validator.dart';

Future<MonitoringProfileParams?> showAddMonitoringProfileDialog(
  BuildContext context,
) {
  return showDialog<MonitoringProfileParams>(
    context: context,
    builder: (context) => const _AddMonitoringProfileDialog(),
  );
}

class _AddMonitoringProfileDialog extends StatefulWidget {
  const _AddMonitoringProfileDialog();

  @override
  State<_AddMonitoringProfileDialog> createState() =>
      _AddMonitoringProfileDialogState();
}

class _AddMonitoringProfileDialogState
    extends State<_AddMonitoringProfileDialog> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();

  final _soilMinController = TextEditingController();
  final _soilMaxController = TextEditingController();
  final _airMinController = TextEditingController();
  final _airMaxController = TextEditingController();
  final _phMinController = TextEditingController();
  final _phMaxController = TextEditingController();
  final _tempMinController = TextEditingController();
  final _tempMaxController = TextEditingController();
  final _lightMinController = TextEditingController();
  final _lightMaxController = TextEditingController();

  String? _validationError;

  @override
  void dispose() {
    _nameController.dispose();
    _soilMinController.dispose();
    _soilMaxController.dispose();
    _airMinController.dispose();
    _airMaxController.dispose();
    _phMinController.dispose();
    _phMaxController.dispose();
    _tempMinController.dispose();
    _tempMaxController.dispose();
    _lightMinController.dispose();
    _lightMaxController.dispose();
    super.dispose();
  }

  double? _parseOptionalDouble(String value) {
    final normalized = value.trim().replaceAll(',', '.');
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  String? _numberValidator(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return _parseOptionalDouble(value) == null ? 'Введите число' : null;
  }

  void _submit() {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    final params = MonitoringProfileParams(
      name: _nameController.text.trim(),
      soilMoistureRange: (
        _parseOptionalDouble(_soilMinController.text),
        _parseOptionalDouble(_soilMaxController.text),
      ),
      airHumidityRange: (
        _parseOptionalDouble(_airMinController.text),
        _parseOptionalDouble(_airMaxController.text),
      ),
      soilPhRange: (
        _parseOptionalDouble(_phMinController.text),
        _parseOptionalDouble(_phMaxController.text),
      ),
      temperatureRange: (
        _parseOptionalDouble(_tempMinController.text),
        _parseOptionalDouble(_tempMaxController.text),
      ),
      lightRange: (
        _parseOptionalDouble(_lightMinController.text),
        _parseOptionalDouble(_lightMaxController.text),
      ),
    );

    final validationError = MonitoringProfileValidator.validate(params);
    if (validationError != null) {
      setState(() {
        _validationError = validationError;
      });
      return;
    }

    Navigator.of(context).pop(params);
  }

  Widget _buildRangeFields({
    required String label,
    required TextEditingController minController,
    required TextEditingController maxController,
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
                  validator: _numberValidator,
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
                  validator: _numberValidator,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Новый профиль'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
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
                minController: _soilMinController,
                maxController: _soilMaxController,
              ),
              _buildRangeFields(
                label: 'Влажность воздуха (%)',
                minController: _airMinController,
                maxController: _airMaxController,
              ),
              _buildRangeFields(
                label: 'Кислотность почвы (pH)',
                minController: _phMinController,
                maxController: _phMaxController,
              ),
              _buildRangeFields(
                label: 'Температура (°C)',
                minController: _tempMinController,
                maxController: _tempMaxController,
              ),
              _buildRangeFields(
                label: 'Освещенность (лк)',
                minController: _lightMinController,
                maxController: _lightMaxController,
              ),
              if (_validationError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _validationError!,
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
        FilledButton(onPressed: _submit, child: const Text('Добавить')),
      ],
    );
  }
}
