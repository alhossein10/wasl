import 'package:flutter/material.dart';

import 'package:matrix/matrix.dart';

import 'package:fluffychat/config/themes.dart';

class UnreadBubble extends StatelessWidget {
  final Room room;
  const UnreadBubble({required this.room, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unread = room.isUnread;
    final hasNotifications = room.notificationCount > 0;
    final hasIndicator = unread || room.hasNewMessages;
    final countLabel = room.notificationCount > 999
        ? '999+'
        : room.notificationCount.toString();
    final unreadBubbleSize = hasNotifications ? 22.0 : 10.0;

    if (!hasIndicator) return const SizedBox.shrink();

    return AnimatedContainer(
      duration: FluffyThemes.animationDuration,
      curve: FluffyThemes.animationCurve,
      alignment: Alignment.center,
      padding: hasNotifications
          ? const EdgeInsets.symmetric(horizontal: 8)
          : EdgeInsets.zero,
      height: unreadBubbleSize,
      width: hasNotifications
          ? (unreadBubbleSize - 10) * countLabel.length + 16
          : unreadBubbleSize,
      decoration: BoxDecoration(
        color: room.highlightCount > 0
            ? theme.colorScheme.error
            : hasNotifications || room.markedUnread
            ? theme.colorScheme.primary
            : theme.colorScheme.primary.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(999),
      ),
      child: hasNotifications
          ? Text(
              countLabel,
              style: TextStyle(
                color: room.highlightCount > 0
                    ? theme.colorScheme.onError
                    : hasNotifications
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onPrimaryContainer,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
              textAlign: TextAlign.center,
            )
          : const SizedBox.shrink(),
    );
  }
}
