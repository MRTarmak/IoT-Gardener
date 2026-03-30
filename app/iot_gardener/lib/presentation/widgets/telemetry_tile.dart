import 'package:flutter/material.dart';

class TelemetryTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const TelemetryTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: Colors.green),
        title: Text(label, style: TextStyle(fontSize: 16)),
        trailing: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}
