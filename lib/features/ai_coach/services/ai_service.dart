import 'dart:convert';
import 'dart:math';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../../core/config/app_config.dart';

/// One turn of prior conversation, passed to the model so the coach actually
/// remembers what was just said.
class CoachTurn {
  final String text;
  final bool isUser;
  const CoachTurn(this.text, this.isUser);
}

/// Result of a crisis scan — lets the UI pin resources without a model round-trip.
class CrisisSignal {
  final bool isCrisis;
  final String message;
  const CrisisSignal(this.isCrisis, this.message);
}

class AiCoachService {
  static final AiCoachService _instance = AiCoachService._internal();
  factory AiCoachService() => _instance;
  AiCoachService._internal();

  /// True when a real model is reachable. Mirrors [AppConfig.aiConfigured] so
  /// callers can branch on "real AI" vs "on-device fallback" and label the UI
  /// honestly.
  bool get isLiveAi => AppConfig.aiConfigured;

  // ── Crisis + safety ─────────────────────────────────────────────────────────

  static const _crisisTriggers = [
    'kill myself', 'end my life', 'suicid', 'want to die', 'better off dead',
    'hurt myself', 'harming myself', 'self harm', 'self-harm', 'cutting myself',
    'no reason to live', "don't want to be here", 'take my life',
  ];

  /// Detected locally on every message so support is instant and works offline.
  CrisisSignal scanForCrisis(String input) {
    final lower = input.toLowerCase();
    final hit = _crisisTriggers.any(lower.contains);
    if (!hit) return const CrisisSignal(false, '');
    return const CrisisSignal(
      true,
      "I'm really glad you told me, and I want to make sure you're safe. "
      "I'm a habit coach, not a crisis service — please reach out to people who can help right now:\n\n"
      "• US: call or text 988 (Suicide & Crisis Lifeline)\n"
      "• UK & ROI: call 116 123 (Samaritans)\n"
      "• Or text HOME to 741741 (Crisis Text Line)\n\n"
      "If you're in immediate danger, please call your local emergency number. "
      "You matter, and you don't have to carry this alone.",
    );
  }

  String get _systemPrompt =>
      'You are Nudge, a warm, shame-free coach for people with ADHD and other '
      'neurodivergent brains. Your voice is calm, validating, and practical — '
      'never clinical, never patronizing.\n\n'
      'RULES:\n'
      '- Keep replies short: 2-4 sentences unless the user asks for steps.\n'
      '- Always break things into the smallest possible next action.\n'
      '- Never shame missed days, streaks, or "laziness"; reframe with compassion.\n'
      '- Plain text only. No markdown, asterisks, or headers.\n'
      '- You are a coach, NOT a therapist or doctor. Do not diagnose. Never give '
      'medication dosing or medical advice — for meds, suggest talking to their '
      'prescriber.\n'
      '- If the user expresses self-harm or crisis, gently encourage them to '
      'contact 988 (US), Samaritans 116 123 (UK/ROI), or their local emergency '
      'number, and stay supportive.\n'
      '- Personalize using the context provided (brain type, goals, habits, '
      'recent patterns) so it feels like you know them.';

  // ── Live streaming reply (preferred path) ────────────────────────────────────

  /// Streams the coach's reply token-by-token. Throws if no live model is
  /// configured or the call fails — callers should catch and fall back to
  /// [fallbackResponse]. History is the prior conversation, oldest first.
  Stream<String> streamReply(
    String userInput, {
    List<CoachTurn> history = const [],
    Map<String, dynamic>? context,
  }) async* {
    if (!AppConfig.aiConfigured) {
      throw StateError('No AI key configured');
    }
    final model = GenerativeModel(
      model: AppConfig.geminiModel,
      apiKey: AppConfig.geminiApiKey,
      systemInstruction: Content.system(_systemPrompt),
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
      ],
      generationConfig: GenerationConfig(temperature: 0.8, maxOutputTokens: 400),
    );

    // Last ~10 turns of memory, mapped to Gemini's alternating user/model roles.
    final trimmed = history.length > 10 ? history.sublist(history.length - 10) : history;
    final chatHistory = trimmed
        .map((t) => Content(t.isUser ? 'user' : 'model', [TextPart(t.text)]))
        .toList();

    final chat = model.startChat(history: chatHistory);
    final prompt = _composePrompt(userInput, context);
    final stream = chat.sendMessageStream(Content.text(prompt));
    var any = false;
    await for (final chunk in stream) {
      final t = chunk.text;
      if (t != null && t.isNotEmpty) {
        any = true;
        yield t;
      }
    }
    if (!any) throw StateError('Empty model response');
  }

  String _composePrompt(String userInput, Map<String, dynamic>? context) {
    final timeOfDay = context?['time_of_day'] ?? 'day';
    final brainType = context?['brain_type'] ?? 'Not sure';
    final goals = (context?['goals'] as List?)?.cast<String>() ?? const [];
    final habitsSummary = context?['habits_summary'] as String?;
    final patterns = context?['patterns'] as String?;
    final name = context?['name'] as String?;

    final lines = <String>[
      'Time of day: $timeOfDay',
      'Brain type: $brainType',
      if (name != null && name.isNotEmpty && name != 'Friend') 'Their name: $name',
      if (goals.isNotEmpty) 'Goals they chose: ${goals.join(', ')}',
      if (habitsSummary != null && habitsSummary.isNotEmpty) 'Current habits: $habitsSummary',
      if (patterns != null && patterns.isNotEmpty) 'Recent patterns: $patterns',
    ];
    return 'Context about this person — ${lines.join('; ')}.\n\n'
        'Their message: "$userInput"';
  }

  // ── On-device fallback (offline / no key / error) ────────────────────────────

  /// Deterministic, ADHD-specific reply from the local knowledge base. Always
  /// available, never throws — the safety net behind [streamReply].
  String fallbackResponse(String userInput) {
    final crisis = scanForCrisis(userInput);
    if (crisis.isCrisis) return crisis.message;

    final input = userInput.toLowerCase();
    if (_containsAny(input, ['help', 'stuck', 'can\'t', 'unable', 'paralysis'])) {
      return _pick(_paralysis);
    }
    if (_containsAny(input, ['forgot', 'forget', 'remember', 'memory', 'remind'])) {
      return _pick(_memory);
    }
    if (_containsAny(input, ['overwhelm', 'too much', 'stress', 'anxious', 'panic'])) {
      return _pick(_overwhelm);
    }
    if (_containsAny(input, ['sleep', 'tired', 'insomnia', 'exhausted'])) {
      return _sleep;
    }
    if (_containsAny(input, ['focus', 'distracted', 'concentrate', 'attention'])) {
      return _pick(_focus);
    }
    if (_containsAny(input, ['routine', 'morning', 'evening', 'habit', 'daily'])) {
      return input.contains('morning') ? _morningRoutine : _routine;
    }
    if (_containsAny(input, ['procrastinat', 'delay', 'later', 'avoid'])) {
      return _procrastination;
    }
    if (_containsAny(input, ['sad', 'depress', 'lonely', 'cry', 'hopeless'])) {
      return _emotional;
    }
    if (_containsAny(input, ['medication', 'pill', 'meds', 'prescription'])) {
      return _medication;
    }
    if (_containsAny(input, ['work', 'school', 'college', 'study', 'career'])) {
      return _containsAny(input, ['school', 'study', 'college']) ? _school : _work;
    }
    if (_containsAny(input, ['angry', 'frustrat', 'irritabl', 'rage'])) {
      return _anger;
    }
    if (_containsAny(input, ['thank', 'great', 'good', 'amazing', 'proud'])) {
      return _encouragement;
    }
    return _default();
  }

  bool _containsAny(String input, List<String> keywords) =>
      keywords.any((k) => input.contains(k));
  String _pick(List<String> list) => list[Random().nextInt(list.length)];

  static const _paralysis = [
    "I hear you. Task paralysis is real and it's not your fault. Let's try something: pick ONE thing within arm's reach and do it for 60 seconds. That's all. You can stop after that. Ready?",
    "Being stuck doesn't mean you're broken. Your brain is just in protection mode. Take a slow breath, and let's find the tiniest possible next step. What's smaller than what you're thinking of? That's the right size.",
    "Paralysis happens when the task looks too big. Can you shrink it? Instead of 'clean the kitchen', try 'put one cup in the sink'. One micro-move is still a win.",
  ];
  static const _memory = [
    "Forgetting isn't a character flaw — it's how ADHD brains work. Your working memory is like a whiteboard that gets erased. Write things down the instant you think them.",
    "Try the 'phone portal' method: whenever you think of something, immediately put it in your phone. The act of recording helps your brain release the thought.",
    "Externalize your memory. Sticky notes, alarms, widgets — make your environment do the remembering for you.",
  ];
  static const _overwhelm = [
    "Let's slow down together. Three slow breaths — in for 4, hold for 4, out for 4. Now name one thing you can see, one you can hear, one you can feel. We'll figure this out step by step.",
    "When everything feels like too much, the best thing you can do is LESS. Give yourself permission to do nothing for 10 minutes. Your brain needs the reset.",
    "Overwhelm says 'everything is urgent'. Pick the ONE thing that truly matters right now and let the rest float. What's that one thing?",
  ];
  static const _sleep =
      "Sleep and ADHD have a complicated relationship. Try: no phone 60 min before bed, same bedtime nightly, a cool room, and white noise to calm racing thoughts. Be gentle with yourself — sleep struggles aren't your fault.";
  static const _focus = [
    "Focus isn't about forcing attention — it's about removing distractions. For 25 minutes: phone face down, one tab, a timer. When your mind wanders (it will), guide it back without judgment.",
    "Your brain craves dopamine, which is why boring tasks are hard. Make it a game: set a timer, race yourself, add a reward. Bribe your brain — it works.",
    "Try the body-double effect. Start a focus session in Nudge and work alongside other real people — having someone there, even digitally, keeps your brain on track.",
  ];
  static const _morningRoutine =
      "Morning routines don't have to be perfect. Start with ONE anchor habit under 2 minutes — a full glass of water, or making your bed. That's enough. Build from there.";
  static const _routine =
      "Routines aren't about discipline — they reduce decisions. Start with an evening routine: same bedtime, phone away, clothes ready for tomorrow. Small wins compound.";
  static const _procrastination =
      "Procrastination isn't laziness — it's your brain avoiding discomfort. Make the START feel good: put on music, make tea, then do 5 minutes. Starting is the hardest part; momentum carries you.";
  static const _emotional =
      "I hear that you're struggling, and your feelings are valid. You don't have to face them alone — please reach out to someone you trust or a mental health professional if it's heavy. In the meantime, try holding something cold; the sensation can help ground you.";
  static const _medication =
      "Managing meds with ADHD is a lot. What helps: a weekly pill organizer, an alarm at med time, and keeping meds next to something you do daily like your toothbrush. Always talk to your prescriber before changing anything — I can't advise on that.";
  static const _school =
      "School wasn't designed for our brains — ask for accommodations; they exist for a reason. For studying, try 'scan, chunk, summarize': skim it, break it into small pieces, and put each piece in your own words.";
  static const _work =
      "Workplace success with ADHD is about designing your environment, not fighting your brain: noise-cancelling headphones for deep work, a visible to-do list, movement breaks, and the two-minute rule for small tasks.";
  static const _anger =
      "ADHD anger often comes from feeling flooded — too much input, too little control. When it builds: leave the room, count backwards from 100 by 7s, squeeze something hard. You're not bad for feeling it; your nervous system just got overloaded.";
  static const _encouragement =
      "You're welcome — and I mean it: showing up to understand yourself is genuinely huge. Progress isn't linear. Some days you're unstoppable, others brushing your teeth is the win. Both count. Keep going.";

  static const _defaults = [
    "That's a great thing to bring up. Here's a thought: ",
    "I appreciate you sharing that. Here's something that might help: ",
    "Every brain works differently, and yours has its own patterns. Here's an idea: ",
  ];

  final Map<String, List<String>> _knowledgeBase = const {
    'executive': [
      'Try the 2-minute rule: if a task takes under 2 minutes, do it now.',
      'Break tasks into tiny steps. Even "open the document" counts.',
      'Use external cues — alarms and visual reminders bypass the initiation block.',
    ],
    'habits': [
      'Start with ONE habit. Mastering one builds confidence for more.',
      'Stack a new habit onto an existing one: "After I brush my teeth, I will…".',
      'Make it easy — reduce the friction between you and the habit.',
    ],
    'focus': [
      'Keep your phone in another room during focus time.',
      'Set a specific end time for focus, not just a start time.',
      'Move between sitting and standing every 30 minutes.',
    ],
  };

  String _default() {
    final prefix = _defaults[Random().nextInt(_defaults.length)];
    final cats = _knowledgeBase.values.toList();
    final cat = cats[Random().nextInt(cats.length)];
    return '$prefix${cat[Random().nextInt(cat.length)]}';
  }

  // ── Task breakdown ───────────────────────────────────────────────────────────

  /// Real, model-generated micro-steps for any task, each with an honest time
  /// estimate. Falls back to curated templates offline or on error. Returns a
  /// list of {step, time} maps.
  Future<List<Map<String, String>>> breakdownTask(String task, {bool useAi = true}) async {
    if (useAi && AppConfig.aiConfigured) {
      try {
        final model = GenerativeModel(
          model: AppConfig.geminiModel,
          apiKey: AppConfig.geminiApiKey,
          systemInstruction: Content.system(
            'You break tasks into tiny, concrete steps for someone with ADHD who '
            'feels paralyzed. Each step must be a single physical action that takes '
            'under 5 minutes. The first step must be almost laughably small.',
          ),
          generationConfig: GenerationConfig(
            temperature: 0.6,
            responseMimeType: 'application/json',
            responseSchema: Schema.array(
              items: Schema.object(properties: {
                'step': Schema.string(description: 'the action, imperative, under 8 words'),
                'minutes': Schema.number(description: 'realistic minutes, 1-5'),
              }, requiredProperties: ['step', 'minutes']),
            ),
          ),
        );
        final res = await model.generateContent(
          [Content.text('Break this into 4-5 micro-steps: "$task"')],
        );
        final text = res.text;
        if (text != null && text.trim().isNotEmpty) {
          final parsed = _parseSteps(text);
          if (parsed.isNotEmpty) return parsed;
        }
      } catch (_) {
        // fall through to templates
      }
    }
    return _templateSteps(task);
  }

  List<Map<String, String>> _parseSteps(String json) {
    try {
      // The schema guarantees a JSON array of {step, minutes}.
      final decoded = _decodeJsonArray(json);
      return decoded
          .map((e) {
            final step = (e['step'] ?? '').toString().trim();
            final mins = (e['minutes'] is num) ? (e['minutes'] as num).round() : 2;
            return {'title': step, 'time': mins <= 1 ? '1 min' : '$mins min'};
          })
          .where((m) => (m['title'] ?? '').isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  List<Map<String, dynamic>> _decodeJsonArray(String json) {
    final dynamic decoded = jsonDecode(json);
    if (decoded is List) return decoded.cast<Map<String, dynamic>>();
    return const [];
  }

  List<Map<String, String>> _templateSteps(String task) {
    final t = task.toLowerCase();
    List<String> steps;
    if (_containsAny(t, ['clean', 'tidy', 'organize', 'declutter'])) {
      steps = ['Pick up one item and decide its home', 'Put that item away', 'Clear one surface', 'Wipe that surface', 'Take out one bag of trash'];
    } else if (_containsAny(t, ['write', 'report', 'essay', 'email', 'document'])) {
      steps = ['Open a blank document', 'Write 5 rough ideas', 'Pick the best 3', 'Write 50 words on the first', 'Tidy up what you wrote'];
    } else if (_containsAny(t, ['code', 'program', 'develop', 'app'])) {
      steps = ['Open your editor', 'Re-read the requirement', 'Write one small function', 'Test it', 'Commit your change'];
    } else if (_containsAny(t, ['exercise', 'workout', 'gym', 'run', 'walk'])) {
      steps = ['Put on workout clothes', 'Fill your water bottle', 'Stretch for 5 minutes', 'Start with the easiest move', 'Do one minute more than yesterday'];
    } else if (_containsAny(t, ['read', 'study', 'learn', 'research'])) {
      steps = ['Open the material', 'Read one page', 'Note one thing you learned', 'Read one more page', 'Summarize in 3 bullets'];
    } else if (_containsAny(t, ['call', 'phone', 'talk', 'meeting'])) {
      steps = ['Open the contact', 'Write what you want to say', 'Take a breath and dial', 'Have the conversation', 'Note what was decided'];
    } else {
      steps = ['Gather what you need for: $task', 'Set a 10-minute timer', 'Work until it goes off', 'Take a 2-minute break', 'Decide whether to continue'];
    }
    const times = ['1 min', '2 min', '5 min', '2 min', '3 min'];
    return List.generate(steps.length, (i) => {'title': steps[i], 'time': times[i % times.length]});
  }

  // ── Weekly insight ───────────────────────────────────────────────────────────

  String getWeeklyInsight(Map<String, dynamic> stats) {
    final completionRate = (stats['completion_rate'] ?? 0.0) as double;
    final bestDay = stats['best_day'] ?? 'unknown';
    final streakLength = (stats['streak'] ?? 0) as int;
    final improvement = (stats['improvement'] ?? 0.0) as double;
    final moodNote = stats['mood_note'] as String?;

    final parts = <String>[];
    if (completionRate >= 0.8) {
      parts.add("You've been crushing it — a ${(completionRate * 100).toInt()}% completion rate this week!");
    } else if (completionRate >= 0.5) {
      parts.add("You completed ${(completionRate * 100).toInt()}% of your habits this week — solid progress.");
    } else {
      parts.add("This week you completed ${(completionRate * 100).toInt()}% of your habits. Every check-in counts.");
    }
    if (bestDay != 'unknown') parts.add("$bestDay was your strongest day.");
    if (streakLength >= 7) {
      parts.add("An awesome $streakLength-day streak — real momentum!");
    } else if (streakLength >= 3) {
      parts.add("Nice $streakLength-day streak going.");
    }
    if (improvement > 0) {
      parts.add("You improved ${(improvement * 100).toInt()}% over last week — keep going!");
    }
    if (moodNote != null && moodNote.isNotEmpty) parts.add(moodNote);
    parts.add("Remember: consistency beats perfection. You're doing great.");
    return parts.join(' ');
  }

  String get moodInsight {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return "Mornings can be tough with ADHD — executive function is lowest right after waking. Start with one tiny win.";
    } else if (hour < 17) {
      return "Afternoon slump? This is when many ADHD brains struggle most. Move your body or change your environment.";
    } else {
      return "Evenings are when many ADHD brains come alive — use the energy, but start winding down 1-2 hours before bed.";
    }
  }
}
