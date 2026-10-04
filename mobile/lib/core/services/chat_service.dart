import 'dart:async';

import 'package:dio/dio.dart';

import '../api/api_client.dart';
import '../models/models.dart';

/// Chat service: history, send, and SSE streaming.
class ChatService {
  Dio get _dio => ApiClient.instance.dio;

  Future<List<Message>> history(String threadId) async {
    final res = await _dio.get('/chat/history/$threadId');
    final data = res.data;
    final list = data is List ? data : (data['messages'] as List? ?? const []);
    return list.map((e) => Message.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> send({
    required String threadId,
    required String botId,
    required String userText,
    String? model,
    String? imageUrl,
  }) async {
    await _dio.post(
      '/chat/send',
      data: {
        'thread_id': threadId,
        'bot_id': botId,
        'user_text': userText,
        if (model != null && model.isNotEmpty) 'model': model,
        if (imageUrl != null && imageUrl.isNotEmpty) 'image_url': imageUrl,
      },
    );
  }

  /// Subscribes to the SSE chat stream for a thread.
  /// Returns a cancellation function (like the web client's cleanup).
  Future<Stream<Map<String, dynamic>>> stream(String threadId,
      {String? model}) async {
    final config = ApiClient.instance.dio.options;
    final uri = Uri.parse(config.baseUrl!).replace(path: '/chat/stream/$threadId',
        queryParameters: {
          if (model != null && model.isNotEmpty) 'model': model,
        });

    final controller = StreamController<Map<String, dynamic>>();
    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      final token = config.headers['Authorization'];
      if (token != null) request.headers.set('Authorization', token);
      request.headers.set('Accept', 'text/event-stream');
      final response = await request.close();

      if (response.statusCode != 200) {
        controller.addError('Stream failed: HTTP ${response.statusCode}');
        await response.drain();
        await client.close();
        await controller.close();
        return controller.stream;
      }

      response
          .transform(const LineSplitter())
          .listen(
        (line) {
          if (line.startsWith('data:')) {
            final payload = line.substring(5).trim();
            if (payload.isEmpty || payload == '[DONE]') return;
            try {
              final json = {
                'raw': payload,
                // The backend streams JSON payloads or text deltas; pass both.
                'text': payload,
              };
              controller.add(json);
            } catch (_) {
              controller.add({'text': payload});
            }
          }
        },
        onDone: () async {
          await controller.close();
          client.close();
        },
        onError: (e) async {
          controller.addError(e);
          await controller.close();
          client.close();
        },
        cancelOnError: true,
      );
    } catch (e) {
      controller.addError(e);
      await controller.close();
    }
    return controller.stream;
  }
}
