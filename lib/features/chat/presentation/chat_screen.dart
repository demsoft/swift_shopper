import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../models/chat_message.dart';
import '../providers/chat_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    super.key,
    required this.orderId,
    this.isShopper = false,
    this.otherPersonName = '',
    this.otherPersonRole = 'SHOPPER',
    this.otherPersonAvatarUrl,
  });

  final String orderId;
  final bool isShopper;
  final String otherPersonName;
  final String otherPersonRole;
  final String? otherPersonAvatarUrl;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  ChatMessage? _replyingTo;

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

  ChatArgs get _args =>
      ChatArgs(orderId: widget.orderId, isShopper: widget.isShopper);

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final reply = _replyingTo;
    _controller.clear();
    setState(() => _replyingTo = null);
    await ref.read(chatProvider(_args).notifier).sendTextMessage(
          text,
          replyToText: reply?.text ?? (reply?.imageUrl != null ? '📷 Photo' : null),
        );
    _scrollToBottom();
  }

  Future<void> _pickImage(ImageSource source, {bool fromSheet = false}) async {
    if (fromSheet) Navigator.of(context).pop();
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final name = picked.name;
    final ext = name.split('.').last.toLowerCase();
    final contentType = ext == 'png' ? 'image/png' : 'image/jpeg';
    try {
      await ref.read(chatProvider(_args).notifier).sendMediaMessage(
            bytes: bytes,
            fileName: name,
            contentType: contentType,
            isImage: true,
          );
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send image: $e')),
        );
      }
    }
  }

  Future<void> _pickFile() async {
    Navigator.of(context).pop(); // close bottom sheet
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;
    final name = file.name;
    final ext = name.split('.').last.toLowerCase();
    final isImage = ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext);
    final contentType = isImage
        ? (ext == 'png' ? 'image/png' : 'image/jpeg')
        : 'application/octet-stream';
    try {
      await ref.read(chatProvider(_args).notifier).sendMediaMessage(
            bytes: file.bytes!,
            fileName: name,
            contentType: contentType,
            isImage: isImage,
          );
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send file: $e')),
        );
      }
    }
  }

  void _showAttachOptions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Share',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0D1512)),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _AttachOption(
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    color: AppColors.primary,
                    onTap: () => _pickImage(ImageSource.camera, fromSheet: true),
                  ),
                  _AttachOption(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    color: const Color(0xFF1565C0),
                    onTap: () => _pickImage(ImageSource.gallery, fromSheet: true),
                  ),
                  _AttachOption(
                    icon: Icons.attach_file_rounded,
                    label: 'File',
                    color: const Color(0xFFE07B39),
                    onTap: _pickFile,
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatAsync = ref.watch(chatProvider(_args));

    // Auto-scroll when new messages arrive
    ref.listen(chatProvider(_args), (_, next) {
      if (next.hasValue) _scrollToBottom();
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F1),
      resizeToAvoidBottomInset: false,
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
                            ref.invalidate(chatProvider(_args)),
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
                      final isSent = widget.isShopper
                          ? msg.sender == SenderType.shopper
                          : msg.sender == SenderType.customer;
                      final timeStr = _fmtTime(msg.time);

                      Widget bubble;
                      if (msg.type == MessageType.image) {
                        bubble = _ImageBubble(
                          imageUrl: msg.imageUrl ?? '',
                          time: timeStr,
                          isSent: isSent,
                        );
                      } else if (isSent) {
                        bubble = _SentBubble(
                          text: msg.text ?? '',
                          time: timeStr,
                          replyToText: msg.replyToText,
                        );
                      } else {
                        bubble = _ReceivedBubble(
                          text: msg.text ?? '',
                          time: timeStr,
                          replyToText: msg.replyToText,
                        );
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _SwipeToReply(
                          onReply: () => setState(() => _replyingTo = msg),
                          child: bubble,
                        ),
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
          if (_replyingTo != null) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F6F4),
                borderRadius: BorderRadius.circular(12),
                border: const Border(
                  left: BorderSide(color: AppColors.primary, width: 3),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Replying to',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary)),
                        const SizedBox(height: 2),
                        Text(
                          _replyingTo!.text ?? (_replyingTo!.imageUrl != null ? '📷 Photo' : ''),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _replyingTo = null),
                    child: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF9A9C97)),
                  ),
                ],
              ),
            ),
          ],
          Row(
            children: [
              GestureDetector(
                onTap: isSending ? null : _showAttachOptions,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F6F4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.attach_file_rounded,
                      color: Color(0xFF6B7280), size: 22),
                ),
              ),
              const SizedBox(width: 8),
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
              const SizedBox(width: 8),
              GestureDetector(
                onTap: isSending ? null : () => _pickImage(ImageSource.camera),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F6F4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_rounded,
                      color: Color(0xFF6B7280), size: 22),
                ),
              ),
              const SizedBox(width: 8),
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
  const _SentBubble({required this.text, required this.time, this.replyToText});

  final String text;
  final String time;
  final String? replyToText;

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
            if (replyToText != null) ...[
              Container(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border(
                    left: BorderSide(color: Colors.white.withValues(alpha: 0.8), width: 3),
                  ),
                ),
                child: Text(
                  replyToText!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Colors.white70, height: 1.3),
                ),
              ),
            ],
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
  const _ReceivedBubble({required this.text, required this.time, this.replyToText});

  final String text;
  final String time;
  final String? replyToText;

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
            if (replyToText != null) ...[
              Container(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F2EF),
                  borderRadius: BorderRadius.circular(10),
                  border: const Border(
                    left: BorderSide(color: AppColors.primary, width: 3),
                  ),
                ),
                child: Text(
                  replyToText!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), height: 1.3),
                ),
              ),
            ],
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

// ===========================================================================
// ATTACH OPTION BUTTON (used in bottom sheet)
// ===========================================================================
class _AttachOption extends StatelessWidget {
  const _AttachOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0D1512),
            ),
          ),
        ],
      ),
    );
  }
}

class _SwipeToReply extends StatefulWidget {
  const _SwipeToReply({
    required this.child,
    required this.onReply,
  });

  final Widget child;
  final VoidCallback onReply;

  @override
  State<_SwipeToReply> createState() => _SwipeToReplyState();
}

class _SwipeToReplyState extends State<_SwipeToReply> {
  static const double _maxOffset = 86;
  static const double _triggerOffset = 62;

  double _offset = 0;
  bool _triggered = false;

  void _handleDragUpdate(DragUpdateDetails details) {
    final next = (_offset + details.delta.dx).clamp(0.0, _maxOffset);

    if (!_triggered && next >= _triggerOffset) {
      _triggered = true;
      HapticFeedback.lightImpact();
      widget.onReply();
    } else if (_triggered && next < (_triggerOffset * 0.5)) {
      _triggered = false;
    }

    setState(() => _offset = next);
  }

  void _handleDragEnd() {
    setState(() {
      _offset = 0;
      _triggered = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_offset / _triggerOffset).clamp(0.0, 1.0);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragUpdate: _handleDragUpdate,
      onHorizontalDragEnd: (_) => _handleDragEnd(),
      onHorizontalDragCancel: _handleDragEnd,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          Positioned(
            left: 8,
            child: Opacity(
              opacity: progress,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.reply_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
            transform: Matrix4.translationValues(_offset, 0, 0),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}
