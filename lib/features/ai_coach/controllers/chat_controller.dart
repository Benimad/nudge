import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../services/ai_service.dart';
import '../../../core/database/database_helper.dart';
import '../../habits/controllers/home_controller.dart';

class ChatController extends GetxController {
  final AiCoachService _aiService = AiCoachService();
  final stt.SpeechToText _speech = stt.SpeechToText();

  final messages = <ChatMessage>[].obs;
  final isLoading = false.obs;
  final isListening = false.obs;
  bool _speechAvailable = false;

  final List<String> suggestedPrompts = [
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
    _speechAvailable = await _speech.initialize(
      onError: (error) => {},
      onStatus: (status) => {},
    );
  }

  Future<void> _loadHistory() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final maps = await db.query(
        'chat_messages',
        orderBy: 'createdAt DESC',
        limit: 50,
      );
      final loaded = maps.reversed.map((m) => ChatMessage(
        text: m['text'] as String,
        isUser: (m['isUser'] as int) == 1,
        timestamp: DateTime.parse(m['createdAt'] as String),
      )).toList();
      messages.assignAll(loaded);
    } catch (e) {
      debugPrint('Failed to load chat history: $e');
    }
  }

  Future<void> _saveMessage(ChatMessage msg) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.insert('chat_messages', {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'text': msg.text,
        'isUser': msg.isUser ? 1 : 0,
        'createdAt': msg.timestamp.toIso8601String(),
      });
      // Trim to last 50
      final count = await db.rawQuery('SELECT COUNT(*) as c FROM chat_messages');
      final total = (count.first['c'] as int?) ?? 0;
      if (total > 50) {
        await db.rawDelete(
          'DELETE FROM chat_messages WHERE id IN (SELECT id FROM chat_messages ORDER BY createdAt ASC LIMIT ?)',
          [total - 50],
        );
      }
    } catch (e) {
      debugPrint('Failed to save chat message: $e');
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMsg = ChatMessage(text: text, isUser: true);
    messages.add(userMsg);
    await _saveMessage(userMsg);
    isLoading.value = true;

    try {
      final context = await _getUserContext();
      final response = await _aiService.getResponse(text, context: context);

      final wordCount = response.split(' ').length;
      final delay = (wordCount * 50).clamp(300, 2000);
      await Future.delayed(Duration(milliseconds: delay));

      final aiMsg = ChatMessage(text: response, isUser: false);
      messages.add(aiMsg);
      await _saveMessage(aiMsg);
    } catch (e) {
      final fallbackMsg = ChatMessage(
        text: "I'm here for you. Let me think about this differently... ${_aiService.getResponse('help')}",
        isUser: false,
      );
      messages.add(fallbackMsg);
      await _saveMessage(fallbackMsg);
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>> _getUserContext() async {
    final prefs = await SharedPreferences.getInstance();

    List<String> goals = [];
    final goalsJson = prefs.getString('user_goals');
    if (goalsJson != null) {
      try {
        goals = (jsonDecode(goalsJson) as List).cast<String>();
      } catch (_) {
        // Malformed/legacy value — treat as no goals set rather than crash.
      }
    }

    String habitsSummary = '';
    try {
      final home = Get.find<HomeController>();
      habitsSummary = home.habits
          .map((h) => '${h.name} (streak: ${home.getStreak(h.id)})')
          .join(', ');
    } catch (_) {
      // HomeController isn't registered yet — skip habit context this time.
    }

    return {
      'time_of_day': DateTime.now().hour < 12 ? 'morning' : DateTime.now().hour < 17 ? 'afternoon' : 'evening',
      'mood': _aiService.moodInsight,
      'brain_type': prefs.getString('brain_type') ?? 'Not sure',
      'goals': goals,
      'habits_summary': habitsSummary,
      'offline_mode': prefs.getBool('offline_mode') ?? false,
    };
  }

  List<String> getTaskBreakdown(String taskName) {
    return _aiService.getTaskBreakdown(taskName);
  }

  String getWeeklyInsight(Map<String, dynamic> stats) {
    return _aiService.getWeeklyInsight(stats);
  }

  Future<void> startVoiceInput() async {
    if (!_speechAvailable) {
      Get.snackbar(
        'Voice Input Unavailable',
        'Speech recognition is not available on this device',
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
        onDevice: true,
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

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'isUser': isUser ? 1 : 0,
      'createdAt': timestamp.toIso8601String(),
    };
  }
}
