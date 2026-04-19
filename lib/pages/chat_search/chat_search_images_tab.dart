import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import 'package:matrix/matrix.dart';

import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/pages/chat/events/video_player.dart';
import 'package:fluffychat/pages/chat_search/search_footer.dart';
import 'package:fluffychat/pages/image_viewer/image_viewer.dart';
import 'package:fluffychat/widgets/mxc_image.dart';

class ChatSearchImagesTab extends StatelessWidget {
  final Room room;
  final List<Event> events;
  final void Function() onStartSearch;
  final bool endReached, isLoading;
  final DateTime? searchedUntil;

  const ChatSearchImagesTab({
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
    final borderRadius = BorderRadius.circular(AppConfig.borderRadius / 2);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final eventsByMonth = <DateTime, List<Event>>{};
    for (final event in events) {
      final month = DateTime(
        event.originServerTs.year,
        event.originServerTs.month,
      );
      eventsByMonth[month] ??= [];
      eventsByMonth[month]!.add(event);
    }
    final eventsByMonthList = eventsByMonth.entries.toList();

    const padding = 8.0;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      itemCount: eventsByMonth.length + 1,
      itemBuilder: (context, i) {
        if (i == eventsByMonth.length) {
          return SearchFooter(
            searchedUntil: searchedUntil,
            endReached: endReached,
            isLoading: isLoading,
            onStartSearch: onStartSearch,
          );
        }

        final monthEvents = eventsByMonthList[i].value;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 2),
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
                      DateFormat.yMMMM(
                        Localizations.localeOf(context).languageCode,
                      ).format(eventsByMonthList[i].key),
                      style: theme.textTheme.labelSmall,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            GridView.count(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              mainAxisSpacing: padding,
              crossAxisSpacing: padding,
              clipBehavior: Clip.none,
              padding: const EdgeInsets.only(bottom: padding),
              crossAxisCount: 3,
              children: monthEvents.map((event) {
                if (event.messageType == MessageTypes.Video) {
                  return Material(
                    clipBehavior: Clip.hardEdge,
                    borderRadius: borderRadius,
                    child: EventVideoPlayer(event),
                  );
                }
                return InkWell(
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) => ImageViewer(event, outerContext: context),
                  ),
                  borderRadius: borderRadius,
                  child: Material(
                    clipBehavior: Clip.hardEdge,
                    borderRadius: borderRadius,
                    child: MxcImage(
                      event: event,
                      width: 128,
                      height: 128,
                      fit: BoxFit.cover,
                      animated: true,
                      isThumbnail: true,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}
