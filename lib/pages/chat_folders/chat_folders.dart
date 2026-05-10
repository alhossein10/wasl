import 'package:flutter/material.dart';

import 'package:fluffychat/l10n/l10n.dart';
import 'package:fluffychat/utils/chat_folders.dart';
import 'package:fluffychat/widgets/adaptive_dialogs/show_ok_cancel_alert_dialog.dart';
import 'package:fluffychat/widgets/adaptive_dialogs/show_text_input_dialog.dart';
import 'package:fluffychat/widgets/future_loading_dialog.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:matrix/matrix.dart';

class ChatFoldersPage extends StatefulWidget {
  const ChatFoldersPage({super.key});

  @override
  State<ChatFoldersPage> createState() => _ChatFoldersPageState();
}

class _ChatFoldersPageState extends State<ChatFoldersPage> {
  List<ChatFolder>? _folders;

  Client get _client => Matrix.of(context).client;

  List<ChatFolder> get folders => _folders ?? _client.chatFolders;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _folders ??= [..._client.chatFolders];
  }

  Future<void> _persistFolders() async {
    final data = _folders;
    if (data == null) return;
    await _client.setChatFolders(data);
  }

  Future<void> _createFolder() async {
    final l10n = L10n.of(context);
    final name = await showTextInputDialog(
      useRootNavigator: false,
      context: context,
      title: l10n.newFolder,
      okLabel: l10n.ok,
      cancelLabel: l10n.cancel,
    );
    if (name == null || name.trim().isEmpty) return;
    await showFutureLoadingDialog(
      context: context,
      future: () => _client.createChatFolder(name.trim()),
    );
    if (!mounted) return;
    setState(() {
      _folders = [..._client.chatFolders];
    });
  }

  Future<void> _deleteFolder(String folderId) async {
    final l10n = L10n.of(context);
    final confirmed = await showOkCancelAlertDialog(
      useRootNavigator: false,
      context: context,
      title: l10n.areYouSure,
      message: l10n.deleteFolderConfirm,
      okLabel: l10n.delete,
      cancelLabel: l10n.cancel,
      isDestructive: true,
    );
    if (confirmed != OkCancelResult.ok) return;
    await showFutureLoadingDialog(
      context: context,
      future: () => _client.deleteChatFolder(folderId),
    );
    if (!mounted) return;
    setState(() {
      _folders = [..._client.chatFolders];
    });
  }

  Future<void> _renameFolder(ChatFolder folder) async {
    final l10n = L10n.of(context);
    final name = await showTextInputDialog(
      useRootNavigator: false,
      context: context,
      title: l10n.renameFolder,
      okLabel: l10n.ok,
      cancelLabel: l10n.cancel,
      initialText: folder.name,
    );
    if (name == null || name.trim().isEmpty) return;
    await showFutureLoadingDialog(
      context: context,
      future: () => _client.renameChatFolder(folder.id, name.trim()),
    );
    if (!mounted) return;
    setState(() {
      _folders = [..._client.chatFolders];
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final folders = this.folders;

    return Scaffold(
      appBar: AppBar(
        leading: const Center(child: BackButton()),
        title: Text(l10n.folders),
        actions: [
          IconButton(
            tooltip: l10n.newFolder,
            icon: const Icon(Icons.create_new_folder_outlined),
            onPressed: _createFolder,
          ),
        ],
      ),
      body: folders.isEmpty
          ? Center(
              child: TextButton.icon(
                onPressed: _createFolder,
                icon: const Icon(Icons.create_new_folder_outlined),
                label: Text(l10n.newFolder),
              ),
            )
          : ReorderableListView.builder(
              itemCount: folders.length,
              onReorder: (oldIndex, newIndex) async {
                setState(() {
                  final list = [...folders];
                  if (newIndex > oldIndex) newIndex -= 1;
                  final item = list.removeAt(oldIndex);
                  list.insert(newIndex, item);
                  _folders = list;
                });
                // Persist in background; UI updates immediately.
                await _persistFolders();
                if (mounted) setState(() {});
              },
              itemBuilder: (context, index) {
                final folder = folders[index];
                return ListTile(
                  key: ValueKey(folder.id),
                  title: Text(folder.name),
                  subtitle: Text(
                    '${folder.roomIds.length} ${l10n.chats}',
                  ),
                  leading: const Icon(Icons.drag_handle),
                  onTap: () => _renameFolder(folder),
                  trailing: IconButton(
                    tooltip: l10n.delete,
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _deleteFolder(folder.id),
                  ),
                );
              },
            ),
    );
  }
}

