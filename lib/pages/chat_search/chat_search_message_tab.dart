import 'package:flutter/material.dart';

import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';

import 'package:fluffychat/l10n/l10n.dart';
import 'package:fluffychat/pages/chat_search/search_footer.dart';
import 'package:fluffychat/utils/date_time_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:fluffychat/utils/url_launcher.dart';
import 'package:fluffychat/widgets/avatar.dart';

class ChatSearchMessageTab extends StatelessWidget {
  final String searchQuery;
  final Room room;
  final List<Event> events;
  final void Function() onStartSearch;
  final bool endReached, isLoading;
  final DateTime? searchedUntil;

  const ChatSearchMessageTab({
    required this.searchQuery,
    required this.room,
    required this.onStartSearch,
    required this.events,
    required this.searchedUntil,
    required this.endReached,
    required this.isLoading,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    if (events.isEmpty && searchQuery.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_outlined,
            size: 54,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              L10n.of(context).searchIn(
                room.getLocalizedDisplayname(MatrixLocals(L10n.of(context))),
              ),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
          ),
        ],
      );
    }

    return SelectionArea(
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        itemCount: events.length + 1,
        separatorBuilder: (context, _) => const SizedBox(height: 6),
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
          final sender = event.senderFromMemoryOrFallback;
          final displayname = sender.calcDisplayname(
            i18n: MatrixLocals(L10n.of(context)),
          );
          return _MessageSearchResultListTile(
            sender: sender,
            displayname: displayname,
            event: event,
            room: room,
          );
        },
      ),
    );
  }
}

class _MessageSearchResultListTile extends StatelessWidget {
  const _MessageSearchResultListTile({
    required this.sender,
    required this.displayname,
    required this.event,
    required this.room,
  });

  final User sender;
  final String displayname;
  final Event event;
  final Room room;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final messageBody = event
        .calcLocalizedBodyFallback(
          plaintextBody: true,
          removeMarkdown: true,
          MatrixLocals(L10n.of(context)),
        )
        .trim();

    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () => context.go(
          '/${Uri(pathSegments: ['rooms', room.id], queryParameters: {'event': event.eventId})}',
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Avatar(mxContent: sender.avatarUrl, name: displayname, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            displayname,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            event.originServerTs.localizedTimeShort(context),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSecondaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Linkify(
                      textScaleFactor: MediaQuery.textScalerOf(
                        context,
                      ).scale(1),
                      options: const LinkifyOptions(humanize: false),
                      linkStyle: TextStyle(
                        color: colorScheme.primary,
                        decoration: TextDecoration.underline,
                        decorationColor: colorScheme.primary,
                      ),
                      onOpen: (url) =>
                          UrlLauncher(context, url.url).launchUrl(),
                      text: messageBody,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.35,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.surface,
                ),
                onPressed: () => context.go(
                  '/${Uri(pathSegments: ['rooms', room.id], queryParameters: {'event': event.eventId})}',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
