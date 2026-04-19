import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';

import 'package:fluffychat/config/themes.dart';
import 'package:fluffychat/l10n/l10n.dart';
import 'package:fluffychat/pages/chat/chat.dart';
import 'package:fluffychat/utils/date_time_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:fluffychat/utils/sync_status_localization.dart';
import 'package:fluffychat/widgets/avatar.dart';
import 'package:fluffychat/widgets/presence_builder.dart';

class ChatAppBarTitle extends StatelessWidget {
  final ChatController controller;
  const ChatAppBarTitle(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    final room = controller.room;
    if (controller.selectedEvents.isNotEmpty) {
      return Text(
        controller.selectedEvents.length.toString(),
        style: TextStyle(
          color: Theme.of(context).colorScheme.onTertiaryContainer,
        ),
      );
    }
    return InkWell(
      hoverColor: Colors.transparent,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      onTap: controller.isArchived
          ? null
          : () => FluffyThemes.isThreeColumnMode(context)
                ? controller.toggleDisplayChatDetailsColumn()
                : context.go('/rooms/${room.id}/details'),
      child: Row(
        children: [
          Hero(
            tag: 'content_banner',
            child: Avatar(
              mxContent: room.avatar,
              name: room.getLocalizedDisplayname(
                MatrixLocals(L10n.of(context)),
              ),
              size: 32,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  room.getLocalizedDisplayname(MatrixLocals(L10n.of(context))),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                StreamBuilder(
                  stream: room.client.onSyncStatus.stream,
                  builder: (context, snapshot) {
                    final status =
                        room.client.onSyncStatus.value ??
                        const SyncStatusUpdate(SyncStatus.waitingForResponse);
                    final hide =
                        FluffyThemes.isColumnMode(context) ||
                        (room.client.onSync.value != null &&
                            status.status != SyncStatus.error &&
                            room.client.prevBatch != null);
                    return AnimatedSize(
                      duration: FluffyThemes.animationDuration,
                      child: hide
                          ? PresenceBuilder(
                              userId: room.directChatMatrixID,
                              builder: (context, presence) {
                                final lastActiveTimestamp =
                                    presence?.lastActiveTimestamp;
                                final style = TextStyle(
                                  fontSize: 12,
                                  height: 1.1,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                );
                                if (presence?.currentlyActive == true) {
                                  return Text(
                                    L10n.of(context).currentlyActive,
                                    style: style,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  );
                                }
                                if (lastActiveTimestamp != null) {
                                  return Text(
                                    L10n.of(context).lastActiveAgo(
                                      lastActiveTimestamp.localizedTimeShort(
                                        context,
                                      ),
                                    ),
                                    style: style,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            )
                          : Row(
                              children: [
                                SizedBox.square(
                                  dimension: 9,
                                  child: CircularProgressIndicator.adaptive(
                                    strokeWidth: 1,
                                    value: status.progress,
                                    valueColor: status.error != null
                                        ? AlwaysStoppedAnimation<Color>(
                                            Theme.of(context).colorScheme.error,
                                          )
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    status.calcLocalizedString(context),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      height: 1.1,
                                      color: status.error != null
                                          ? Theme.of(context).colorScheme.error
                                          : Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
