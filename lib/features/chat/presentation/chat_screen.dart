import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../models/chat_message.dart';
import '../providers/chat_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    super.key,
    required this.orderId,
    this.otherPersonName = '',
    this.otherPersonRole = 'SHOPPER',
    this.otherPersonAvatarUrl,
  });

  final String orderId;
  final String otherPersonName;
  final String otherPersonRole;
  final String? otherPersonAvatarUrl;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _fmtTime(DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    await ref.read(chatProvider(widget.orderId).notifier).sendTextMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final chatAsync = ref.watch(chatProvider(widget.orderId));

    // Auto-scroll when new messages arrive
    ref.listen(chatProvider(widget.orderId), (_, next) {
      if (next.hasValue) _scrollToBottom();
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F1),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, chatAsync.valueOrNull?.isRealtimeConnected ?? false),
            Expanded(
              child: chatAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi_off_rounded,
                          size: 48, color: AppColors.textSecondary),
                      const SizedBox(height: 12),
                      Text(e.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 13)),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () =>
                            ref.invalidate(chatProvider(widget.orderId)),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (chat) {
                  if (chat.messages.isEmpty) {
                    return const Center(
                      child: Text(
                        'No messages yet.\nSay hello!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    );
                  }
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: chat.messages.length,
                    itemBuilder: (context, index) {
                      final msg = chat.messages[index];
                      final isSent = msg.sender == SenderType.customer;
                      final timeStr = _fmtTime(msg.time);

                      if (msg.type == MessageType.image) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _ImageBubble(
                            imageUrl: msg.imageUrl ?? '',
                            time: timeStr,
                            isSent: isSent,
                          ),
                        );
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: isSent
                            ? _SentBubble(text: msg.text ?? '', time: timeStr)
                            : _ReceivedBubble(
                                text: msg.text ?? '', time: timeStr),
                      );
                    },
                  );
                },
              ),
            ),
            _buildInputBar(chatAsync.valueOrNull?.isSending ?? false),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isConnected) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(8, 10, 16, 10),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Color(0xFF202123), size: 22),
          ),
          Stack(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFFE8A060),
                backgroundImage: widget.otherPersonAvatarUrl != null &&
                        widget.otherPersonAvatarUrl!.isNotEmpty
                    ? NetworkImage(widget.otherPersonAvatarUrl!)
                    : null,
                child: widget.otherPersonAvatarUrl == null ||
                        widget.otherPersonAvatarUrl!.isEmpty
                    ? const Icon(Icons.person, color: Colors.white, size: 22)
                    : null,
              ),
              Positioned(
                bottom: 1,
                right: 1,
                child: Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: isConnected
                        ? const Color(0xFF22C55E)
                        : const Color(0xFF9A9C97),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherPersonName.isNotEmpty
                      ? widget.otherPersonName
                      : 'Chat',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0D1512),
                  ),
                ),
                Text(
                  isConnected ? widget.otherPersonRole : 'Connecting...',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color:
                        isConnected ? AppColors.primary : AppColors.textSecondary,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(bool isSending) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
          12, 10, 12, MediaQuery.of(context).viewInsets.bottom + 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(minHeight: 44),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F6F4),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _controller,
                    maxLines: null,
                    textInputAction: TextInputAction.newline,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(
                          color: Color(0xFFADB5AD), fontSize: 14),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: isSending ? null : _send,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isSending
                        ? AppColors.primary.withValues(alpha: 0.5)
                        : AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: isSending
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Icon(Icons.send_rounded,
                          color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _QuickReplyChip(
                  label: 'SOUNDS GOOD!',
                  onTap: () {
                    _controller.text = 'Sounds good!';
                    _controller.selection = TextSelection.fromPosition(
                      TextPosition(offset: _controller.text.length),
                    );
                  },
                ),
                const SizedBox(width: 8),
                _QuickReplyChip(
                  label: 'WAIT A MOMENT',
                  onTap: () {
                    _controller.text = 'Wait a moment.';
                    _controller.selection = TextSelection.fromPosition(
                      TextPosition(offset: _controller.text.length),
                    );
                  },
                ),
                const SizedBox(width: 8),
                _QuickReplyChip(
                  label: 'CAN YOU CHECK?',
                  onTap: () {
                    _controller.text = 'Can you check?';
                    _controller.selection = TextSelection.fromPosition(
                      TextPosition(offset: _controller.text.length),
                    );
                  },
                ),
                const SizedBox(width: 8),
                _QuickReplyChip(
                  label: 'NO PROBLEM',
                  onTap: () {
                    _controller.text = 'No problem.';
                    _controller.selection = TextSelection.fromPosition(
                      TextPosition(offset: _controller.text.length),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// SENT BUBBLE
// ===========================================================================
class _SentBubble extends StatelessWidget {
  const _SentBubble({required this.text, required this.time});

  final String text;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.74),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        decoration: const BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(text,
                style: const TextStyle(
                    fontSize: 15, color: Colors.white, height: 1.45)),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(time,
                    style: const TextStyle(
                        fontSize: 11, color: Colors.white70)),
                const SizedBox(width: 4),
                const Icon(Icons.done_all_rounded,
                    size: 14, color: Colors.white70),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// RECEIVED TEXT BUBBLE
// ===========================================================================
class _ReceivedBubble extends StatelessWidget {
  const _ReceivedBubble({required this.text, required this.time});

  final String text;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.74),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(text,
                style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF0D1512),
                    height: 1.45)),
            const SizedBox(height: 6),
            Text(time,
                style: const TextStyle(
                    fontSize: 11, color: Color(0xFF9A9C97))),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// IMAGE BUBBLE
// ===========================================================================
class _ImageBubble extends StatelessWidget {
  const _ImageBubble(
      {required this.imageUrl, required this.time, required this.isSent});

  final String imageUrl;
  final String time;
  final bool isSent;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.74),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(4),
            topRight: const Radius.circular(20),
            bottomLeft: const Radius.circular(20),
            bottomRight: Radius.circular(isSent ? 4 : 20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(20),
              ),
              child: Image.network(
                imageUrl,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: double.infinity,
                  height: 200,
                  color: const Color(0xFFD9DDD7),
                  child: const Icon(Icons.image_outlined,
                      color: Colors.white54, size: 48),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
              child: Text(time,
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF9A9C97))),
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// QUICK REPLY CHIP
// ===========================================================================
class _QuickReplyChip extends StatelessWidget {
  const _QuickReplyChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFD9DDD7)),
        ),
        child: Text(
          label,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0D1512)),
        ),
      ),
    );
  }
}
