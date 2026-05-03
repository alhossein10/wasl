import 'package:flutter/material.dart';

import 'package:fluffychat/widgets/adaptive_dialogs/show_modal_action_popup.dart';

import '../../utils/chat_folder.dart';
import 'settings_folders.dart';

class SettingsFoldersView extends StatelessWidget {
  final SettingsFoldersController controller;

  const SettingsFoldersView(this.controller, {super.key});

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
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Folders')),
      body: controller.folders.isEmpty
          ? const Center(
              child: Text('No folders yet. Create some from the home screen.'),
            )
          : ReorderableListView(
              onReorder: controller.reorderFolders,
              children: controller.folders.map((folder) {
                return ListTile(
                  key: ValueKey(folder.id),
                  title: Text(folder.name),
                  subtitle: Text('${folder.roomIds.length} chats'),
                  trailing: IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => _showFolderMenu(context, folder),
                  ),
                );
              }).toList(),
            ),
    );
  }
}
