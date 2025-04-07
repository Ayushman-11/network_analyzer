import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppBar(
          title: const Text('About'),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: const [
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.network_check,
                        size: 64,
                        color: Colors.blue,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Network Analyzer',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Version 1.0.0',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: Icon(Icons.description),
                  title: Text('Description'),
                  subtitle: Text(
                    'Network Analyzer is a powerful tool for monitoring and analyzing your network connections, speed, and performance.',
                  ),
                ),
              ),
              SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: Icon(Icons.code),
                  title: Text('Developer'),
                  subtitle: Text('Your Name'),
                ),
              ),
              SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: Icon(Icons.email),
                  title: Text('Contact'),
                  subtitle: Text('your.email@example.com'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
