/// Nudge app — API configuration.
///
/// All values are injected at build time and never committed to source:
///   flutter build apk \
///     --dart-define=GEMINI_API_KEY=your_key \
///     --dart-define=GEMINI_MODEL=gemini-2.5-flash \
///     --dart-define=POSTHOG_API_KEY=phc_xxx \
///     --dart-define=REVENUECAT_ANDROID_KEY=goog_xxx \
///     --dart-define=REVENUECAT_IOS_KEY=appl_xxx
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
  /// without a code change.
  static const String geminiModel = String.fromEnvironment(
    'GEMINI_MODEL',
    defaultValue: 'gemini-2.5-flash',
  );

  /// True when the coach can reach a real model.
  static bool get aiConfigured => geminiApiKey.isNotEmpty;
}
