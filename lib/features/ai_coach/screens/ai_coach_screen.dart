import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/chat_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/pro_gate.dart';
import '../../../shared/widgets/brain_mascot.dart';

class AiCoachScreen extends StatelessWidget {
  const AiCoachScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ChatController>();
    final TextEditingController textController = TextEditingController();
    final ScrollController scrollController = ScrollController();

    ever(controller.messages, (_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scrollController.hasClients) {
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    });

    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: ProGate(
          featureName: 'AI Coach',
          child: Column(
            children: [
              // Custom Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: context.colors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const BrainMascot(size: 28),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AI Coach',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: context.colors.text,
                                fontFamily: 'Inter',
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: context.colors.iconBubble,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Text('💥', style: TextStyle(fontSize: 10)),
                                  const SizedBox(width: 4),
                                  Text(
                                    'AI-powered',
                                    style: TextStyle(
                                      color: context.colors.primary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: context.colors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: context.colors.outlineVariant, width: 1.5),
                      ),
                      child: Icon(Icons.more_horiz_rounded, color: context.colors.text, size: 20),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),
              Text(
                'Your ADHD-friendly coach 💜',
                style: TextStyle(
                  color: context.colors.textVariant,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 16),

              // Messages
              Expanded(
                child: Obx(() {
                  if (controller.messages.isEmpty) {
                    return _buildEmptyState(context, controller);
                  }
                  return ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    physics: const BouncingScrollPhysics(),
                    itemCount: controller.messages.length,
                    itemBuilder: (context, index) {
                      final message = controller.messages[index];
                      return _buildMessageBubble(context, message);
                    },
                  );
                }),
              ),

              // Typing indicator
              Obx(() => controller.isLoading.value
                  ? _buildTypingIndicator(context)
                  : const SizedBox.shrink()),

              // Input bar
              Container(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 12,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 12,
                ),
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  border: Border(top: BorderSide(color: context.colors.outlineVariant.withValues(alpha: 0.5))),
                ),
                child: Row(
                  children: [
                    // Text field
                    Expanded(
                      child: TextField(
                        controller: textController,
                        textInputAction: TextInputAction.send,
                        style: TextStyle(fontFamily: 'Inter', fontSize: 15, color: context.colors.text),
                        onSubmitted: (value) {
                          if (value.trim().isNotEmpty) {
                            controller.sendMessage(value);
                            textController.clear();
                          }
                        },
                        decoration: InputDecoration(
                          hintText: 'Message your AI coach...',
                          hintStyle: TextStyle(color: context.colors.textVariant, fontFamily: 'Inter', fontSize: 15),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(color: context.colors.outlineVariant),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(color: context.colors.outlineVariant),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(color: context.colors.primary),
                          ),
                          filled: true,
                          fillColor: context.colors.surface,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Send/Mic button
                    GestureDetector(
                      onTap: () {
                        if (textController.text.trim().isNotEmpty) {
                          controller.sendMessage(textController.text);
                          textController.clear();
                        } else {
                          controller.startVoiceInput();
                        }
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: context.colors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.mic_rounded, color: Colors.white, size: 22),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ChatController controller) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 40),
        // Suggested prompts
        ...controller.suggestedPrompts.map((prompt) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () => controller.sendMessage(prompt),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: context.colors.outlineVariant),
                  boxShadow: context.colors.cardShadow,
                ),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, color: context.colors.primary, size: 18),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        prompt,
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                          color: context.colors.text,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: context.colors.outlineVariant, size: 20),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMessageBubble(BuildContext context, ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: context.colors.primary,
                shape: BoxShape.circle,
              ),
              child: const BrainMascot(size: 20),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: message.isUser
                    ? (context.isDarkTheme ? const Color(0xFF23304A) : const Color(0xFFE8EEFA))
                    : context.colors.iconBubble,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  fontSize: 15,
                  fontFamily: 'Inter',
                  color: context.colors.text,
                  height: 1.5,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: context.colors.primary,
              shape: BoxShape.circle,
            ),
            child: const BrainMascot(size: 20),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: context.colors.iconBubble,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const SizedBox(width: 4),
                _buildDot(400),
                const SizedBox(width: 4),
                _buildDot(800),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int delay) {
    return _AnimatedDot(delay: delay);
  }
}

class _AnimatedDot extends StatefulWidget {
  final int delay;
  const _AnimatedDot({required this.delay});

  @override
  State<_AnimatedDot> createState() => _AnimatedDotState();
}

class _AnimatedDotState extends State<_AnimatedDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(
          widget.delay / 1200,
          (widget.delay + 400) / 1200,
          curve: Curves.easeInOut,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: context.colors.primary,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
