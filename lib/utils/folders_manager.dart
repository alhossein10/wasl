import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'chat_folder.dart';

class FoldersManager {
  static const String _foldersKey = 'chat.fluffy.folders';

  static final StreamController<List<ChatFolder>> _foldersController =
      StreamController<List<ChatFolder>>.broadcast();

  static Stream<List<ChatFolder>> get foldersStream =>
      _foldersController.stream;

  static Future<List<ChatFolder>> getFolders() async {
    final prefs = await SharedPreferences.getInstance();
    final foldersJson = prefs.getString(_foldersKey);
    if (foldersJson == null) return [];

    try {
      final foldersList = jsonDecode(foldersJson) as List<dynamic>;
      return foldersList.map((json) => ChatFolder.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveFolders(List<ChatFolder> folders) async {
    final prefs = await SharedPreferences.getInstance();
    final foldersJson = jsonEncode(folders.map((f) => f.toJson()).toList());
    await prefs.setString(_foldersKey, foldersJson);
    _foldersController.add(folders);
  }

  static Future<ChatFolder?> getFolder(String id) async {
    final folders = await getFolders();
    return folders.where((f) => f.id == id).firstOrNull;
  }

  static Future<void> addFolder(ChatFolder folder) async {
    final folders = await getFolders();
    folders.add(folder);
    await saveFolders(folders);
  }

  static Future<void> updateFolder(ChatFolder folder) async {
    final folders = await getFolders();
    final index = folders.indexWhere((f) => f.id == folder.id);
    if (index != -1) {
      folders[index] = folder;
      await saveFolders(folders);
    }
  }

  static Future<void> deleteFolder(String id) async {
    final folders = await getFolders();
    folders.removeWhere((f) => f.id == id);
    await saveFolders(folders);
  }

  static Future<void> addRoomToFolder(String folderId, String roomId) async {
    final folder = await getFolder(folderId);
    if (folder != null && !folder.roomIds.contains(roomId)) {
      final updatedFolder = folder.copyWith(
        roomIds: [...folder.roomIds, roomId],
      );
      await updateFolder(updatedFolder);
    }
  }

  static Future<void> removeRoomFromFolder(
    String folderId,
    String roomId,
  ) async {
    final folder = await getFolder(folderId);
    if (folder != null) {
      final updatedRoomIds = folder.roomIds
          .where((id) => id != roomId)
          .toList();
      final updatedFolder = folder.copyWith(roomIds: updatedRoomIds);
      await updateFolder(updatedFolder);
    }
  }
}
