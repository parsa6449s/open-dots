import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/config/app_config.dart';

/// Settings screen: server base URL and app auth token (stored on device).
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _baseUrlCtrl;
  late final TextEditingController _tokenCtrl;
  bool _saving = false;
  String? _status;

  @override
  void initState() {
    super.initState();
    _baseUrlCtrl = TextEditingController();
    _tokenCtrl = TextEditingController();
    _load();
  }

  Future<void> _load() async {
    final config = await AppConfig.load();
    if (!mounted) return;
    setState(() {
      _baseUrlCtrl.text = config.baseUrl;
      _tokenCtrl.text = config.authToken;
    });
  }

  Future<void> _save() async {
    final url = _baseUrlCtrl.text.trim();
    if (url.isEmpty || !Uri.tryParse(url)!.hasScheme) {
      setState(() => _status = 'Enter a valid http(s) server URL.');
      return;
    }
    setState(() => _saving = true);
    try {
      await AppConfig.saveBaseUrl(url);
      await AppConfig.saveAuthToken(_tokenCtrl.text);
      await ApiClient.configure();
      // Sanity check against the backend.
      await ApiClient.instance.dio.get('/models');
      if (!mounted) return;
      setState(() => _status = 'Saved. Server reachable.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = 'Saved, but server check failed: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _baseUrlCtrl.dispose();
    _tokenCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _baseUrlCtrl,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'Server base URL',
              hintText: 'https://your-server.example.com',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _tokenCtrl,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'App auth token (APP_AUTH_TOKEN)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Saving...' : 'Save & test connection'),
          ),
          if (_status != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(_status!),
            ),
        ],
      ),
    );
  }
}
