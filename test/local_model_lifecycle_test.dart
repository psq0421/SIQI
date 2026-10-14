import 'package:flutter_test/flutter_test.dart';
import 'package:siqi/core/constants/minicpm_catalog.dart';
import 'package:siqi/core/services/local_inference_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('LES state replay is opt-in and leaves production tuning unchanged', () {
    const production = LocalInferenceTuning();
    expect(production.decodeThreadSweep, isFalse);
    expect(production.expertWindow, 56);
    const experiment = LocalInferenceTuning(decodeThreadSweep: true);
    expect(experiment.decodeThreadSweep, isTrue);
  });

  test(
    'concurrent unload shares one release future and clears its gate',
    () async {
      final service = LocalInferenceService();
      final first = service.unloadModel();
      final second = service.unloadModel();
      expect(identical(first, second), isTrue);
      expect(service.busy, isTrue);
      await Future.wait([first, second]);
      expect(service.busy, isFalse);
      await service.unloadModel();
      expect(service.busy, isFalse);
    },
  );

  test(
    'request waits for unloading and fails cleanly after disposal',
    () async {
      final service = LocalInferenceService();
      service.dispose();
      await expectLater(
        service.complete(
          model: MiniCpmCatalog.models.first,
          artifactPaths: const {},
          messages: const [],
          systemPrompt: '',
          contextWindow: 2048,
          temperature: 0,
          topP: 1,
          maxTokens: 32,
        ),
        throwsA(
          isA<LocalInferenceException>().having(
            (error) => error.stage,
            'stage',
            LocalInferenceStage.modelLoad,
          ),
        ),
      );
      expect(service.busy, isFalse);
    },
  );
}
