import 'dart:convert';

class ChatFolder {
  final String id;
  final String name;
  final List<String> roomIds;

  ChatFolder({
    required this.id,
    required this.name,
    required this.roomIds,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'roomIds': roomIds,
  };

  factory ChatFolder.fromJson(Map<String, dynamic> json) => ChatFolder(
    id: json['id'] as String,
    name: json['name'] as String,
    roomIds: (json['roomIds'] as List<dynamic>).cast<String>(),
  );

  ChatFolder copyWith({
    String? id,
    String? name,
    List<String>? roomIds,
  }) => ChatFolder(
    id: id ?? this.id,
    name: name ?? this.name,
    roomIds: roomIds ?? this.roomIds,
  );
}