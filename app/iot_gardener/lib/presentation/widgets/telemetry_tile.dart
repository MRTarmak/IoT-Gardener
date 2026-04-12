import 'package:flutter/material.dart';

class TelemetryTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isOutOfRange;

  const TelemetryTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.isOutOfRange = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: isOutOfRange ? colorScheme.errorContainer : null,
      child: ListTile(
        leading: Icon(icon, color: isOutOfRange ? colorScheme.error : Colors.green),
        title: Text(label, style: TextStyle(fontSize: 16)),
        trailing: Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isOutOfRange ? colorScheme.error : null,
          ),
        ),
      ),
    );
  }
}
