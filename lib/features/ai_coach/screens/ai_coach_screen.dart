import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/chat_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/brain_mascot.dart';

class AiCoachScreen extends StatefulWidget {
  const AiCoachScreen({super.key});

  @override
  State<AiCoachScreen> createState() => _AiCoachScreenState();
}

class _AiCoachScreenState extends State<AiCoachScreen> {
  final ChatController controller = Get.find<ChatController>();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final Worker _autoScroll;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      final has = _textController.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
    // Registered once (not per-build) so the listener isn't duplicated.
    _autoScroll = ever(controller.messages, (_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _autoScroll.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send([String? value]) {
    final text = (value ?? _textController.text).trim();
    if (text.isEmpty) return;
    controller.sendMessage(text);
    _textController.clear();
  }

  void _confirmClear() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.delete_sweep_rounded, color: ctx.colors.warning),
              title: const Text('Clear conversation', style: TextStyle(fontFamily: 'Inter')),
              onTap: () {
                controller.clearConversation();
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
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
            const SizedBox(height: 8),
            _buildDisclaimer(context),
            const SizedBox(height: 8),
            Expanded(
              child: Obx(() {
                if (controller.messages.isEmpty) {
                  return _buildEmptyState(context);
                }
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  physics: const BouncingScrollPhysics(),
                  itemCount: controller.messages.length,
                  itemBuilder: (context, index) =>
                      _buildMessageBubble(context, controller.messages[index]),
                );
              }),
            ),
            Obx(() => controller.isLoading.value
                ? _buildTypingIndicator(context)
                : const SizedBox.shrink()),
            _buildInputBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: context.colors.primary, shape: BoxShape.circle),
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(controller.isLiveAi ? '💥' : '📴', style: const TextStyle(fontSize: 10)),
                        const SizedBox(width: 4),
                        Text(
                          controller.isLiveAi ? 'AI-powered' : 'On-device coach',
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
          Semantics(
            button: true,
            label: 'Conversation options',
            child: GestureDetector(
              onTap: _confirmClear,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: context.colors.outlineVariant, width: 1.5),
                ),
                child: Icon(Icons.more_horiz_rounded, color: context.colors.text, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimer(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: context.colors.iconBubble,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.favorite_rounded, size: 14, color: context.colors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'A supportive coach, not a therapist or doctor. In a crisis, contact 988 (US) or your local line.',
              style: TextStyle(
                fontSize: 11,
                height: 1.3,
                color: context.colors.textVariant,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(BuildContext context) {
    return Container(
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
          Expanded(
            child: TextField(
              controller: _textController,
              textInputAction: TextInputAction.send,
              minLines: 1,
              maxLines: 4,
              style: TextStyle(fontFamily: 'Inter', fontSize: 15, color: context.colors.text),
              onSubmitted: _send,
              decoration: InputDecoration(
                hintText: 'Message your AI coach…',
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
          Obx(() {
            final listening = controller.isListening.value;
            final showSend = _hasText;
            return Semantics(
              button: true,
              label: showSend
                  ? 'Send message'
                  : listening
                      ? 'Stop voice input'
                      : 'Start voice input',
              child: GestureDetector(
                onTap: showSend ? _send : controller.startVoiceInput,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: listening ? context.colors.warning : context.colors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    showSend ? Icons.arrow_upward_rounded : Icons.mic_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 24),
        ...controller.suggestedPrompts.map((prompt) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Semantics(
              button: true,
              label: 'Ask: $prompt',
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
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMessageBubble(BuildContext context, ChatMessage message) {
    return Semantics(
      label: '${message.isUser ? 'You' : 'Coach'}: ${message.text}',
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Row(
          mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (!message.isUser) ...[
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: context.colors.primary, shape: BoxShape.circle),
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
                  message.text.isEmpty ? '…' : message.text,
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
            decoration: BoxDecoration(color: context.colors.primary, shape: BoxShape.circle),
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
                _AnimatedDot(delay: 0),
                const SizedBox(width: 4),
                _AnimatedDot(delay: 400),
                const SizedBox(width: 4),
                _AnimatedDot(delay: 800),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedDot extends StatefulWidget {
  final int delay;
  const _AnimatedDot({required this.delay});

  @override
  State<_AnimatedDot> createState() => _AnimatedDotState();
}

class _AnimatedDotState extends State<_AnimatedDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(widget.delay / 1200, (widget.delay + 400) / 1200, curve: Curves.easeInOut),
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
        decoration: BoxDecoration(color: context.colors.primary, shape: BoxShape.circle),
      ),
    );
  }
}
