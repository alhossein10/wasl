import 'package:flutter/material.dart';

import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';

import 'package:fluffychat/l10n/l10n.dart';
import 'package:fluffychat/pages/chat_details/chat_details.dart';
import 'package:fluffychat/pages/chat_details/participant_list_item.dart';
import 'package:fluffychat/utils/fluffy_share.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:fluffychat/widgets/avatar.dart';
import 'package:fluffychat/widgets/chat_settings_popup_menu.dart';
import 'package:fluffychat/widgets/layouts/max_width_body.dart';
import 'package:fluffychat/widgets/matrix.dart';
import '../../utils/url_launcher.dart';
import '../../widgets/mxc_image_viewer.dart';
import '../../widgets/qr_code_viewer.dart';

class ChatDetailsView extends StatelessWidget {
  final ChatDetailsController controller;

  const ChatDetailsView(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final room = Matrix.of(context).client.getRoomById(controller.roomId!);
    if (room == null) {
      return Scaffold(
        appBar: AppBar(title: Text(L10n.of(context).oopsSomethingWentWrong)),
        body: Center(
          child: Text(L10n.of(context).youAreNoLongerParticipatingInThisChat),
        ),
      );
    }

    final directChatMatrixID = room.directChatMatrixID;
    final roomAvatar = room.avatar;

    return StreamBuilder(
      stream: room.client.onRoomState.stream.where(
        (update) => update.roomId == room.id,
      ),
      builder: (context, snapshot) {
        var members = room.getParticipants().toList()
          ..sort((b, a) => a.powerLevel.compareTo(b.powerLevel));
        members = members.take(10).toList();
        final actualMembersCount =
            (room.summary.mInvitedMemberCount ?? 0) +
            (room.summary.mJoinedMemberCount ?? 0);
        final canRequestMoreMembers = members.length < actualMembersCount;
        final iconColor = theme.textTheme.bodyLarge!.color;
        final displayname = room.getLocalizedDisplayname(
          MatrixLocals(L10n.of(context)),
        );
        return Scaffold(
          appBar: AppBar(
            leading:
                controller.widget.embeddedCloseButton ??
                const Center(child: BackButton()),
            elevation: theme.appBarTheme.elevation,
            actions: <Widget>[
              if (room.canonicalAlias.isNotEmpty)
                IconButton(
                  tooltip: L10n.of(context).share,
                  icon: const Icon(Icons.qr_code_rounded),
                  onPressed: () =>
                      showQrCodeViewer(context, room.canonicalAlias),
                )
              else if (directChatMatrixID != null)
                IconButton(
                  tooltip: L10n.of(context).share,
                  icon: const Icon(Icons.qr_code_rounded),
                  onPressed: () =>
                      showQrCodeViewer(context, directChatMatrixID),
                ),
              if (controller.widget.embeddedCloseButton == null)
                ChatSettingsPopupMenu(room, false),
            ],
            title: Text(L10n.of(context).chatDetails),
            backgroundColor: theme.appBarTheme.backgroundColor,
          ),
          body: MaxWidthBody(
            child: ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
              itemCount: members.length + 1 + (canRequestMoreMembers ? 1 : 0),
              itemBuilder: (BuildContext context, int i) {
                final colorScheme = theme.colorScheme;
                if (i == 0) {
                  final canEditName = room.canChangeStateEvent(
                    EventTypes.RoomName,
                  );
                  final canEditTopic = room.canChangeStateEvent(
                    EventTypes.RoomTopic,
                  );
                  final displaynameAction = room.isDirectChat
                      ? null
                      : canEditName
                      ? controller.setDisplaynameAction
                      : () => FluffyShare.share(
                          displayname,
                          context,
                          copyOnly: true,
                        );

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _DetailCard(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 14),
                                child: Stack(
                                  children: [
                                    Hero(
                                      tag:
                                          controller
                                                  .widget
                                                  .embeddedCloseButton !=
                                              null
                                          ? 'embedded_content_banner'
                                          : 'content_banner',
                                      child: Avatar(
                                        mxContent: room.avatar,
                                        name: displayname,
                                        size: Avatar.defaultSize * 2.35,
                                        onTap: roomAvatar != null
                                            ? () => showDialog(
                                                context: context,
                                                builder: (_) =>
                                                    MxcImageViewer(roomAvatar),
                                              )
                                            : null,
                                      ),
                                    ),
                                    if (!room.isDirectChat &&
                                        room.canChangeStateEvent(
                                          EventTypes.RoomAvatar,
                                        ))
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: FloatingActionButton.small(
                                          onPressed: controller.setAvatarAction,
                                          heroTag: null,
                                          elevation: 0,
                                          child: const Icon(
                                            Icons.camera_alt_outlined,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 2),
                                    Text(
                                      displayname,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        FilledButton.tonalIcon(
                                          onPressed: displaynameAction,
                                          icon: Icon(
                                            room.isDirectChat
                                                ? Icons.chat_bubble_outline
                                                : canEditName
                                                ? Icons.edit_outlined
                                                : Icons.copy_outlined,
                                            size: 18,
                                          ),
                                          label: Text(
                                            room.isDirectChat
                                                ? L10n.of(context).directChat
                                                : canEditName
                                                ? L10n.of(context).edit
                                                : L10n.of(context).copy,
                                          ),
                                        ),
                                        OutlinedButton.icon(
                                          onPressed: room.isDirectChat
                                              ? null
                                              : () => context.push(
                                                  '/rooms/${controller.roomId}/details/members',
                                                ),
                                          icon: const Icon(
                                            Icons.group_outlined,
                                            size: 18,
                                          ),
                                          label: Text(
                                            L10n.of(context).countParticipants(
                                              actualMembersCount,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (canEditTopic || room.topic.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _DetailCard(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      L10n.of(context).chatDescription,
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            color: colorScheme.secondary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const Spacer(),
                                    if (canEditTopic)
                                      IconButton(
                                        onPressed: controller.setTopicAction,
                                        tooltip: L10n.of(
                                          context,
                                        ).setChatDescription,
                                        icon: const Icon(Icons.edit_outlined),
                                      ),
                                  ],
                                ),
                                SelectableLinkify(
                                  text: room.topic.isEmpty
                                      ? L10n.of(context).noChatDescriptionYet
                                      : room.topic,
                                  textScaleFactor: MediaQuery.textScalerOf(
                                    context,
                                  ).scale(1),
                                  options: const LinkifyOptions(
                                    humanize: false,
                                  ),
                                  linkStyle: TextStyle(
                                    color: colorScheme.primary,
                                    decorationColor: colorScheme.primary,
                                  ),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontStyle: room.topic.isEmpty
                                        ? FontStyle.italic
                                        : FontStyle.normal,
                                  ),
                                  onOpen: (url) =>
                                      UrlLauncher(context, url.url).launchUrl(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      if (!room.isDirectChat) ...[
                        const SizedBox(height: 10),
                        _DetailCard(
                          child: Column(
                            children: [
                              _ActionTile(
                                leadingIcon:
                                    Icons.admin_panel_settings_outlined,
                                iconColor: iconColor,
                                title: L10n.of(context).accessAndVisibility,
                                subtitle: L10n.of(
                                  context,
                                ).accessAndVisibilityDescription,
                                onTap: () => context.push(
                                  '/rooms/${room.id}/details/access',
                                ),
                              ),
                              Divider(
                                height: 1,
                                indent: 70,
                                endIndent: 16,
                                color: colorScheme.outlineVariant.withValues(
                                  alpha: 0.35,
                                ),
                              ),
                              _ActionTile(
                                leadingIcon: Icons.tune_outlined,
                                iconColor: iconColor,
                                title: L10n.of(context).chatPermissions,
                                subtitle: L10n.of(
                                  context,
                                ).whoCanPerformWhichAction,
                                onTap: () => context.push(
                                  '/rooms/${room.id}/details/permissions',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          L10n.of(
                            context,
                          ).countParticipants(actualMembersCount),
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: colorScheme.secondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (!room.isDirectChat && room.canInvite) ...[
                        const SizedBox(height: 8),
                        _DetailCard(
                          child: ListTile(
                            title: Text(L10n.of(context).inviteContact),
                            leading: CircleAvatar(
                              backgroundColor: colorScheme.primaryContainer,
                              foregroundColor: colorScheme.onPrimaryContainer,
                              radius: Avatar.defaultSize / 2,
                              child: const Icon(Icons.add_outlined),
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => context.go('/rooms/${room.id}/invite'),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                    ],
                  );
                }
                if (i < members.length + 1) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: _DetailCard(
                      child: ParticipantListItem(members[i - 1]),
                    ),
                  );
                }
                return _DetailCard(
                  child: ListTile(
                    title: Text(
                      L10n.of(context).loadCountMoreParticipants(
                        actualMembersCount - members.length,
                      ),
                    ),
                    leading: CircleAvatar(
                      backgroundColor: theme.scaffoldBackgroundColor,
                      child: const Icon(
                        Icons.group_outlined,
                        color: Colors.grey,
                      ),
                    ),
                    onTap: () => context.push(
                      '/rooms/${controller.roomId!}/details/members',
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _DetailCard extends StatelessWidget {
  final Widget child;

  const _DetailCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.hardEdge,
      child: child,
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData leadingIcon;
  final Color? iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.leadingIcon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: colorScheme.surfaceContainer,
        foregroundColor: iconColor,
        child: Icon(leadingIcon),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
