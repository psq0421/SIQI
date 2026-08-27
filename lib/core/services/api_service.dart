import 'dart:convert';

import 'package:dio/dio.dart';

import '../models/app_models.dart';

class ApiService {
  const ApiService(this._dio);
  final Dio _dio;

  Stream<CompletionChunk> streamComplete({
    required ApiProfile profile,
    required String apiKey,
    required List<ChatMessage> messages,
    required String systemPrompt,
    required double temperature,
    required double topP,
    required int maxTokens,
    String? modelId,
    CancelToken? cancelToken,
  }) async* {
    if (profile.format == ApiFormat.local) {
      throw StateError('Local model must use the local inference service.');
    }
    final openAi = profile.format == ApiFormat.openAi;
    final selectedModelId = profile.resolveModel(modelId);
    final endpoint = _join(
      profile.baseUrl,
      openAi ? 'chat/completions' : 'messages',
    );
    final data = openAi
        ? <String, Object?>{
            'model': selectedModelId,
            'messages': [
              {'role': 'system', 'content': systemPrompt},
              ...messages
                  .where((message) => message.role != MessageRole.system)
                  .map(
                    (message) => {
                      'role': message.role == MessageRole.assistant
                          ? 'assistant'
                          : 'user',
                      'content': _openAiContent(message),
                    },
                  ),
            ],
            'temperature': temperature,
            'top_p': topP,
            'max_tokens': maxTokens,
            'stream': true,
            'stream_options': {'include_usage': true},
          }
        : <String, Object?>{
            'model': selectedModelId,
            'system': systemPrompt,
            'messages': messages
                .where((message) => message.role != MessageRole.system)
                .map(
                  (message) => {
                    'role': message.role == MessageRole.assistant
                        ? 'assistant'
                        : 'user',
                    'content': _anthropicContent(message),
                  },
                )
                .toList(),
            'temperature': temperature,
            'top_p': topP,
            'max_tokens': maxTokens,
            'stream': true,
          };
    final headers = openAi
        ? <String, String>{
            if (apiKey.isNotEmpty) 'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
            ...profile.headers,
          }
        : <String, String>{
            'x-api-key': apiKey,
            'anthropic-version': '2023-06-01',
            'Content-Type': 'application/json',
            ...profile.headers,
          };
    final response = await _dio.post<ResponseBody>(
      endpoint,
      data: data,
      options: Options(headers: headers, responseType: ResponseType.stream),
      cancelToken: cancelToken,
    );
    final body = response.data;
    if (body == null) throw const FormatException('Missing response stream');
    var usage = const TokenUsage();
    await for (final line
        in body.stream
            .cast<List<int>>()
            .transform(utf8.decoder)
            .transform(const LineSplitter())) {
      final normalized = line.trim();
      if (!normalized.startsWith('data:')) continue;
      final raw = normalized.substring(5).trim();
      if (raw.isEmpty || raw == '[DONE]') continue;
      Map<String, dynamic> event;
      try {
        event = jsonDecode(raw) as Map<String, dynamic>;
      } on Object {
        continue;
      }
      if (openAi) {
        final eventUsage = event['usage'] as Map<String, dynamic>?;
        if (eventUsage != null) {
          usage = TokenUsage(
            input: eventUsage['prompt_tokens'] as int? ?? usage.input,
            output: eventUsage['completion_tokens'] as int? ?? usage.output,
          );
        }
        final choices = event['choices'] as List? ?? const [];
        if (choices.isNotEmpty) {
          final delta =
              (choices.first as Map<String, dynamic>)['delta']
                  as Map<String, dynamic>?;
          final text = delta?['content'] as String? ?? '';
          if (text.isNotEmpty) {
            yield CompletionChunk(textDelta: text, usage: usage);
          }
        }
      } else {
        final type = event['type'] as String?;
        if (type == 'content_block_delta') {
          final delta = event['delta'] as Map<String, dynamic>?;
          final text = delta?['text'] as String? ?? '';
          if (text.isNotEmpty) {
            yield CompletionChunk(textDelta: text, usage: usage);
          }
        } else if (type == 'message_start') {
          final message = event['message'] as Map<String, dynamic>?;
          final eventUsage = message?['usage'] as Map<String, dynamic>?;
          usage = TokenUsage(
            input: eventUsage?['input_tokens'] as int? ?? 0,
            output: usage.output,
          );
        } else if (type == 'message_delta') {
          final eventUsage = event['usage'] as Map<String, dynamic>?;
          usage = TokenUsage(
            input: usage.input,
            output: eventUsage?['output_tokens'] as int? ?? usage.output,
          );
        }
      }
    }
    yield CompletionChunk(usage: usage, done: true);
  }

  Future<CompletionResult> testProfile(ApiProfile profile, String apiKey) =>
      complete(
        profile: profile,
        apiKey: apiKey,
        messages: [
          ChatMessage(
            id: 'connection-test',
            sessionId: 'connection-test',
            role: MessageRole.user,
            content: 'ping',
            createdAt: DateTime.now(),
          ),
        ],
        systemPrompt: 'Reply with pong.',
        temperature: 0,
        topP: 1,
        maxTokens: 8,
      );

  Future<CompletionResult> complete({
    required ApiProfile profile,
    required String apiKey,
    required List<ChatMessage> messages,
    required String systemPrompt,
    required double temperature,
    required double topP,
    required int maxTokens,
    String? modelId,
    CancelToken? cancelToken,
  }) async {
    return switch (profile.format) {
      ApiFormat.openAi => _openAi(
        profile,
        apiKey,
        messages,
        systemPrompt,
        temperature,
        topP,
        maxTokens,
        profile.resolveModel(modelId),
        cancelToken,
      ),
      ApiFormat.anthropic => _anthropic(
        profile,
        apiKey,
        messages,
        systemPrompt,
        temperature,
        topP,
        maxTokens,
        profile.resolveModel(modelId),
        cancelToken,
      ),
      ApiFormat.local => throw StateError(
        'Local model must use the local inference service.',
      ),
    };
  }

  Future<CompletionResult> _openAi(
    ApiProfile profile,
    String apiKey,
    List<ChatMessage> messages,
    String systemPrompt,
    double temperature,
    double topP,
    int maxTokens,
    String modelId,
    CancelToken? cancelToken,
  ) async {
    final endpoint = _join(profile.baseUrl, 'chat/completions');
    final response = await _dio.post<Map<String, dynamic>>(
      endpoint,
      data: {
        'model': modelId,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          ...messages
              .where((message) => message.role != MessageRole.system)
              .map(
                (message) => {
                  'role': message.role == MessageRole.assistant
                      ? 'assistant'
                      : 'user',
                  'content': _openAiContent(message),
                },
              ),
        ],
        'temperature': temperature,
        'top_p': topP,
        'max_tokens': maxTokens,
      },
      options: Options(
        headers: {
          if (apiKey.isNotEmpty) 'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
          ...profile.headers,
        },
      ),
      cancelToken: cancelToken,
    );
    final data = response.data ?? const {};
    final choices = data['choices'] as List? ?? const [];
    if (choices.isEmpty) {
      throw const FormatException('Missing completion choice');
    }
    final first = choices.first as Map<String, dynamic>;
    final message = first['message'] as Map<String, dynamic>? ?? const {};
    final content = message['content'];
    final text = content is String ? content : jsonEncode(content);
    final usage = data['usage'] as Map<String, dynamic>? ?? const {};
    return CompletionResult(
      text,
      profile.applyBilling(
        TokenUsage(
          input: usage['prompt_tokens'] as int? ?? 0,
          output: usage['completion_tokens'] as int? ?? 0,
        ),
      ),
    );
  }

  Object _openAiContent(ChatMessage message) {
    if (message.attachments.isEmpty) return message.content;
    return <Map<String, Object?>>[
      {'type': 'text', 'text': message.content},
      for (final attachment in message.attachments)
        if (attachment.mimeType.startsWith('image/') &&
            attachment.base64Data != null)
          {
            'type': 'image_url',
            'image_url': {
              'url':
                  'data:${attachment.mimeType};base64,${attachment.base64Data}',
            },
          }
        else if (attachment.mimeType.startsWith('audio/') &&
            attachment.base64Data != null)
          {
            'type': 'input_audio',
            'input_audio': {
              'data': attachment.base64Data,
              'format': attachment.mimeType.split('/').last,
            },
          }
        else
          {
            'type': 'text',
            'text': '${attachment.name}\n${attachment.extractedText ?? ''}',
          },
    ];
  }

  Future<CompletionResult> _anthropic(
    ApiProfile profile,
    String apiKey,
    List<ChatMessage> messages,
    String systemPrompt,
    double temperature,
    double topP,
    int maxTokens,
    String modelId,
    CancelToken? cancelToken,
  ) async {
    final endpoint = _join(profile.baseUrl, 'messages');
    final response = await _dio.post<Map<String, dynamic>>(
      endpoint,
      data: {
        'model': modelId,
        'system': systemPrompt,
        'messages': messages
            .where((message) => message.role != MessageRole.system)
            .map(
              (message) => {
                'role': message.role == MessageRole.assistant
                    ? 'assistant'
                    : 'user',
                'content': _anthropicContent(message),
              },
            )
            .toList(),
        'temperature': temperature,
        'top_p': topP,
        'max_tokens': maxTokens,
      },
      options: Options(
        headers: {
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
          'Content-Type': 'application/json',
          ...profile.headers,
        },
      ),
      cancelToken: cancelToken,
    );
    final data = response.data ?? const {};
    final blocks = data['content'] as List? ?? const [];
    final text = blocks
        .whereType<Map>()
        .where((block) => block['type'] == 'text')
        .map((block) => block['text'])
        .join('\n');
    if (text.isEmpty) throw const FormatException('Missing completion content');
    final usage = data['usage'] as Map<String, dynamic>? ?? const {};
    return CompletionResult(
      text,
      profile.applyBilling(
        TokenUsage(
          input: usage['input_tokens'] as int? ?? 0,
          output: usage['output_tokens'] as int? ?? 0,
        ),
      ),
    );
  }

  List<Map<String, Object?>> _anthropicContent(ChatMessage message) => [
    {'type': 'text', 'text': message.content},
    for (final attachment in message.attachments)
      if (attachment.mimeType.startsWith('image/') &&
          attachment.base64Data != null)
        {
          'type': 'image',
          'source': {
            'type': 'base64',
            'media_type': attachment.mimeType,
            'data': attachment.base64Data,
          },
        }
      else
        {
          'type': 'text',
          'text': '${attachment.name}\n${attachment.extractedText ?? ''}',
        },
  ];

  String _join(String base, String path) =>
      '${base.replaceAll(RegExp(r'/+$'), '')}/${path.replaceAll(RegExp(r'^/+'), '')}';
}
