import 'chat_folder.dart';

class FolderFilter {
  final ChatFolder folder;

  const FolderFilter(this.folder);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FolderFilter && runtimeType == other.runtimeType && folder.id == other.folder.id;

  @override
  int get hashCode => folder.id.hashCode;

  String toLocalizedString() => folder.name;
}