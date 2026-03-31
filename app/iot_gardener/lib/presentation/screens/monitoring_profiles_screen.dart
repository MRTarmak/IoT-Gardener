import 'package:flutter/material.dart';

import '../../domain/entities/monitoring_profile_params.dart';

class MonitoringProfilesScreen extends StatefulWidget {
  final Future<List<MonitoringProfileParams>> Function() getProfiles;
  final Future<void> Function(MonitoringProfileParams params) onAddProfile;
  final Future<void> Function(String name) onDeleteProfile;
  final void Function({MonitoringProfileParams? profile}) onSelectProfile;

  const MonitoringProfilesScreen({
    super.key,
    required this.getProfiles,
    required this.onAddProfile,
    required this.onDeleteProfile,
    required this.onSelectProfile,
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
    setState(() {
      _profilesFuture = widget.getProfiles();
    });
  }

  Future<void> _onDelete(String name) async {
    await widget.onDeleteProfile(name);
    _refreshProfiles();
  }

  Future<void> _onAdd() async {
    // TODO сделать нормальный ввод параметров вместо заглушки
    final newProfile = MonitoringProfileParams(
      name: 'Новый профиль',
      soilMoistureRange: (0.2, 0.8),
      airHumidityRange: (30, 70),
      soilPhRange: (5.5, 7.5),
      temperatureRange: (15, 30),
      lightRange: (200, 1000),
    );
    await widget.onAddProfile(newProfile);
    _refreshProfiles();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
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
                return ListView.separated(
                  itemCount: profiles.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final profile = profiles[index];
                    return Card(
                      child: ListTile(
                        title: Text(profile.name),
                        subtitle: Text(
                          'Параметры: ...',
                        ), // TODO добавить детали
                        onTap: () => widget.onSelectProfile(
                          profile: profile,
                        ), // TODO выделить выбранный профиль
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
