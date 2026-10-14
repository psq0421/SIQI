/// Best-effort secret filtering for persisted/exported research traces.
/// It is not a guarantee that arbitrary private content can be published.
abstract final class TraceRedactor {
  static String sanitize(String value, {int maxCharacters = 12000}) {
    final redacted = value
        .replaceAll(
          RegExp(r'bearer\s+[A-Za-z0-9._~+/=-]+', caseSensitive: false),
          'Bearer [REDACTED]',
        )
        .replaceAllMapped(
          RegExp(
            r'''(["']?(?:api[-_ ]?key|authorization|access[-_ ]?token|token|password|secret)["']?\s*[:=]\s*)("[^"\r\n]*"|'[^'\r\n]*'|[^\s,;\r\n]+)''',
            caseSensitive: false,
          ),
          (match) => '${match[1]}"[REDACTED]"',
        )
        .replaceAll(RegExp(r'\bsk-[A-Za-z0-9_-]{12,}\b'), '[REDACTED]');
    return redacted.length <= maxCharacters
        ? redacted
        : '${redacted.substring(0, maxCharacters)}\n...[truncated]';
  }
}
