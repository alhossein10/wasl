import 'package:flutter/material.dart';

import 'package:matrix/matrix.dart';

import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/l10n/l10n.dart';
import 'package:fluffychat/pages/chat_search/search_footer.dart';
import 'package:fluffychat/utils/date_time_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';

class ChatSearchFilesTab extends StatelessWidget {
  final Room room;
  final List<Event> events;
  final void Function() onStartSearch;
  final bool endReached, isLoading;
  final DateTime? searchedUntil;

  const ChatSearchFilesTab({
    required this.room,
    required this.events,
    required this.onStartSearch,
    required this.endReached,
    required this.isLoading,
    super.key,
    required this.searchedUntil,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SelectionArea(
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        itemCount: events.length + 1,
        itemBuilder: (context, i) {
          if (i == events.length) {
            return SearchFooter(
              searchedUntil: searchedUntil,
              endReached: endReached,
              isLoading: isLoading,
              onStartSearch: onStartSearch,
            );
          }
          final event = events[i];
          final filename =
              event.content.tryGet<String>('filename') ??
              event.content.tryGet<String>('body') ??
              L10n.of(context).unknownEvent('File');
          final filetype = (filename.contains('.')
              ? filename.split('.').last.toUpperCase()
              : event.content
                        .tryGetMap<String, dynamic>('info')
                        ?.tryGet<String>('mimetype')
                        ?.toUpperCase() ??
                    'UNKNOWN');
          final sizeString = event.sizeString;
          final prevEvent = i > 0 ? events[i - 1] : null;
          final sameEnvironment = prevEvent == null
              ? false
              : prevEvent.originServerTs.sameEnvironment(event.originServerTs);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!sameEnvironment) ...[
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: colorScheme.outlineVariant.withValues(
                                alpha: 0.4,
                              ),
                            ),
                          ),
                          child: Text(
                            event.originServerTs.localizedTime(context),
                            style: theme.textTheme.labelSmall,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                Material(
                  borderRadius: BorderRadius.circular(
                    AppConfig.borderRadius + 2,
                  ),
                  color: colorScheme.surfaceContainerLow,
                  clipBehavior: Clip.hardEdge,
                  child: ListTile(
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.file_present_outlined,
                        color: colorScheme.onSecondaryContainer,
                      ),
                    ),
                    title: Text(
                      filename,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text('$sizeString  •  $filetype'),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => event.saveFile(context),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
