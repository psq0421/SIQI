/// Token-stream timing, measured after model loading. Reasoning output is not
/// the visible answer; neither timestamp includes cold-load wall time.
class GenerationDeltaTimings {
  int? firstDeltaMs;
  int? firstContentDeltaMs;
  int? firstReasoningDeltaMs;

  void observe({required int elapsedMs, String? content, String? reasoning}) {
    if (content != null && content.isNotEmpty) {
      firstContentDeltaMs ??= elapsedMs;
      firstDeltaMs ??= elapsedMs;
    }
    if (reasoning != null && reasoning.isNotEmpty) {
      firstReasoningDeltaMs ??= elapsedMs;
      firstDeltaMs ??= elapsedMs;
    }
  }

  Map<String, Object?> toJson() => {
    'timingSchema': 2,
    'firstDeltaMs': firstDeltaMs,
    'firstContentDeltaMs': firstContentDeltaMs,
    'firstReasoningDeltaMs': firstReasoningDeltaMs,
  };
}
