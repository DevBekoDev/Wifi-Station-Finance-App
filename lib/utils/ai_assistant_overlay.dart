import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:wsfm/utils/app_navigator_key.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AiAssistantConnector {
  const AiAssistantConnector({
    required this.sendText,
    this.listenToUser,
    this.speakAssistantMessage,
  });

  final Future<String> Function(
  String message,
  List<Map<String, String>> history,
) sendText;
  final Future<String?> Function()? listenToUser;
  final Future<void> Function(String text)? speakAssistantMessage;
}

class AiAssistantOverlay extends StatefulWidget {
  const AiAssistantOverlay({
    super.key,
    required this.child,
    required this.currentRouteListenable,
    required this.hiddenRoutes,
    required this.connector,
  });

  final Widget child;
  final ValueListenable<String?> currentRouteListenable;
  final Set<String> hiddenRoutes;
  final AiAssistantConnector connector;

  @override
  State<AiAssistantOverlay> createState() => _AiAssistantOverlayState();
}

class _AiAssistantOverlayState extends State<AiAssistantOverlay> {
  bool _isAssistantOpen = false;
Future<void> _openAssistant() async {
  final navigatorContext = appNavigatorKey.currentState?.overlay?.context;

  if (navigatorContext == null) {
    return;
  }

  setState(() {
    _isAssistantOpen = true;
  });

  await showModalBottomSheet(
    context: navigatorContext,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) {
      return AiAssistantChatSheet(connector: widget.connector);
    },
  );

  if (mounted) {
    setState(() {
      _isAssistantOpen = false;
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,

        ValueListenableBuilder<String?>(
          valueListenable: widget.currentRouteListenable,
          builder: (context, routeName, _) {
 if (_isAssistantOpen || widget.hiddenRoutes.contains(routeName)) {
  return const SizedBox.shrink();
}

            return Positioned(
              right: 18,
              bottom: 24 + MediaQuery.of(context).viewPadding.bottom,
              child: FloatingAiButton(onTap: _openAssistant),
            );
          },
        ),
      ],
    );
  }
}

class FloatingAiButton extends StatefulWidget {
  const FloatingAiButton({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  State<FloatingAiButton> createState() => _FloatingAiButtonState();
}

class _FloatingAiButtonState extends State<FloatingAiButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _scale = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF7C3AED),
                    Color(0xFF2563EB),
                    Color(0xFF06B6D4),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withOpacity(0.35),
                    blurRadius: 28,
                    spreadRadius: 2,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Container(
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0B1220).withOpacity(0.88),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.18),
                  ),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 31,
                ),
              ),
            ),

            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: const Text(
                  'AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum AiMessageRole { user, assistant }

class AiMessage {
  AiMessage({
    required this.role,
    required this.text,
  });

  final AiMessageRole role;
  final String text;

  Map<String, dynamic> toMap() {
    return {
      'role': role.name,
      'text': text,
    };
  }

  factory AiMessage.fromMap(Map<String, dynamic> map) {
    return AiMessage(
      role: map['role'] == 'user'
          ? AiMessageRole.user
          : AiMessageRole.assistant,
      text: map['text'] ?? '',
    );
  }
}

class AiAssistantChatSheet extends StatefulWidget {
  const AiAssistantChatSheet({
    super.key,
    required this.connector,
  });

  final AiAssistantConnector connector;

  @override
  State<AiAssistantChatSheet> createState() => _AiAssistantChatSheetState();
}

class _AiAssistantChatSheetState extends State<AiAssistantChatSheet> {
  @override
void initState() {
  super.initState();
  _loadMessages();
}
Future<void> _loadMessages() async {
  try {
    final prefs = await SharedPreferences.getInstance();

    // Remove old shared chat history so users do not see each other's old messages.
    await prefs.remove(_legacyStorageKey);

    final savedMessages = prefs.getStringList(_storageKey);

    if (savedMessages == null || savedMessages.isEmpty) {
      _messages.add(_welcomeMessage);
    } else {
      _messages.addAll(
        savedMessages.map((messageJson) {
          final decoded = jsonDecode(messageJson) as Map<String, dynamic>;
          return AiMessage.fromMap(decoded);
        }),
      );
    }
  } catch (e) {
    _messages
      ..clear()
      ..add(_welcomeMessage);

    debugPrint('Failed to load AI messages: $e');
  }

  if (mounted) {
    setState(() {
      _isLoadingMessages = false;
    });
  }

  _scrollToBottom();
}

Future<void> _saveMessages() async {
  try {
    final prefs = await SharedPreferences.getInstance();

    final encodedMessages = _messages.map((message) {
      return jsonEncode(message.toMap());
    }).toList();

    await prefs.setStringList(_storageKey, encodedMessages);
  } catch (e) {
    debugPrint('Failed to save AI messages: $e');
  }
}

Future<void> _clearMessages() async {
  final prefs = await SharedPreferences.getInstance();

  await prefs.remove(_storageKey);

  setState(() {
    _messages
      ..clear()
      ..add(_welcomeMessage);
  });

  _scrollToBottom();
}
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

static const String _legacyStorageKey = 'wsfm_ai_chat_messages';

String get _storageKey {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    return 'wsfm_ai_chat_messages_guest';
  }

  return 'wsfm_ai_chat_messages_${user.uid}';
}

final List<AiMessage> _messages = [];

bool _isSending = false;
bool _isListening = false;
bool _isLoadingMessages = true;

AiMessage get _welcomeMessage {
  return AiMessage(
    role: AiMessageRole.assistant,
    text:
        'Hi, I am your WSFM AI assistant. Ask me about sales, expenses, center reports, or daily finance.',
  );
}

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();

    if (text.isEmpty || _isSending) return;
final historyBeforeNewMessage = _messages.map((message) {
  return {
    'role': message.role == AiMessageRole.user ? 'user' : 'assistant',
    'text': message.text,
  };
}).toList();
setState(() {
  _messages.add(AiMessage(role: AiMessageRole.user, text: text));
  _inputController.clear();
  _isSending = true;
});

await _saveMessages();
_scrollToBottom();

    try {
      final answer = await widget.connector.sendText(
  text,
  historyBeforeNewMessage,
);

      setState(() {
  _messages.add(AiMessage(role: AiMessageRole.assistant, text: answer));
});

await _saveMessages();
_scrollToBottom();
    } catch (e, stackTrace) {
  debugPrint('AI ASSISTANT ERROR: $e');
  debugPrint('AI ASSISTANT STACK: $stackTrace');

  setState(() {
    _messages.add(
      AiMessage(
        role: AiMessageRole.assistant,
        text: 'AI error: $e',
      ),
    );
  });

  await _saveMessages();
} finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _listen() async {
    if (widget.connector.listenToUser == null || _isListening) return;

    setState(() => _isListening = true);

    try {
      final words = await widget.connector.listenToUser!.call();

      if (words != null && words.trim().isNotEmpty) {
        _inputController.text = words.trim();
        _inputController.selection = TextSelection.fromPosition(
          TextPosition(offset: _inputController.text.length),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isListening = false);
      }
    }
  }

  Future<void> _speakLastAssistantMessage() async {
    if (widget.connector.speakAssistantMessage == null) return;

    final lastAssistantMessage = _messages.reversed.firstWhere(
      (message) => message.role == AiMessageRole.assistant,
      orElse: () => AiMessage(
        role: AiMessageRole.assistant,
        text: '',
      ),
    );

    if (lastAssistantMessage.text.trim().isNotEmpty) {
      await widget.connector.speakAssistantMessage!.call(
        lastAssistantMessage.text,
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: DraggableScrollableSheet(
        initialChildSize: 0.86,
        minChildSize: 0.55,
        maxChildSize: 0.94,
        builder: (context, sheetScrollController) {
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(32),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF08111F),
                      Color(0xFF101B33),
                      Color(0xFF111827),
                    ],
                  ),
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withOpacity(0.12),
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    _buildHeader(context),
                    Expanded(child: _buildMessages()),
                    if (_isSending) _buildTypingIndicator(),
                    _buildInputBar(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 12, 12),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF7C3AED),
                  Color(0xFF06B6D4),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF06B6D4).withOpacity(0.25),
                  blurRadius: 20,
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WSFM AI Assistant',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    decoration: TextDecoration.none,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Finance help, reports, sales and expenses',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
         IconButton(
  tooltip: 'Clear chat',
  onPressed: _clearMessages,
  icon: const Icon(
    Icons.delete_outline_rounded,
    color: Colors.white,
  ),
),
IconButton(
  tooltip: 'Speak last answer',
  onPressed: _speakLastAssistantMessage,
  icon: const Icon(
    Icons.volume_up_rounded,
    color: Colors.white,
  ),
),
IconButton(
  onPressed: () => Navigator.pop(context),
  icon: const Icon(
    Icons.close_rounded,
    color: Colors.white,
  ),
),
        ],
      ),
    );
  }

Widget _buildMessages() {
  if (_isLoadingMessages) {
    return const Center(
      child: CircularProgressIndicator(
        color: Colors.white,
      ),
    );
  }

  return ListView.builder(
    controller: _scrollController,
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
    itemCount: _messages.length,
    itemBuilder: (context, index) {
      return AiMessageBubble(message: _messages[index]);
    },
  );
}

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: 18, bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: const Text(
              'AI is thinking...',
              style: TextStyle(
                color: Color(0xFFCBD5E1),
                fontSize: 12,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
        decoration: BoxDecoration(
          color: const Color(0xFF020617).withOpacity(0.55),
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.08)),
          ),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: _listen,
              icon: Icon(
                _isListening ? Icons.graphic_eq_rounded : Icons.mic_rounded,
                color: _isListening
                    ? const Color(0xFF22C55E)
                    : const Color(0xFFCBD5E1),
              ),
            ),
            Expanded(
              child: TextField(
                controller: _inputController,
                minLines: 1,
                maxLines: 4,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: _isListening
                      ? 'Listening...'
                      : 'Ask about sales, expenses, reports...',
                  hintStyle: const TextStyle(color: Color(0xFF64748B)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.07),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 13,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF2563EB),
                      Color(0xFF7C3AED),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withOpacity(0.25),
                      blurRadius: 18,
                    ),
                  ],
                ),
                child: _isSending
                    ? const Padding(
                        padding: EdgeInsets.all(13),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.arrow_upward_rounded,
                        color: Colors.white,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AiMessageBubble extends StatelessWidget {
  const AiMessageBubble({
    super.key,
    required this.message,
  });

  final AiMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == AiMessageRole.user;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        decoration: BoxDecoration(
          gradient: isUser
              ? const LinearGradient(
                  colors: [
                    Color(0xFF2563EB),
                    Color(0xFF7C3AED),
                  ],
                )
              : null,
          color: isUser ? null : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 5),
            bottomRight: Radius.circular(isUser ? 5 : 20),
          ),
          border: Border.all(
            color: isUser
                ? Colors.white.withOpacity(0.06)
                : Colors.white.withOpacity(0.08),
          ),
        ),
        child: Text(
          message.text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            height: 1.35,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }
}