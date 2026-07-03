/// Nudge app — API configuration
/// Keep this file out of public repositories.
///
/// Build with: --dart-define=GEMINI_API_KEY=your_key_here
class AppConfig {
  // Gemini API key — injected at build time, never committed to source
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  // Model: Gemma 4 26B A4B Instruction-tuned
  // Activates ~4B params per inference — fast, efficient, high-quality
  static const String geminiModel = 'gemma-4-26b-a4b-it';
}
