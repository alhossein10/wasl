import 'package:flutter/material.dart';

import 'package:fluffychat/widgets/adaptive_dialogs/show_ok_cancel_alert_dialog.dart';
import 'package:fluffychat/widgets/adaptive_dialogs/show_text_input_dialog.dart';

import '../../utils/chat_folder.dart';
import '../../utils/folders_manager.dart';
import 'settings_folders_view.dart';

class SettingsFolders extends StatefulWidget {
  const SettingsFolders({super.key});

  @override
  SettingsFoldersController createState() => SettingsFoldersController();
}

class SettingsFoldersController extends State<SettingsFolders> {
  List<ChatFolder> folders = [];

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  void _loadFolders() async {
    folders = await FoldersManager.getFolders();
    if (mounted) setState(() {});
  }

  void reorderFolders(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final folder = folders.removeAt(oldIndex);
    folders.insert(newIndex, folder);
    await FoldersManager.saveFolders(folders);
    setState(() {});
  }

  void editFolder(ChatFolder folder) async {
    final newName = await showTextInputDialog(
      context: context,
      title: 'Edit Folder',
      hintText: 'Name',
      initialText: folder.name,
      okLabel: 'Save',
      cancelLabel: 'Cancel',
    );
    if (newName != null && newName.isNotEmpty && newName != folder.name) {
      final updatedFolder = ChatFolder(
        id: folder.id,
        name: newName,
        roomIds: folder.roomIds,
      );
      await FoldersManager.updateFolder(updatedFolder);
      _loadFolders();
    }
  }

  void deleteFolder(String id) async {
    final confirmed = await showOkCancelAlertDialog(
      context: context,
      title: 'Delete Folder',
      message: 'Are you sure you want to delete this folder?',
      okLabel: 'Delete',
      cancelLabel: 'Cancel',
      isDestructive: true,
    );
    if (confirmed == OkCancelResult.ok) {
      await FoldersManager.deleteFolder(id);
      _loadFolders();
    }
  }

  @override
  Widget build(BuildContext context) => SettingsFoldersView(this);
}
