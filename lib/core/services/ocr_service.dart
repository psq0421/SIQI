import 'dart:io';

import '../constants/app_constants.dart';
import '../models/app_models.dart';
import 'file_content_service.dart';
import 'local_inference_service.dart';
import 'local_task_service.dart';
import 'model_download_service.dart';

class OcrRecognitionResult {
  const OcrRecognitionResult({
    required this.text,
    required this.modelId,
    required this.sourcePath,
  });

  final String text;
  final String modelId;
  final String sourcePath;
}

/// OCR through the bundled llama.cpp multimodal FFI runtime. It reuses an
/// installed Qwen3.5/Gemma 4 projector instead of duplicating several GB of
/// weights under an artificial OCR-only model id.
class OcrService {
  const OcrService(this._downloads, this._inference, this._files);

  final ModelDownloadService _downloads;
  final LocalInferenceService _inference;
  final FileContentService _files;

  Future<LocalTaskStatus> status({String? preferredModelId}) async {
    final model = await _resolveModel(preferredModelId);
    return LocalTaskStatus(
      available: model != null,
      runtime: 'llama.cpp multimodal FFI',
      detail: model == null ? 'vision-model-not-installed' : model.displayName,
    );
  }

  Future<OcrRecognitionResult> recognize({
    required String imagePath,
    required AppSettings settings,
    String? preferredModelId,
  }) async {
    if (!await File(imagePath).exists()) {
      throw const LocalTaskException('image-file-missing');
    }
    final model = await _resolveModel(
      preferredModelId ?? settings.selectedModelId,
    );
    if (model == null) {
      throw const LocalTaskException('vision-model-not-installed');
    }
    final artifacts = await _downloads.installedArtifactPaths(model);
    final attachment = await _files.read(imagePath, multimodal: true);
    if (!attachment.mimeType.startsWith('image/')) {
      throw const LocalTaskException('unsupported-image');
    }
    final sessionId = 'ocr-${DateTime.now().microsecondsSinceEpoch}';
    final message = ChatMessage(
      id: '$sessionId-input',
      sessionId: sessionId,
      role: MessageRole.user,
      content:
          'Recognize every visible character in this image. Preserve reading '
          'order, paragraphs, lists, tables, punctuation, and code layout. '
          'Return only the transcription; do not summarize or invent text.',
      createdAt: DateTime.now(),
      modelId: model.id,
      attachments: [attachment],
    );
    try {
      final result = await _inference.complete(
        model: model,
        artifactPaths: artifacts,
        messages: [message],
        systemPrompt:
            'You are an offline OCR engine. Copy visible text faithfully and '
            'mark unreadable regions as [unclear].',
        contextWindow: settings.contextWindow.clamp(2048, 8192),
        temperature: 0,
        topP: .1,
        maxTokens: settings.maxTokens.clamp(256, 4096),
      );
      final text = result.text.trim();
      if (text.isEmpty) throw const LocalTaskException('ocr-empty-output');
      return OcrRecognitionResult(
        text: text,
        modelId: model.id,
        sourcePath: attachment.path,
      );
    } on LocalTaskException {
      rethrow;
    } on Object catch (error) {
      throw LocalTaskException('ocr-inference-failed', error);
    }
  }

  Future<ModelDefinition?> _resolveModel(String? preferredModelId) async {
    final candidates = <ModelDefinition>[
      if (preferredModelId != null)
        ...ModelCatalog.models.where((model) => model.id == preferredModelId),
      ...ModelCatalog.models.where(
        (model) =>
            model.family == ModelFamily.local &&
            model.runnable &&
            model.runtime == ModelRuntime.llamaCpp &&
            model.capabilities.contains(ModelCapability.imageInput) &&
            (model.task == ModelTask.visionLanguage ||
                model.task == ModelTask.vision),
      ),
    ];
    final seen = <String>{};
    for (final model in candidates) {
      if (!seen.add(model.id)) continue;
      if (model.projectorArtifact == null) continue;
      if (await _downloads.isFullyInstalled(model)) return model;
    }
    return null;
  }
}
