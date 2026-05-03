import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

import 'package:fluffychat/l10n/l10n.dart';

import 'chat_folder.dart';

abstract class FilterItem {
  String toLocalizedString(BuildContext context);
  bool matches(Room room);
}

class BuiltInFilter extends FilterItem {
  final ActiveFilter filter;

  BuiltInFilter(this.filter);

  @override
  String toLocalizedString(BuildContext context) {
    switch (filter) {
      case ActiveFilter.allChats:
        return L10n.of(context).all;
      case ActiveFilter.messages:
        return L10n.of(context).messages;
      case ActiveFilter.groups:
        return L10n.of(context).groups;
      case ActiveFilter.calls:
        return L10n.of(context).calls;
      case ActiveFilter.unread:
        return L10n.of(context).unread;
      case ActiveFilter.spaces:
        return L10n.of(context).spaces;
    }
  }

  @override
  bool matches(Room room) {
    // This will be handled by the controller
    throw UnimplementedError();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BuiltInFilter &&
          runtimeType == other.runtimeType &&
          filter == other.filter;

  @override
  int get hashCode => filter.hashCode;
}

class FolderFilterItem extends FilterItem {
  final ChatFolder folder;

  FolderFilterItem(this.folder);

  @override
  String toLocalizedString(BuildContext context) => folder.name;

  @override
  bool matches(Room room) => folder.roomIds.contains(room.id);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FolderFilterItem &&
          runtimeType == other.runtimeType &&
          folder.id == other.folder.id;

  @override
  int get hashCode => folder.id.hashCode;
}

enum ActiveFilter { allChats, messages, groups, calls, unread, spaces }
