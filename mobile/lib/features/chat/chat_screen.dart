import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/models/models.dart';
import '../../core/services/chat_service.dart';

/// Chat screen with SSE streaming (stage 3).
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.bot});

  final Bot bot;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _service = ChatService();
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<_ChatEntry> _entries = [];
  StreamSubscription? _sub;
  String? _threadId;
  bool _streaming = false;

  @override
  void dispose() {
    _cancelStream();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _cancelStream() {
    _sub?.cancel();
    _sub = null;
    if (mounted) setState(() => _streaming = false);
  }

  Future<void> _loadHistory() async {
    final threadId = _threadId;
    if (threadId == null) return;
    try {
      final history = await _service.history(threadId);
      if (!mounted) return;
      setState(() {
        _entries
          ..clear()
          ..addAll(history.map((m) => _ChatEntry(
                sender: m.sender,
                text: m.text,
              )));
      });
      _scrollToBottom();
    } catch (_) {
      // New thread has no history yet; ignore.
    }
  }

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _streaming) return;
    _inputCtrl.clear();

    final threadId = _threadId ??
        'thread-${DateTime.now().millisecondsSinceEpoch}-${widget.bot.id}';
    _threadId = threadId;

    setState(() {
      _entries.add(_ChatEntry(sender: 'user', text: text));
      _streaming = true;
    });
    _scrollToBottom();

    try {
      await _service.send(
        threadId: threadId,
        botId: widget.bot.id,
        userText: text,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _entries.add(_ChatEntry(sender: 'system', text: 'Send failed: $e'));
      });
    }

    // Subscribe to the SSE stream for assistant output.
    await _loadHistory();
    _listenStream(threadId);
  }

  void _listenStream(String threadId) {
    _sub?.cancel();
    setState(() {
      _entries.add(_ChatEntry(sender: 'bot', text: ''));
    });
    _service.stream(threadId).then((stream) {
      _sub = stream.listen(
        (event) {
          if (!mounted) return;
          setState(() {
            final last = _entries.last;
            if (last.sender == 'bot') {
              last.text += (event['text'] as String? ?? '');
            } else {
              _entries.add(_ChatEntry(
                  sender: 'bot', text: event['text'] as String? ?? ''));
            }
          });
          _scrollToBottom();
        },
        onError: (e) {
          if (!mounted) return;
          setState(() {
            _entries.add(_ChatEntry(sender: 'system', text: 'Stream error: $e'));
          });
          _cancelStream();
        },
        onDone: () => _cancelStream(),
      );
    }).catchError((e) {
      if (!mounted) return;
      setState(() {
        _entries.add(_ChatEntry(sender: 'system', text: 'Stream failed: $e'));
      });
      _cancelStream();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.bot.name)),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(12),
              itemCount: _entries.length,
              itemBuilder: (_, i) {
                final e = _entries[i];
                final isUser = e.sender == 'user';
                final isSystem = e.sender == 'system';
                return Align(
                  alignment: isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.8),
                    decoration: BoxDecoration(
                      color: isSystem
                          ? Colors.red.shade900
                          : isUser
                              ? Colors.cyan.shade700
                              : Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SelectableText(
                      e.text.isEmpty && e.sender == 'bot' && _streaming
                          ? '…'
                          : e.text,
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputCtrl,
                      enabled: !_streaming,
                      decoration: const InputDecoration(
                        hintText: 'Message...',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _streaming ? null : _send,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatEntry {
  _ChatEntry({required this.sender, required this.text});

  final String sender;
  String text;
}
