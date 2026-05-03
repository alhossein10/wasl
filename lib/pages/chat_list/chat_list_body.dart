import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:matrix/matrix.dart';

import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/config/setting_keys.dart';
import 'package:fluffychat/l10n/l10n.dart';
import 'package:fluffychat/pages/chat_list/chat_list.dart';
import 'package:fluffychat/pages/chat_list/chat_list_item.dart';
import 'package:fluffychat/pages/chat_list/dummy_chat_list_item.dart';
import 'package:fluffychat/pages/chat_list/search_title.dart';
import 'package:fluffychat/pages/chat_list/space_view.dart';
import 'package:fluffychat/pages/chat_list/status_msg_list.dart';
import 'package:fluffychat/utils/stream_extension.dart';
import 'package:fluffychat/widgets/adaptive_dialogs/public_room_dialog.dart';
import 'package:fluffychat/widgets/adaptive_dialogs/show_modal_action_popup.dart';
import 'package:fluffychat/widgets/avatar.dart';
import '../../config/themes.dart';
import '../../widgets/adaptive_dialogs/user_dialog.dart';
import '../../widgets/matrix.dart';
import '../../utils/filter_item.dart';
import '../../utils/chat_folder.dart';
import 'chat_list_header.dart';

/// Parses [AppSettings.defaultHomeserver] to a host.
String _defaultHomeserverHost() {
  final raw = AppSettings.defaultHomeserver.value.trim();
  if (raw.contains('://')) {
    return Uri.tryParse(raw)?.host ?? raw.split('/').first;
  }
  return raw.split('/').first;
}

String _normalizeHomeserverDomain(String? value) {
  if (value == null) return '';
  final trimmed = value.trim().toLowerCase();
  if (trimmed.isEmpty) return '';
  if (trimmed.contains('://')) {
    return Uri.tryParse(trimmed)?.host.toLowerCase() ?? trimmed;
  }
  final parsed = Uri.tryParse('https://$trimmed');
  return parsed?.host.toLowerCase() ?? trimmed;
}

String? _domainFromMatrixId(String matrixId) {
  final separatorIndex = matrixId.indexOf(':');
  return separatorIndex > 0 ? matrixId.substring(separatorIndex + 1) : null;
}

class ChatListViewBody extends StatelessWidget {
  final ChatListController controller;

  const ChatListViewBody(this.controller, {super.key});

  void _showFolderMenu(BuildContext context, ChatFolder folder) {
    showModalActionPopup(
      context: context,
      title: folder.name,
      actions: [
        AdaptiveModalAction(value: 'edit', label: 'Edit'),
        AdaptiveModalAction(value: 'delete', label: 'Delete'),
      ],
    ).then((action) {
      if (action == 'edit') {
        controller.editFolder(folder);
      } else if (action == 'delete') {
        controller.deleteFolder(folder.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final client = Matrix.of(context).client;
    final activeSpace = controller.activeSpaceId;
    if (activeSpace != null) {
      return SpaceView(
        key: ValueKey(activeSpace),
        spaceId: activeSpace,
        onBack: controller.clearActiveSpace,
        onChatTab: (room) => controller.onChatTap(room),
        activeChat: controller.activeChat,
      );
    }
    final spaces = client.rooms.where((r) => r.isSpace);
    final spaceDelegateCandidates = <String, Room>{};
    for (final space in spaces) {
      for (final spaceChild in space.spaceChildren) {
        final roomId = spaceChild.roomId;
        if (roomId == null) continue;
        spaceDelegateCandidates[roomId] = space;
      }
    }

    final publicRooms = controller.roomSearchResult?.chunk
        .where((room) => room.roomType != 'm.space')
        .toList();
    final publicSpaces = controller.roomSearchResult?.chunk
        .where((room) => room.roomType == 'm.space')
        .toList();
    final userSearchResult = controller.userSearchResult;
    final allowedDomains = <String>{
      _normalizeHomeserverDomain(_defaultHomeserverHost()),
      _normalizeHomeserverDomain(AppConfig.forcedHomeserverHost),
      _normalizeHomeserverDomain(client.userID?.domain),
    }..removeWhere((domain) => domain.isEmpty);
    final filteredUserResults =
        userSearchResult?.results
            .where(
              (profile) => allowedDomains.contains(
                _normalizeHomeserverDomain(profile.userId.domain),
              ),
            )
            .toList() ??
        <Profile>[];
    final searchQuery = controller.searchController.text.trim();
    if (searchQuery.isValidMatrixId && searchQuery.sigil == '@') {
      final queryDomain = _normalizeHomeserverDomain(
        _domainFromMatrixId(searchQuery),
      );
      if (allowedDomains.contains(queryDomain) &&
          filteredUserResults.every(
            (profile) => profile.userId != searchQuery,
          )) {
        filteredUserResults.add(Profile(userId: searchQuery));
      }
    }
    const dummyChatCount = 4;
    final filter = controller.searchController.text.toLowerCase();
    return StreamBuilder(
      key: ValueKey(client.userID.toString()),
      stream: client.onSync.stream
          .where((s) => s.hasRoomUpdate)
          .rateLimit(const Duration(seconds: 1)),
      builder: (context, _) {
        final rooms = controller.filteredRooms;

        return SafeArea(
          child: CustomScrollView(
            controller: controller.scrollController,
            slivers: [
              ChatListHeader(controller: controller),
              SliverList(
                delegate: SliverChildListDelegate([
                  if (controller.isSearchMode) ...[
                    SearchTitle(
                      title: L10n.of(context).publicRooms,
                      icon: const Icon(Icons.explore_outlined),
                    ),
                    PublicRoomsHorizontalList(publicRooms: publicRooms),
                    SearchTitle(
                      title: L10n.of(context).publicSpaces,
                      icon: const Icon(Icons.workspaces_outlined),
                    ),
                    PublicRoomsHorizontalList(publicRooms: publicSpaces),
                    SearchTitle(
                      title: L10n.of(context).users,
                      icon: const Icon(Icons.group_outlined),
                    ),
                    AnimatedContainer(
                      clipBehavior: Clip.hardEdge,
                      decoration: const BoxDecoration(),
                      height: filteredUserResults.isEmpty ? 0 : 106,
                      duration: FluffyThemes.animationDuration,
                      curve: FluffyThemes.animationCurve,
                      child: filteredUserResults.isEmpty
                          ? null
                          : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: filteredUserResults.length,
                              itemBuilder: (context, i) => _SearchItem(
                                title:
                                    filteredUserResults[i].displayName ??
                                    filteredUserResults[i].userId.localpart ??
                                    L10n.of(context).unknownDevice,
                                avatar: filteredUserResults[i].avatarUrl,
                                onPressed: () => UserDialog.show(
                                  context: context,
                                  profile: filteredUserResults[i],
                                ),
                              ),
                            ),
                    ),
                  ],
                  if (!controller.isSearchMode &&
                      AppSettings.showPresences.value)
                    GestureDetector(
                      onLongPress: () => controller.dismissStatusList(),
                      child: StatusMessageList(
                        onStatusEdit: controller.setStatus,
                      ),
                    ),
                  if (client.rooms.isNotEmpty && !controller.isSearchMode)
                    SizedBox(
                      height: 56,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ...[
                              if (AppSettings.separateChatTypes.value)
                                BuiltInFilter(ActiveFilter.messages)
                              else
                                BuiltInFilter(ActiveFilter.allChats),
                              BuiltInFilter(ActiveFilter.groups),
                              BuiltInFilter(ActiveFilter.calls),
                              BuiltInFilter(ActiveFilter.unread),
                              if (spaceDelegateCandidates.isNotEmpty &&
                                  !AppSettings.displayNavigationRail.value &&
                                  !FluffyThemes.isColumnMode(context))
                                BuiltInFilter(ActiveFilter.spaces),
                            ].map(
                              (filter) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4.0,
                                ),
                                child: FilterChip(
                                  selected: filter == controller.activeFilter,
                                  onSelected: (_) =>
                                      controller.setActiveFilter(filter),
                                  label: Text(
                                    filter.toLocalizedString(context),
                                  ),
                                ),
                              ),
                            ),
                            ReorderableListView(
                              scrollDirection: Axis.horizontal,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              onReorder: controller.reorderFolders,
                              children: controller.folders
                                  .map(
                                    (folder) => Padding(
                                      key: ValueKey(folder.id),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4.0,
                                      ),
                                      child: GestureDetector(
                                        onLongPress: () =>
                                            _showFolderMenu(context, folder),
                                        child: FilterChip(
                                          selected:
                                              FolderFilterItem(folder) ==
                                              controller.activeFilter,
                                          onSelected: (_) =>
                                              controller.setActiveFilter(
                                                FolderFilterItem(folder),
                                              ),
                                          label: Text(folder.name),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (controller.isSearchMode)
                    SearchTitle(
                      title: L10n.of(context).chats,
                      icon: const Icon(Icons.forum_outlined),
                    ),
                  if (client.prevBatch != null &&
                      rooms.isEmpty &&
                      !controller.isSearchMode) ...[
                    Column(
                      mainAxisAlignment: .center,
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            const Column(
                              mainAxisSize: .min,
                              children: [
                                DummyChatListItem(opacity: 0.5, animate: false),
                                DummyChatListItem(opacity: 0.3, animate: false),
                              ],
                            ),
                            Icon(
                              CupertinoIcons.chat_bubble_text_fill,
                              size: 128,
                              color: theme.colorScheme.secondary,
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            client.rooms.isEmpty
                                ? L10n.of(context).noChatsFoundHere
                                : L10n.of(context).noMoreChatsFound,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ]),
              ),
              if (client.prevBatch == null)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => DummyChatListItem(
                      opacity: (dummyChatCount - i) / dummyChatCount,
                      animate: true,
                    ),
                    childCount: dummyChatCount,
                  ),
                ),
              if (client.prevBatch != null)
                SliverList.builder(
                  itemCount: rooms.length,
                  itemBuilder: (BuildContext context, int i) {
                    final room = rooms[i];
                    final space = spaceDelegateCandidates[room.id];
                    return ChatListItem(
                      room,
                      space: space,
                      key: Key('chat_list_item_${room.id}'),
                      filter: filter,
                      onTap: () => controller.onChatTap(room),
                      onLongPress: (context) =>
                          controller.chatContextAction(room, context, space),
                      activeChat: controller.activeChat == room.id,
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

class PublicRoomsHorizontalList extends StatelessWidget {
  const PublicRoomsHorizontalList({super.key, required this.publicRooms});

  final List<PublishedRoomsChunk>? publicRooms;

  @override
  Widget build(BuildContext context) {
    final publicRooms = this.publicRooms;
    return AnimatedContainer(
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(),
      height: publicRooms == null || publicRooms.isEmpty ? 0 : 106,
      duration: FluffyThemes.animationDuration,
      curve: FluffyThemes.animationCurve,
      child: publicRooms == null
          ? null
          : ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: publicRooms.length,
              itemBuilder: (context, i) => _SearchItem(
                title:
                    publicRooms[i].name ??
                    publicRooms[i].canonicalAlias?.localpart ??
                    L10n.of(context).group,
                avatar: publicRooms[i].avatarUrl,
                onPressed: () => showAdaptiveDialog(
                  context: context,
                  builder: (c) => PublicRoomDialog(
                    roomAlias:
                        publicRooms[i].canonicalAlias ?? publicRooms[i].roomId,
                    chunk: publicRooms[i],
                  ),
                ),
              ),
            ),
    );
  }
}

class _SearchItem extends StatelessWidget {
  final String title;
  final Uri? avatar;
  final void Function() onPressed;

  const _SearchItem({
    required this.title,
    this.avatar,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onPressed,
    child: SizedBox(
      width: 84,
      child: Column(
        mainAxisSize: .min,
        children: [
          const SizedBox(height: 8),
          Avatar(mxContent: avatar, name: title),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              title,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    ),
  );
}
