import 'package:dio/dio.dart';

import '../api/api_client.dart';
import '../models/models.dart';

/// Bots CRUD + available models.
class BotsService {
  Dio get _dio => ApiClient.instance.dio;

  Future<List<Bot>> listBots() async {
    final res = await _dio.get('/bots');
    final data = res.data;
    final list = data is List ? data : (data['bots'] as List? ?? const []);
    return list.map((e) => Bot.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Bot> createBot(Bot bot) async {
    final res = await _dio.post('/bots', data: bot.toCreateJson());
    return Bot.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Bot> updateBot(String botId, Bot bot) async {
    final res = await _dio.put('/bots/$botId', data: bot.toCreateJson());
    return Bot.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> deleteBot(String botId) async {
    await _dio.delete('/bots/$botId');
  }

  Future<List<ModelInfo>> listModels() async {
    final res = await _dio.get('/models');
    final data = res.data;
    final list = data is List ? data : (data['models'] as List? ?? const []);
    return list
        .map((e) => ModelInfo.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
