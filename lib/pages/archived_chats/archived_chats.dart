import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';

import 'package:fluffychat/l10n/l10n.dart';
import 'package:fluffychat/pages/archived_chats/archived_chats_view.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:fluffychat/widgets/future_loading_dialog.dart';
import 'package:fluffychat/widgets/matrix.dart';

import 'package:fluffychat/utils/archived_chats.dart';

/// Chats hidden from the main list via account data ([ArchivedChatsExtension]).
/// Distinct from [/rooms/archive], which lists **left** rooms from the server.
class ArchivedChats extends StatefulWidget {
  const ArchivedChats({super.key});

  @override
  ArchivedChatsController createState() => ArchivedChatsController();
}

class ArchivedChatsController extends State<ArchivedChats> {
  bool _pruned = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _pruneOnce());
  }

  Future<void> _pruneOnce() async {
    if (_pruned || !mounted) return;
    _pruned = true;
    await Matrix.of(context).client.pruneArchivedChatRoomIds();
    if (mounted) setState(() {});
  }

  void onChatTap(Room room) {
    // Push (not go) so system back / AppBar back returns to archived chats.
    context.push('/rooms/${room.id}');
  }

  Future<void> chatContextAction(Room room, BuildContext posContext) async {
    final overlay =
        Overlay.of(posContext).context.findRenderObject() as RenderBox;
    final button = posContext.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(const Offset(0, -65), ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero) + const Offset(-50, 0),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    final displayname = room.getLocalizedDisplayname(
      MatrixLocals(L10n.of(context)),
    );

    final action = await showMenu<_ArchivedMenuAction>(
      context: posContext,
      position: position,
      items: [
        PopupMenuItem(
          value: _ArchivedMenuAction.open,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 12,
            children: [
              Text(
                displayname,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: _ArchivedMenuAction.unarchive,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.unarchive_outlined),
              const SizedBox(width: 12),
              Text(L10n.of(context).unarchiveChat),
            ],
          ),
        ),
      ],
    );
    if (action == null || !mounted) return;
    switch (action) {
      case _ArchivedMenuAction.open:
        onChatTap(room);
        return;
      case _ArchivedMenuAction.unarchive:
        await showFutureLoadingDialog(
          context: context,
          future: () => Matrix.of(context).client.unarchiveChatRoom(room.id),
        );
        if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) => ArchivedChatsView(this);
}

enum _ArchivedMenuAction { open, unarchive }
