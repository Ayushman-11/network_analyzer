import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppBar(
          title: const Text('Scan History'),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: 10, // TODO: Replace with actual history count
            itemBuilder: (context, index) {
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.history),
                  title: Text('Scan ${index + 1}'),
                  subtitle: Text(
                      DateTime.now().subtract(Duration(hours: index)).toString().substring(0, 16)),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // TODO: Show detailed scan results
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
