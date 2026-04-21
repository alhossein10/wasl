import 'package:matrix/matrix.dart';

/// Stores room IDs the user hid from the main list under client account data
/// ([`PUT /_matrix/client/v3/user/{userId}/account_data/{type}`](https://spec.matrix.org/latest/client-server-api/#put_matrixclientv3useruseridaccount_datatype)).
/// Any custom type key is allowed; content must be a JSON object.
const String archivedChatsAccountDataType = 'im.wasl.archived_chats';

extension ArchivedChatsExtension on Client {
  Set<String> get archivedChatRoomIds {
    final raw = accountData[archivedChatsAccountDataType]?.content['room_ids'];
    if (raw is! List) return {};
    return raw.map((e) => e.toString()).toSet();
  }

  Future<void> setArchivedChatRoomIds(Set<String> ids) async {
    final uid = userID;
    if (uid == null) return;
    await setAccountData(uid, archivedChatsAccountDataType, {
      'room_ids': ids.toList(),
    });
  }

  Future<void> archiveChatRoom(String roomId) async {
    final next = archivedChatRoomIds..add(roomId);
    await setArchivedChatRoomIds(next);
  }

  Future<void> unarchiveChatRoom(String roomId) async {
    final next = archivedChatRoomIds..remove(roomId);
    await setArchivedChatRoomIds(next);
  }

  /// Drops IDs that are no longer known to this client (e.g. forgotten rooms).
  Future<void> pruneArchivedChatRoomIds() async {
    final known = rooms.map((r) => r.id).toSet();
    final next = archivedChatRoomIds.where(known.contains).toSet();
    if (next.length == archivedChatRoomIds.length) return;
    await setArchivedChatRoomIds(next);
  }
}
