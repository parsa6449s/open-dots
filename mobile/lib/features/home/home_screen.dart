import 'package:flutter/material.dart';

import '../settings/settings_screen.dart';

/// Home screen placeholder. Bot list and chat arrive in the next steps.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.baseUrl});

  final String baseUrl;

  @override
  Widget build(BuildContext context) {
    final configured = baseUrl.isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Open Dots'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              configured ? Icons.check_circle : Icons.warning,
              size: 64,
              color: configured ? Colors.green : Colors.orange,
            ),
            const SizedBox(height: 16),
            Text(configured ? 'Server configured' : 'Server not configured'),
            if (!configured) ...[
              const SizedBox(height: 8),
              const Text('Open settings and set the server URL and token.'),
            ],
          ],
        ),
      ),
    );
  }
}
