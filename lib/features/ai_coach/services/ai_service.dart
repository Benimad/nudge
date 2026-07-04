import 'dart:math';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../../core/config/app_config.dart';

class AiCoachService {
  static final AiCoachService _instance = AiCoachService._internal();
  factory AiCoachService() => _instance;
  AiCoachService._internal();

  // Knowledge base categories
  final Map<String, List<String>> _knowledgeBase = {
    'executive_dysfunction': [
      'Executive dysfunction means your brain struggles to organize thoughts and actions.',
      'It\'s not laziness - your brain\'s task initiation system needs a different approach.',
      'Try the 2-minute rule: if a task takes less than 2 minutes, do it immediately.',
      'Break tasks into tiny steps. Even "open the document" counts as a step.',
      'Use external cues - alarms, notes, visual reminders help bypass the initiation block.',
    ],
    'time_blindness': [
      'Time blindness is common with ADHD - 5 minutes can feel like 5 hours or 5 seconds.',
      'Use visual timers - seeing time pass helps your brain track it better.',
      'Set multiple gentle alarms rather than one "final warning".',
      'The Pomodoro technique works well: 25 minutes focus, 5 minutes break.',
      'Estimate task times generously - multiply your first guess by 2.',
    ],
    'rsd': [
      'Rejection Sensitive Dysphoria makes criticism feel overwhelming.',
      'You\'re not overreacting - RSD is a real neurological response.',
      'Take a 10-minute pause before responding to something that stings.',
      'Remember: one criticism doesn\'t define your worth.',
      'Talk to yourself like you\'d talk to your best friend.',
    ],
    'overwhelm': [
      'When overwhelmed, stop and name three things you can see.',
      'Write down everything in your head - get it out of your working memory.',
      'Choose ONE thing to focus on. Everything else can wait.',
      'Use the "sometime/now" method: sort tasks into "sometime" and "now".',
      'It\'s okay to do nothing for 5 minutes. Rest is productive.',
    ],
    'motivation': [
      'Motivation follows action, not the other way around. Just start.',
      'Make tasks interesting by pairing them with something you enjoy.',
      'Create urgency by telling someone your plan - accountability helps.',
      'Visualize how you\'ll feel after completing the task, not during.',
      'Reward yourself immediately after completing a task, no matter how small.',
    ],
    'habits': [
      'Start with ONE habit. Mastering one builds confidence for more.',
      'Stack new habits onto existing ones: "After I [existing], I will [new]".',
      'Make it easy - reduce friction between you and the habit.',
      'Don\'t break the chain - but if you do, start again without shame.',
      'Your environment shapes your habits more than willpower.',
    ],
    'focus': [
      'Use background noise at a consistent volume.',
      'Keep your phone in another room during focus time.',
      'Use the "body double" method - work alongside someone else.',
      'Set a specific end time for focus, not just a start time.',
      'Move between sitting and standing every 30 minutes.',
    ],
    'morning_routine': [
      'Have one non-negotiable morning action you can do in under 5 minutes.',
      'Prepare everything the night before - clothes, breakfast, keys.',
      'Use the "5 things" method: drink water, stretch, make bed, wash face, take meds.',
      'Keep your morning routine visual - a checklist on your mirror works wonders.',
      'Give yourself 30 extra minutes for "drift time" between tasks.',
    ],
  };

  // Response patterns based on user input analysis
  Future<String> getResponse(String userInput, {Map<String, dynamic>? context}) async {
    final offlineMode = context?['offline_mode'] == true;
    try {
      if (offlineMode) throw StateError('Offline mode enabled — skipping Gemini call');
      final model = GenerativeModel(
        model: AppConfig.geminiModel,
        apiKey: AppConfig.geminiApiKey,
        systemInstruction: Content.system(
          'You are an expert ADHD coach called Nudge. Keep responses under 3 sentences, '
          'empathetic, shame-free, and highly actionable. Never use markdown formatting. '
          'Always break tasks into the smallest possible steps.',
        ),
      );
      final timeOfDay = context?['time_of_day'] ?? 'day';
      final brainType = context?['brain_type'] ?? 'Not sure';
      final mood = context?['mood'] as String?;
      final goals = (context?['goals'] as List?)?.cast<String>() ?? const [];
      final habitsSummary = context?['habits_summary'] as String?;

      final contextLines = <String>[
        'Time of day: $timeOfDay',
        'Brain type: $brainType',
        if (goals.isNotEmpty) 'Stated goals: ${goals.join(', ')}',
        if (habitsSummary != null && habitsSummary.isNotEmpty)
          'Current habits: $habitsSummary',
        if (mood != null && mood.isNotEmpty) 'Relevant insight: $mood',
      ];

      final prompt = 'User message: "$userInput". '
          'User context — ${contextLines.join('; ')}. '
          'Respond as a warm, supportive ADHD coach in plain text, '
          'personalizing to their brain type and current habits where relevant.';
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      if (response.text != null && response.text!.isNotEmpty) {
        return response.text!;
      }
    } catch (e) {
      // Fallback to local knowledge base on error
    }

    // Fallback to local logic
    final input = userInput.toLowerCase();
    
    // Analyze input for intent
    if (_containsAny(input, ['help', 'stuck', 'can\'t', 'unable', 'paralysis'])) {
      return _getParalysisResponse(input);
    }
    if (_containsAny(input, ['forgot', 'forget', 'remember', 'memory', 'remind'])) {
      return _getMemoryResponse();
    }
    if (_containsAny(input, ['overwhelm', 'too much', 'stress', 'anxious', 'panic'])) {
      return _getOverwhelmResponse(input);
    }
    if (_containsAny(input, ['sleep', 'tired', 'insomnia', 'exhausted'])) {
      return _getSleepResponse();
    }
    if (_containsAny(input, ['focus', 'distracted', 'concentrate', 'attention'])) {
      return _getFocusResponse(input);
    }
    if (_containsAny(input, ['routine', 'morning', 'evening', 'habit', 'daily'])) {
      return _getRoutineResponse(input);
    }
    if (_containsAny(input, ['procrastinat', 'delay', 'later', 'avoid'])) {
      return _getProcrastinationResponse();
    }
    if (_containsAny(input, ['sad', 'depress', 'lonely', 'cry', 'hopeless'])) {
      return _getEmotionalResponse();
    }
    if (_containsAny(input, ['medication', 'pill', 'meds', 'prescription'])) {
      return _getMedicationResponse();
    }
    if (_containsAny(input, ['work', 'school', 'college', 'study', 'career'])) {
      return _getWorkResponse(input);
    }
    if (_containsAny(input, ['angry', 'frustrat', 'irritabl', 'rage'])) {
      return _getAngerResponse();
    }
    if (_containsAny(input, ['thank', 'great', 'good', 'amazing', 'proud'])) {
      return _getEncouragementResponse();
    }

    // Default response
    return _getDefaultResponse(input);
  }

  bool _containsAny(String input, List<String> keywords) {
    return keywords.any((k) => input.contains(k));
  }

  String _getParalysisResponse(String input) {
    final responses = [
      "I hear you. Task paralysis is real and it's not your fault. Let's try something: pick ONE thing within arm's reach and do it for 60 seconds. That's all. You can stop after that. Ready?",
      "Being stuck doesn't mean you're broken. Your brain is just in protection mode. Take a slow breath, and let's find the tiniest possible next step. What's smaller than what you're thinking of? That's the right size.",
      "Paralysis happens when the task looks too big. Can you shrink it? Instead of 'clean the kitchen', try 'put one cup in the sink'. Instead of 'start the project', try 'open the file'. One micro-move is still a win.",
      "You're not avoiding work - your brain is avoiding the feeling of failure. That's a sign you care deeply. Let's make the stakes so small that failure doesn't matter. What would you do if it was impossible to fail?"
    ];
    return responses[Random().nextInt(responses.length)];
  }

  String _getMemoryResponse() {
    final responses = [
      "Forgetting isn't a character flaw - it's how ADHD brains work. Your working memory is like a whiteboard that gets erased randomly. Write things down immediately, before you think 'I'll remember this later' (spoiler: you won't!).",
      "Try the 'phone portal' method: whenever you think of something, immediately put it in your phone. Notes app, calendar, reminder - doesn't matter. The act of recording helps your brain release the thought.",
      "Externalize your memory! Your brain isn't built for holding lots of details. Use sticky notes, whiteboards, phone alarms, widget displays. Make your environment do the remembering for you.",
      "Habit stacking: pair 'I will remember X' with 'when I do Y'. For example, 'when I brush my teeth, I'll take my medication'. The existing habit becomes the trigger for the new one."
    ];
    return responses[Random().nextInt(responses.length)];
  }

  String _getOverwhelmResponse(String input) {
    final responses = [
      "Let's slow down together. First, take three slow breaths. Breathe in for 4 counts, hold for 4, out for 4. Now, name one thing you can see, one you can hear, and one you can feel. You're safe. We'll figure this out step by step.",
      "When everything feels like too much, the best thing you can do is LESS. Give yourself permission to do nothing for 10 minutes. No phone, no guilt - just sitting. Your brain needs the reset.",
      "Overwhelm says 'everything is urgent'. Reality says 'almost nothing is truly urgent'. Let's triage: what would happen if you did NOTHING on your list for a day? The answer is probably 'not much'. Pick what truly matters and let the rest float.",
      "Your brain is trying to process too many tabs at once. Close some mental tabs. Name 3 things you're worried about. Now ask: 'Can I do anything about this right now?' If no, close that tab. If yes, what's one tiny step?"
    ];
    return responses[Random().nextInt(responses.length)];
  }

  String _getSleepResponse() {
    return "Sleep and ADHD have a complicated relationship. Your brain doesn't naturally produce the 'time to sleep' chemicals at the right time. Try these: 1) No phone 60 min before bed 2) Same bedtime every night 3) Cool room temperature 4) White noise helps calm the racing thoughts. Be gentle with yourself - sleep struggles aren't your fault.";
  }

  String _getFocusResponse(String input) {
    final responses = [
      "Focus isn't about forcing attention - it's about removing distractions. For the next 25 minutes, try: phone face down, one browser tab, noise-cancelling headphones, and a timer. When your mind wanders (it will), gently guide it back without judgment.",
      "Your brain craves dopamine, which is why focus is hard on boring tasks. Make it a game: set a timer, race against yourself, add a reward. 'If I focus for 20 minutes, I get to watch a favorite video.' Bribe your brain - it works.",
      "The default ADHD brain cycles between hyperfocus and scatter. Neither is 'bad'. If you're scattered now, move your body. Do 10 jumping jacks, splash water on your face, or walk around the block. Then try again.",
      "Use the 'body double' effect - even a virtual one. Find a study-with-me video, call a friend who also needs to focus, or go to a coffee shop. Having someone else nearby (even digitally) helps your brain stay on track."
    ];
    return responses[Random().nextInt(responses.length)];
  }

  String _getRoutineResponse(String input) {
    if (input.contains('morning')) {
      return "Morning routines don't have to be Instagram-perfect. Start with ONE anchor habit you can do in under 2 minutes. Drink a full glass of water. Make your bed. Take your vitamins. That's enough. Build from there, one tiny habit at a time.";
    }
    return "Routines aren't about discipline - they're about reducing decisions. When something is automatic, your brain doesn't have to 'choose' to do it. Start with evening routine: same bedtime, phone away, clothes ready for tomorrow. Small wins compound.";
  }

  String _getProcrastinationResponse() {
    return "Procrastination isn't laziness - it's your brain trying to protect you from discomfort. The task feels bad, so you avoid it. The secret? Make the START of the task feel good. Put on your favorite music. Make tea. Light a candle. Then do 5 minutes. Starting is the hardest part - once you start, momentum carries you.";
  }

  String _getEmotionalResponse() {
    return "I hear that you're struggling. Please know: your feelings are valid, and you don't have to face them alone. While I can offer support, please reach out to someone you trust or a mental health professional if you're really struggling. You matter. You deserve support. \n\nIn the meantime, try this: hold something cold (ice cube, cold water bottle). The physical sensation can help ground you when emotions feel overwhelming.";
  }

  String _getMedicationResponse() {
    return "Managing medication with ADHD is like being your own pharmacist, nurse, and detective all at once. Tips that help: 1) Use a weekly pill organizer 2) Set an alarm on your phone for medication time 3) Keep medication next to something you do daily (toothbrush, coffee maker) 4) Track side effects and effectiveness in a simple notes app. Never adjust medication without consulting your doctor.";
  }

  String _getWorkResponse(String input) {
    if (input.contains('school') || input.contains('study') || input.contains('college')) {
      return "School with ADHD is extra challenging because the system wasn't designed for our brains. Ask for accommodations - they exist for a reason. Extended time, quiet testing rooms, note-taking assistance. Use the 'scan, chunk, summarize' method for studying: quickly scan, divide into small chunks, summarize each chunk in your own words.";
    }
    return "Workplace success with ADHD is about designing your environment, not fighting your brain. Use: noise-cancelling headphones for deep work, visible to-do lists (not digital ones you'll forget to check), regular movement breaks, and the 'two minute rule' for small tasks. And please - if you're struggling, consider disclosing to HR if you feel safe doing so. Accommodations can transform your work life.";
  }

  String _getAngerResponse() {
    return "ADHD anger often comes from feeling flooded - too much input, too little control. When you feel the rage building: 1) Leave the room immediately 2) Count backwards from 100 by 7s (distracts the emotional brain) 3) Squeeze something hard 4) When you've calmed down, write out what triggered you. You're not a bad person for getting angry - you're a person with a nervous system that gets overloaded.";
  }

  String _getEncouragementResponse() {
    return "You're welcome! And I want you to know - the fact that you're here, trying to understand yourself and build better habits, is genuinely amazing. Progress isn't linear. Some days you'll feel unstoppable, others you'll struggle to brush your teeth. Both are okay. You're not failing at ADHD - you're navigating a world that wasn't built for your brilliant, different brain. Keep going. I'm here whenever you need.";
  }

  String _getDefaultResponse(String input) {
    final responses = [
      "That's a great question. Let me think about what might help most... ",
      "I appreciate you sharing that. Here's what I know that might help: ",
      "Every brain works differently, and yours has its own beautiful patterns. Here's a thought: ",
    ];
    final prefix = responses[Random().nextInt(responses.length)];
    
    // Pull a relevant tip from knowledge base
    final categories = _knowledgeBase.values.toList();
    final randomCategory = categories[Random().nextInt(categories.length)];
    final tip = randomCategory[Random().nextInt(randomCategory.length)];
    
    return '$prefix$tip';
  }

  /// Generate task breakdown into micro-steps
  List<String> getTaskBreakdown(String taskName) {
    final random = Random();
    final templates = _getStepTemplates(taskName);
    
    // Generate 3-5 micro-steps
    final stepCount = random.nextInt(3) + 3; // 3-5 steps
    final steps = <String>[];
    
    for (int i = 0; i < stepCount && i < templates.length; i++) {
      steps.add(templates[i]);
    }
    
    return steps;
  }

  List<String> _getStepTemplates(String task) {
    // Intelligent step generation based on task type
    final lowerTask = task.toLowerCase();
    
    if (_containsAny(lowerTask, ['clean', 'tidy', 'organize', 'declutter'])) {
      return [
        "Pick up one item and decide its home",
        "Put that one item in its place",
        "Choose one surface to clear",
        "Wipe down that surface",
        "Take one bag of trash/recycling out",
      ];
    }
    if (_containsAny(lowerTask, ['write', 'report', 'essay', 'email', 'document'])) {
      return [
        "Open a blank document",
        "Write down 5 random ideas about the topic",
        "Pick the best 3 ideas",
        "Write 50 words about the first idea",
        "Review and clean up what you've written",
      ];
    }
    if (_containsAny(lowerTask, ['code', 'program', 'develop', 'app', 'software'])) {
      return [
        "Open your code editor",
        "Read the current code/requirements",
        "Write a single function or component",
        "Test what you've written",
        "Commit and push your changes",
      ];
    }
    if (_containsAny(lowerTask, ['exercise', 'workout', 'gym', 'run', 'walk'])) {
      return [
        "Put on your workout clothes",
        "Fill your water bottle",
        "Do 5 minutes of stretching",
        "Start with the easiest exercise",
        "Do one more minute than yesterday",
      ];
    }
    if (_containsAny(lowerTask, ['read', 'study', 'learn', 'research'])) {
      return [
        "Open the material you need to read",
        "Read for 5 minutes or one page",
        "Write down one thing you learned",
        "Read for another 5 minutes",
        "Summarize what you've read in 3 bullet points",
      ];
    }
    if (_containsAny(lowerTask, ['call', 'phone', 'talk', 'meeting'])) {
      return [
        "Open the contact/number you need to call",
        "Write down what you want to say",
        "Take a deep breath and dial",
        "Have the conversation",
        "Write a quick note about what was decided",
      ];
    }
    
    // Generic steps
    return [
      "Get the tools/materials you need for: $task",
      "Set a timer for 10 minutes",
      "Work on it until the timer goes off",
      "Take a 2-minute break",
      "Decide if you want to continue or stop here",
    ];
  }

  /// Get weekly insights based on habit data
  String getWeeklyInsight(Map<String, dynamic> stats) {
    final completionRate = stats['completion_rate'] ?? 0.0;
    final bestDay = stats['best_day'] ?? 'unknown';
    final streakLength = stats['streak'] ?? 0;
    final improvement = stats['improvement'] ?? 0.0;

    final parts = <String>[];
    
    if (completionRate >= 0.8) {
      parts.add("You've been crushing it with a ${(completionRate * 100).toInt()}% completion rate this week!");
    } else if (completionRate >= 0.5) {
      parts.add("You completed ${(completionRate * 100).toInt()}% of your habits this week — solid progress!");
    } else {
      parts.add("This week you completed ${(completionRate * 100).toInt()}% of your habits. Every check-in counts.");
    }

    if (bestDay != 'unknown') {
      parts.add("$bestDay was your strongest day.");
    }

    if (streakLength >= 7) {
      parts.add("Awesome $streakLength day streak — you're building real momentum!");
    } else if (streakLength >= 3) {
      parts.add("Nice $streakLength day streak going!");
    }

    if (improvement > 0) {
      parts.add("You've improved by ${(improvement * 100).toInt()}% compared to last week — keep going!");
    }

    parts.add("Remember: consistency beats perfection. You're doing great.");

    return parts.join(' ');
  }

  /// Emotional state detection for personalized responses
  String get moodInsight {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return "Mornings can be tough with ADHD. Your executive functioning is at its lowest right after waking. Give yourself grace and start with one tiny win.";
    } else if (hour < 17) {
      return "Afternoon slump hitting? This is when many ADHD brains struggle most. Try moving your body, changing your environment, or pairing tasks with a podcast.";
    } else {
      return "Evenings are when ADHD brains often come alive. Use this natural energy for creative tasks, but start winding down 1-2 hours before bed for better sleep.";
    }
  }
}