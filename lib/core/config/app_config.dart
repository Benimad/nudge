/// Nudge app — API configuration.
///
/// All values are injected at build time and never committed to source.
/// Real keys live in `dart_defines.json` at the project root (gitignored;
/// template in `dart_defines.example.json`):
///   flutter build apk --dart-define-from-file=dart_defines.json
///   flutter run --dart-define-from-file=dart_defines.json
/// Individual --dart-define=KEY=value flags still work and override the file.
///
/// With no GEMINI_API_KEY the AI coach falls back to its offline, ADHD-specific
/// local knowledge base — the feature degrades gracefully rather than breaking.
class AppConfig {
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  /// Default is a broadly available, low-latency model with a generous free
  /// tier; override with --dart-define=GEMINI_MODEL=... to switch models
  /// without a code change. Must be a Gemini-family model: the coach relies on
  /// systemInstruction and JSON responseSchema, which Gemma models reject.
  static const String geminiModel = String.fromEnvironment(
    'GEMINI_MODEL',
    defaultValue: 'gemini-2.5-flash',
  );

  /// True when the coach can reach a real model.
  static bool get aiConfigured => geminiApiKey.isNotEmpty;
}
