import 'dart:convert';

import 'package:dio/dio.dart';

import '../models/app_models.dart';

class ApiService {
  const ApiService(this._dio);
  final Dio _dio;

  Future<List<String>> fetchModels({
    required String baseUrl,
    required ApiFormat format,
    required String apiKey,
  }) async {
    final response = await _dio.get<Object?>(
      _join(baseUrl, 'models'),
      options: Options(headers: _authenticationHeaders(format, apiKey)),
    );
    final identifiers = <String>{};
    void collect(Object? value) {
      if (value is String && value.trim().isNotEmpty) {
        identifiers.add(value.trim());
      } else if (value is Map) {
        final identifier = value['id'] ?? value['model'] ?? value['name'];
        if (identifier is String && identifier.trim().isNotEmpty) {
          identifiers.add(identifier.trim());
        }
      }
    }

    final rawBody = response.data;
    final body = rawBody is String ? jsonDecode(rawBody) : rawBody;
    if (body is List) {
      for (final item in body) {
        collect(item);
      }
    } else if (body is Map) {
      final items = body['data'] ?? body['models'] ?? body['items'];
      if (items is List) {
        for (final item in items) {
          collect(item);
        }
      }
    }
    final models = identifiers.toList()..sort();
    if (models.isEmpty) throw const FormatException('model-list-empty');
    return models;
  }

  Stream<CompletionChunk> streamComplete({
    required ApiProfile profile,
    required String apiKey,
    required List<ChatMessage> messages,
    required String systemPrompt,
    required double temperature,
    required double topP,
    required int maxTokens,
    required ReasoningEffort reasoningEffort,
    String? modelId,
    CancelToken? cancelToken,
  }) async* {
    if (profile.format == ApiFormat.local) {
      throw StateError('Local model must use the local inference service.');
    }
    final openAi = profile.format == ApiFormat.openAi;
    final selectedModelId = profile.resolveModel(modelId);
    final reasoning = _reasoningFields(
      profile: profile,
      modelId: selectedModelId,
      effort: reasoningEffort,
      maxTokens: maxTokens,
    );
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
            if (reasoning.isEmpty) 'temperature': temperature,
            if (reasoning.isEmpty) 'top_p': topP,
            'max_tokens': maxTokens,
            'stream': true,
            'stream_options': {'include_usage': true},
            ...reasoning,
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
            if (reasoning.isEmpty) 'temperature': temperature,
            if (reasoning.isEmpty) 'top_p': topP,
            'max_tokens': maxTokens,
            'stream': true,
            ...reasoning,
          };
    final headers = _authenticationHeaders(profile.format, apiKey);
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
        reasoningEffort: ReasoningEffort.off,
      );

  Future<CompletionResult> complete({
    required ApiProfile profile,
    required String apiKey,
    required List<ChatMessage> messages,
    required String systemPrompt,
    required double temperature,
    required double topP,
    required int maxTokens,
    required ReasoningEffort reasoningEffort,
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
        reasoningEffort,
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
        reasoningEffort,
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
    ReasoningEffort reasoningEffort,
    String modelId,
    CancelToken? cancelToken,
  ) async {
    final endpoint = _join(profile.baseUrl, 'chat/completions');
    final reasoning = _reasoningFields(
      profile: profile,
      modelId: modelId,
      effort: reasoningEffort,
      maxTokens: maxTokens,
    );
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
        if (reasoning.isEmpty) 'temperature': temperature,
        if (reasoning.isEmpty) 'top_p': topP,
        'max_tokens': maxTokens,
        ...reasoning,
      },
      options: Options(headers: _authenticationHeaders(profile.format, apiKey)),
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
    ReasoningEffort reasoningEffort,
    String modelId,
    CancelToken? cancelToken,
  ) async {
    final endpoint = _join(profile.baseUrl, 'messages');
    final reasoning = _reasoningFields(
      profile: profile,
      modelId: modelId,
      effort: reasoningEffort,
      maxTokens: maxTokens,
    );
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
        if (reasoning.isEmpty) 'temperature': temperature,
        if (reasoning.isEmpty) 'top_p': topP,
        'max_tokens': maxTokens,
        ...reasoning,
      },
      options: Options(headers: _authenticationHeaders(profile.format, apiKey)),
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

  Map<String, String> _authenticationHeaders(ApiFormat format, String apiKey) =>
      switch (format) {
        ApiFormat.openAi => {
          if (apiKey.isNotEmpty) 'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        ApiFormat.anthropic => {
          if (apiKey.isNotEmpty) 'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
          'Content-Type': 'application/json',
        },
        ApiFormat.local => const {},
      };

  Map<String, Object?> _reasoningFields({
    required ApiProfile profile,
    required String modelId,
    required ReasoningEffort effort,
    required int maxTokens,
  }) {
    if (effort == ReasoningEffort.off ||
        !profile.reasoningModelIds.contains(modelId)) {
      return const {};
    }
    if (profile.format == ApiFormat.openAi) {
      return {'reasoning_effort': effort.name};
    }
    if (profile.format == ApiFormat.anthropic && maxTokens >= 2048) {
      final requested = switch (effort) {
        ReasoningEffort.low => 1024,
        ReasoningEffort.medium => 4096,
        ReasoningEffort.high => 8192,
        ReasoningEffort.off => 0,
      };
      return {
        'thinking': {
          'type': 'enabled',
          'budget_tokens': requested.clamp(1024, maxTokens - 1),
        },
      };
    }
    return const {};
  }

  String _join(String base, String path) =>
      '${base.replaceAll(RegExp(r'/+$'), '')}/${path.replaceAll(RegExp(r'^/+'), '')}';
}
