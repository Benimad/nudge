import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../services/ai_service.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/services/analytics_service.dart';
import '../../habits/controllers/home_controller.dart';
import '../../settings/services/subscription_service.dart';

class ChatController extends GetxController {
  final AiCoachService _aiService = AiCoachService();
  final stt.SpeechToText _speech = stt.SpeechToText();

  final messages = <ChatMessage>[].obs;
  final isLoading = false.obs;
  final isListening = false.obs;
  bool _speechAvailable = false;

  /// Whether the coach is running on the live model or the on-device fallback,
  /// so the UI can be honest about it instead of always claiming "AI-powered".
  bool get isLiveAi => _aiService.isLiveAi;

  final List<String> suggestedPrompts = const [
    "Why do I keep forgetting my habits?",
    "Help me start my work block",
    "I missed 3 days — what now?",
    "Break down my hardest task",
    "I'm feeling overwhelmed",
  ];

  @override
  void onInit() {
    super.onInit();
    _loadHistory();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      _speechAvailable = await _speech.initialize(
        onError: (_) => isListening.value = false,
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            isListening.value = false;
          }
        },
      );
    } catch (_) {
      _speechAvailable = false;
    }
  }

  Future<void> _loadHistory() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final maps = await db.query('chat_messages', orderBy: 'createdAt DESC', limit: 50);
      final loaded = maps.reversed
          .map((m) => ChatMessage(
                text: m['text'] as String,
                isUser: (m['isUser'] as int) == 1,
                timestamp: DateTime.parse(m['createdAt'] as String),
              ))
          .toList();
      messages.assignAll(loaded);
    } catch (e) {
      debugPrint('Failed to load chat history: $e');
    }
  }

  Future<void> _saveMessage(ChatMessage msg) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.insert('chat_messages', {
        'id': '${msg.timestamp.microsecondsSinceEpoch}_${msg.isUser ? 'u' : 'a'}',
        'text': msg.text,
        'isUser': msg.isUser ? 1 : 0,
        'createdAt': msg.timestamp.toIso8601String(),
      });
      final count = await db.rawQuery('SELECT COUNT(*) as c FROM chat_messages');
      final total = (count.first['c'] as int?) ?? 0;
      if (total > 100) {
        await db.rawDelete(
          'DELETE FROM chat_messages WHERE id IN (SELECT id FROM chat_messages ORDER BY createdAt ASC LIMIT ?)',
          [total - 100],
        );
      }
    } catch (e) {
      debugPrint('Failed to save chat message: $e');
    }
  }

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || isLoading.value) return;

    final userMsg = ChatMessage(text: trimmed, isUser: true);
    messages.add(userMsg);
    await _saveMessage(userMsg);
    unawaited(AnalyticsService.logAiMessageSent());

    // Crisis takes priority over everything, instantly and offline.
    final crisis = _aiService.scanForCrisis(trimmed);
    if (crisis.isCrisis) {
      final msg = ChatMessage(text: crisis.message, isUser: false);
      messages.add(msg);
      await _saveMessage(msg);
      return;
    }

    isLoading.value = true;

    // History = everything before this reply (excludes the just-added user msg
    // is not desired — we DO want it, so include all prior turns).
    final history = messages
        .where((m) => m != userMsg)
        .map((m) => CoachTurn(m.text, m.isUser))
        .toList();

    final context = await _buildContext();
    final prefs = await SharedPreferences.getInstance();
    final offline = prefs.getBool('offline_mode') ?? false;

    // Live model calls draw down the daily free quota; the on-device coach is
    // always free, so we degrade to it (never a hard wall) when quota is spent.
    final hasQuota = _aiService.isLiveAi && !offline && await SubscriptionService().canUseAi();
    final quotaExhausted = _aiService.isLiveAi && !offline && !hasQuota;

    // Placeholder message that fills in as tokens stream.
    final aiMsg = ChatMessage(text: '', isUser: false);

    try {
      if (!hasQuota) throw StateError('use-fallback');
      messages.add(aiMsg);
      final buffer = StringBuffer();
      await for (final chunk in _aiService.streamReply(trimmed, history: history, context: context)) {
        buffer.write(chunk);
        _updateLast(buffer.toString());
      }
      if (buffer.isEmpty) throw StateError('empty');
      isLoading.value = false;
      unawaited(SubscriptionService().registerAiUse());
      await _saveMessage(messages.last);
    } catch (_) {
      // On-device fallback — always works, never shows a raw error.
      isLoading.value = false;
      var reply = _aiService.fallbackResponse(trimmed);
      if (quotaExhausted) {
        reply +=
            "\n\n(You've used today's free AI coaching. I'll keep helping with on-device tips — upgrade to Pro for unlimited live coaching.)";
      }
      if (messages.isNotEmpty && identical(messages.last, aiMsg)) {
        _updateLast(reply);
      } else {
        messages.add(ChatMessage(text: reply, isUser: false));
      }
      await _saveMessage(messages.last);
    }
  }

  void _updateLast(String text) {
    if (messages.isEmpty) return;
    final last = messages.last;
    if (last.isUser) return;
    messages[messages.length - 1] = ChatMessage(
      text: text,
      isUser: false,
      timestamp: last.timestamp,
    );
  }

  /// Builds a rich personalization snapshot from real user data so the coach
  /// feels like it actually knows them.
  Future<Map<String, dynamic>> _buildContext() async {
    final prefs = await SharedPreferences.getInstance();

    List<String> goals = [];
    final goalsJson = prefs.getString('user_goals');
    if (goalsJson != null) {
      try {
        goals = (jsonDecode(goalsJson) as List).cast<String>();
      } catch (_) {}
    }

    String habitsSummary = '';
    String patterns = '';
    try {
      final home = Get.find<HomeController>();
      habitsSummary = home.habits
          .map((h) => '${h.name} (streak ${home.getStreak(h.id)}d)')
          .join(', ');
      final done = home.habits.where((h) => home.isCompleted(h.id)).length;
      final total = home.habits.where((h) => h.isActive).length;
      final best = home.streaks.values.isEmpty
          ? 0
          : home.streaks.values.reduce((a, b) => a > b ? a : b);
      patterns = 'Today: $done of $total habits done so far. Best current streak: ${best}d.';
    } catch (_) {}

    final hour = DateTime.now().hour;
    return {
      'time_of_day': hour < 12 ? 'morning' : hour < 17 ? 'afternoon' : 'evening',
      'brain_type': prefs.getString('brain_type') ?? 'Not sure',
      'name': prefs.getString('user_name') ?? 'Friend',
      'goals': goals,
      'habits_summary': habitsSummary,
      'patterns': patterns,
    };
  }

  Future<List<Map<String, String>>> getTaskBreakdown(String taskName, {bool useAi = true}) {
    return _aiService.breakdownTask(taskName, useAi: useAi);
  }

  String getWeeklyInsight(Map<String, dynamic> stats) {
    return _aiService.getWeeklyInsight(stats);
  }

  Future<void> clearConversation() async {
    messages.clear();
    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete('chat_messages');
    } catch (_) {}
  }

  Future<void> startVoiceInput() async {
    if (!_speechAvailable) {
      // Try once more — permission may have been granted after first launch.
      await _initSpeech();
    }
    if (!_speechAvailable) {
      Get.snackbar(
        'Voice input unavailable',
        'Enable microphone access in system settings to talk to your coach.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (isListening.value) {
      await _speech.stop();
      isListening.value = false;
      return;
    }

    isListening.value = true;
    await _speech.listen(
      onResult: (result) {
        if (result.finalResult && result.recognizedWords.isNotEmpty) {
          sendMessage(result.recognizedWords);
          isListening.value = false;
        }
      },
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.confirmation,
        cancelOnError: true,
        partialResults: false,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({required this.text, required this.isUser, DateTime? timestamp})
      : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'text': text,
        'isUser': isUser ? 1 : 0,
        'createdAt': timestamp.toIso8601String(),
      };
}
