import 'dart:math';

import 'package:matrix/matrix.dart';

const String chatFoldersAccountDataType = 'im.wasl.chat_folders';

class ChatFolder {
  final String id;
  final String name;
  final List<String> roomIds;

  const ChatFolder({
    required this.id,
    required this.name,
    required this.roomIds,
  });

  factory ChatFolder.fromJson(Map<String, dynamic> json) => ChatFolder(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        roomIds:
            (json['room_ids'] is List)
                ? (json['room_ids'] as List).map((e) => e.toString()).toList()
                : const <String>[],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'room_ids': roomIds,
      };
}

extension ChatFoldersAccountData on Client {
  List<ChatFolder> get chatFolders {
    final raw = accountData[chatFoldersAccountDataType]?.content['folders'];
    if (raw is! List) return const <ChatFolder>[];
    return raw
        .whereType<Map>()
        .map((m) => m.cast<String, dynamic>())
        .map(ChatFolder.fromJson)
        .where((f) => f.id.isNotEmpty && f.name.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> setChatFolders(List<ChatFolder> folders) async {
    final uid = userID;
    if (uid == null) return;
    await setAccountData(uid, chatFoldersAccountDataType, {
      'folders': folders.map((f) => f.toJson()).toList(),
    });
  }

  String _newFolderId() {
    // Avoid adding a new dependency for UUIDs.
    final r = Random.secure().nextInt(1 << 32).toRadixString(16);
    return '${DateTime.now().millisecondsSinceEpoch}-$r';
  }

  Future<void> createChatFolder(String name) async {
    final folders = [...chatFolders];
    folders.add(ChatFolder(id: _newFolderId(), name: name, roomIds: const []));
    await setChatFolders(folders);
  }

  Future<void> deleteChatFolder(String folderId) async {
    final folders = chatFolders.where((f) => f.id != folderId).toList();
    await setChatFolders(folders);
  }

  Future<void> renameChatFolder(String folderId, String newName) async {
    final folders = chatFolders
        .map(
          (f) => f.id == folderId
              ? ChatFolder(id: f.id, name: newName, roomIds: f.roomIds)
              : f,
        )
        .toList();
    await setChatFolders(folders);
  }

  Future<void> setFolderRoomMembership({
    required String folderId,
    required String roomId,
    required bool isMember,
  }) async {
    final folders = chatFolders.map((f) {
      if (f.id != folderId) return f;
      final next = [...f.roomIds];
      if (isMember) {
        if (!next.contains(roomId)) next.add(roomId);
      } else {
        next.remove(roomId);
      }
      return ChatFolder(id: f.id, name: f.name, roomIds: next);
    }).toList();
    await setChatFolders(folders);
  }

  Future<void> reorderChatFolders(int oldIndex, int newIndex) async {
    final folders = [...chatFolders];
    if (newIndex > oldIndex) newIndex -= 1;
    final item = folders.removeAt(oldIndex);
    folders.insert(newIndex, item);
    await setChatFolders(folders);
  }
}

