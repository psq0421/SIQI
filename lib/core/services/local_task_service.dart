class LocalTaskStatus {
  const LocalTaskStatus({
    required this.available,
    required this.runtime,
    this.detail,
  });

  final bool available;
  final String runtime;
  final String? detail;
}

class LocalTaskException implements Exception {
  const LocalTaskException(this.code, [this.detail]);

  final String code;
  final Object? detail;

  @override
  String toString() => detail == null ? code : '$code: $detail';
}
