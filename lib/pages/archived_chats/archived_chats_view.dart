import 'package:flutter/material.dart';

import 'package:fluffychat/l10n/l10n.dart';
import 'package:fluffychat/pages/archived_chats/archived_chats.dart';
import 'package:fluffychat/pages/chat_list/chat_list_item.dart';
import 'package:fluffychat/widgets/layouts/max_width_body.dart';
import 'package:fluffychat/widgets/matrix.dart';

import 'package:fluffychat/utils/archived_chats.dart';

class ArchivedChatsView extends StatelessWidget {
  final ArchivedChatsController controller;

  const ArchivedChatsView(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    final client = Matrix.of(context).client;

    return StreamBuilder(
      stream: client.onSync.stream,
      builder: (context, _) {
        final ids = client.archivedChatRoomIds;
        final rooms =
            client.rooms.where((r) => ids.contains(r.id)).toList(growable: false);

        return Scaffold(
          appBar: AppBar(
            leading: const Center(child: BackButton()),
            title: Text(L10n.of(context).archivedChatsTitle),
          ),
          body: MaxWidthBody(
            withScrolling: false,
            child: rooms.isEmpty
                ? Center(
                    child: Icon(
                      Icons.archive_outlined,
                      size: 80,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  )
                : ListView.builder(
                    itemCount: rooms.length,
                    itemBuilder: (context, i) => ChatListItem(
                      rooms[i],
                      key: Key('archived_chat_${rooms[i].id}'),
                      onTap: () => controller.onChatTap(rooms[i]),
                      onLongPress: (ctx) =>
                          controller.chatContextAction(rooms[i], ctx),
                      filter: '',
                    ),
                  ),
          ),
        );
      },
    );
  }
}
