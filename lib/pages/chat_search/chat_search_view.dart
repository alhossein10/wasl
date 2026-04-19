import 'package:flutter/material.dart';

import 'package:fluffychat/config/themes.dart';
import 'package:fluffychat/l10n/l10n.dart';
import 'package:fluffychat/pages/chat_search/chat_search_files_tab.dart';
import 'package:fluffychat/pages/chat_search/chat_search_images_tab.dart';
import 'package:fluffychat/pages/chat_search/chat_search_message_tab.dart';
import 'package:fluffychat/pages/chat_search/chat_search_page.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:fluffychat/widgets/layouts/max_width_body.dart';

class ChatSearchView extends StatelessWidget {
  final ChatSearchController controller;

  const ChatSearchView(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    final room = controller.room;
    if (room == null) {
      return Scaffold(
        appBar: AppBar(title: Text(L10n.of(context).oopsSomethingWentWrong)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(L10n.of(context).youAreNoLongerParticipatingInThisChat),
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: const Center(child: BackButton()),
        titleSpacing: 0,
        title: Text(
          L10n.of(context).searchIn(
            room.getLocalizedDisplayname(MatrixLocals(L10n.of(context))),
          ),
        ),
      ),
      body: MaxWidthBody(
        withScrolling: false,
        child: Column(
          children: [
            SizedBox(height: FluffyThemes.isThreeColumnMode(context) ? 16 : 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.45),
                  ),
                ),
                child: TextField(
                  controller: controller.searchController,
                  onSubmitted: (_) => controller.restartSearch(),
                  autofocus: true,
                  enabled: controller.tabController.index == 0,
                  decoration: InputDecoration(
                    hintText: L10n.of(context).search,
                    prefixIcon: const Icon(Icons.search_outlined),
                    filled: true,
                    fillColor: Colors.transparent,
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 14,
                    ),
                    hintStyle: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                child: TabBar(
                  controller: controller.tabController,
                  dividerHeight: 0,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelStyle: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  unselectedLabelStyle: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  tabs: [
                    Tab(child: Text(L10n.of(context).messages)),
                    Tab(child: Text(L10n.of(context).gallery)),
                    Tab(child: Text(L10n.of(context).files)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: TabBarView(
                controller: controller.tabController,
                children: [
                  ChatSearchMessageTab(
                    searchQuery: controller.searchController.text,
                    room: room,
                    onStartSearch: controller.startSearch,
                    events: controller.messages,
                    endReached: controller.messagesEndReached,
                    isLoading: controller.isLoading,
                    searchedUntil: controller.searchedUntil,
                  ),
                  ChatSearchImagesTab(
                    room: room,
                    onStartSearch: controller.startSearch,
                    events: controller.images,
                    endReached: controller.imagesEndReached,
                    isLoading: controller.isLoading,
                    searchedUntil: controller.searchedUntil,
                  ),
                  ChatSearchFilesTab(
                    room: room,
                    onStartSearch: controller.startSearch,
                    events: controller.files,
                    endReached: controller.filesEndReached,
                    isLoading: controller.isLoading,
                    searchedUntil: controller.searchedUntil,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
