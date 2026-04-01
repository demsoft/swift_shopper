import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.isMe,
    this.message,
    this.imageUrl,
    this.trailing,
    required this.timeLabel,
  });

  final bool isMe;
  final String? message;
  final String? imageUrl;
  final Widget? trailing;
  final String timeLabel;

  @override
  Widget build(BuildContext context) {
    final bubbleColor =
        isMe ? AppColors.bubbleOutgoing : AppColors.bubbleIncoming;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: AppDimens.gapXs),
          padding: const EdgeInsets.all(AppDimens.gapMd),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (message?.isNotEmpty ?? false)
                Text(message!, style: Theme.of(context).textTheme.bodyMedium),
              if (imageUrl?.isNotEmpty ?? false) ...[
                if (message?.isNotEmpty ?? false)
                  const SizedBox(height: AppDimens.gapSm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    imageUrl!,
                    height: 160,
                    width: 220,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 160,
                        width: 220,
                        color: AppColors.background,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.broken_image_outlined,
                          color: AppColors.textSecondary,
                        ),
                      );
                    },
                  ),
                ),
              ],
              if (trailing != null) ...[
                const SizedBox(height: AppDimens.gapSm),
                trailing!,
              ],
              const SizedBox(height: AppDimens.gapXs),
              Text(
                timeLabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
