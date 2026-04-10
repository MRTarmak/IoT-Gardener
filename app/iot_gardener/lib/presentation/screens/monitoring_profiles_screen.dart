import 'package:flutter/material.dart';

import '../../domain/entities/monitoring_profile_params.dart';
import '../formatters/monitoring_profile_formatter.dart';
import '../widgets/add_monitoring_profile_dialog.dart';

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
    final newProfile = await showAddMonitoringProfileDialog(context);
    if (newProfile == null) return;

    await widget.onAddProfile(newProfile);
    if (!mounted) return;
    _refreshProfiles();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MonitoringProfileParams>>(
      future: _profilesFuture,
      builder: (context, snapshot) {
        Widget content = CustomScrollView(
          slivers: [
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Профили мониторинга',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        );

        if (snapshot.connectionState == ConnectionState.waiting) {
          content = CustomScrollView(
            slivers: [
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'Профили мониторинга',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
          );
        } else if (snapshot.hasError) {
          content = CustomScrollView(
            slivers: [
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'Профили мониторинга',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text('Ошибка загрузки профилей')),
              ),
            ],
          );
        } else {
          final profiles = snapshot.data ?? [];

          if (profiles.isEmpty) {
            content = CustomScrollView(
              slivers: [
                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      'Профили мониторинга',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'Нет профилей',
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  ),
                ),
              ],
            );
          } else {
            content = CustomScrollView(
              slivers: [
                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      'Профили мониторинга',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList.builder(
                    itemCount: profiles.length,
                    itemBuilder: (context, index) {
                      final profile = profiles[index];
                      final isSelected = widget.selectedProfileName == profile.name;

                      return Card(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primaryContainer
                            : null,
                        child: ListTile(
                          title: Text(profile.name),
                            subtitle: Text(
                              MonitoringProfileFormatter.formatProfileDetails(
                                profile,
                              ),
                            ),
                          selected: isSelected,
                          onTap: () {
                            if (isSelected) {
                              widget.onSelectProfile(profile: null);
                            } else {
                              widget.onSelectProfile(profile: profile);
                            }
                          },
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _onDelete(profile.name),
                            tooltip: 'Удалить',
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 70)),
              ],
            );
          }
        }

        return Stack(
          children: [
            Positioned.fill(child: content),
            Positioned(
              right: 16,
              bottom: 16,
              child: SizedBox(
                width: 56,
                height: 56,
                child: FloatingActionButton(
                  onPressed: _onAdd,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  tooltip: 'Добавить профиль',
                  child: const Icon(Icons.add),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
