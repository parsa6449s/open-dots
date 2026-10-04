import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/models/models.dart';
import '../../core/services/bots_service.dart';
import '../chat/chat_screen.dart';

/// Bot list + model picker (stage 2).
class BotsScreen extends StatefulWidget {
  const BotsScreen({super.key});

  @override
  State<BotsScreen> createState() => _BotsScreenState();
}

class _BotsScreenState extends State<BotsScreen> {
  final _service = BotsService();
  List<Bot>? _bots;
  List<ModelInfo> _models = const [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _error = null;
    });
    try {
      final bots = await _service.listBots();
      final models = await _service.listModels();
      if (!mounted) return;
      setState(() {
        _bots = bots;
        _models = models;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _bots = const [];
        _error = 'Failed to load: $e\nCheck server URL & token in settings.';
      });
    }
  }

  Future<void> _openChat(Bot bot) async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChatScreen(bot: bot)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bots = _bots;
    return Scaffold(
      appBar: AppBar(title: const Text('Bots')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(),
        child: const Icon(Icons.add),
      ),
      body: bots == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: _error != null
                  ? ListView(children: [Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(_error!))])
                  : bots.isEmpty
                      ? ListView(children: const [
                          Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('No bots yet. Tap + to create one.'),
                          )
                        ])
                      : ListView.builder(
                          itemCount: bots.length,
                          itemBuilder: (_, i) {
                            final bot = bots[i];
                            return ListTile(
                              leading: Text(bot.avatar,
                                  style: const TextStyle(fontSize: 28)),
                              title: Text(bot.name),
                              subtitle: Text(bot.role),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => _openChat(bot),
                            );
                          },
                        ),
            ),
    );
  }

  Future<void> _showCreateDialog() async {
    final nameCtrl = TextEditingController();
    final roleCtrl = TextEditingController();
    String model = _models.isNotEmpty ? _models.first.id : 'gpt-5-mini';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: const Text('Create bot'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: roleCtrl,
                decoration: const InputDecoration(labelText: 'Role'),
              ),
              DropdownButtonFormField<String>(
                initialValue: model,
                items: _models
                    .map((m) => DropdownMenuItem(value: m.id, child: Text(m.name)))
                    .toList(),
                onChanged: (v) => setDialog(() => model = v ?? model),
                decoration: const InputDecoration(labelText: 'Model'),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Create')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final name = nameCtrl.text.trim();
    if (name.isEmpty) return;
    try {
      await _service.createBot(Bot(
        id: 'bot-${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        role: roleCtrl.text.trim(),
        description: '',
        avatar: '🤖',
        model: model,
        accentColor: 'cyan',
        systemPrompt: 'You are $name, a helpful assistant.',
        tools: const [],
        pinned: false,
        createdAt: '',
      ));
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Create failed: $e')));
    }
  }
}
