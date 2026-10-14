import 'package:flutter_test/flutter_test.dart';
import 'package:siqi/core/services/trace_redactor.dart';

void main() {
  for (final input in [
    'api_key=secretvalue',
    '{"apiKey":"secretvalue"}',
    'Authorization: Bearer secretvalue',
    "password = 'secretvalue'",
    'access_token: secretvalue',
    'sk-secretvalue1234567890',
  ]) {
    test('redacts credential form: $input', () {
      final output = TraceRedactor.sanitize(input);
      expect(output, isNot(contains('secretvalue')));
      expect(output, contains('[REDACTED]'));
    });
  }
  test('keeps useful Chinese task descriptions', () {
    expect(
      TraceRedactor.sanitize('读取 src/main.dart，修复空指针'),
      '读取 src/main.dart，修复空指针',
    );
  });
  test('redacts before bounding output', () {
    final output = TraceRedactor.sanitize(
      'api_key=secretvalue ' * 10000,
      maxCharacters: 80,
    );
    expect(output, contains('[truncated]'));
    expect(output, isNot(contains('secretvalue')));
  });
}
