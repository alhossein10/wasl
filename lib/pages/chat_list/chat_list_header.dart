import 'package:flutter/material.dart';

import 'package:matrix/matrix.dart';

import 'package:fluffychat/config/themes.dart';
import 'package:fluffychat/l10n/l10n.dart';
import 'package:fluffychat/pages/chat_list/chat_list.dart';
import 'package:fluffychat/pages/chat_list/client_chooser_button.dart';
import 'package:fluffychat/utils/sync_status_localization.dart';
import 'package:fluffychat/widgets/app_text_field.dart';
import '../../widgets/matrix.dart';

class ChatListHeader extends StatelessWidget implements PreferredSizeWidget {
  final ChatListController controller;
  final bool globalSearch;

  const ChatListHeader({
    super.key,
    required this.controller,
    this.globalSearch = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final client = Matrix.of(context).client;

    return SliverAppBar(
      floating: true,
      toolbarHeight: 118,
      pinned: FluffyThemes.isColumnMode(context),
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      backgroundColor: colorScheme.surface,
      automaticallyImplyLeading: false,
      titleSpacing: 16,
      title: StreamBuilder(
        stream: client.onSyncStatus.stream,
        builder: (context, snapshot) {
          final status =
              client.onSyncStatus.value ??
              const SyncStatusUpdate(SyncStatus.waitingForResponse);
          final hide =
              client.onSync.value != null &&
              status.status != SyncStatus.error &&
              client.prevBatch != null;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    'Wasl',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const Spacer(),
                  Material(
                    color: colorScheme.surfaceContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: BorderSide(color: colorScheme.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      child: ClientChooserButton(controller),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              AppTextField(
                controller: controller.searchController,
                focusNode: controller.searchFocusNode,
                label: hide
                    ? L10n.of(context).searchChatsRooms
                    : status.calcLocalizedString(context),
                hintText: hide
                    ? L10n.of(context).searchChatsRooms
                    : status.calcLocalizedString(context),
                textInputAction: TextInputAction.search,
                onChanged: (text) =>
                    controller.onSearchEnter(text, globalSearch: globalSearch),
                prefixIcon: hide
                    ? controller.isSearchMode
                          ? IconButton(
                              tooltip: L10n.of(context).cancel,
                              icon: const Icon(Icons.close_outlined),
                              onPressed: controller.cancelSearch,
                              color: colorScheme.onSurfaceVariant,
                            )
                          : IconButton(
                              onPressed: controller.startSearch,
                              icon: Icon(
                                Icons.search_outlined,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            )
                    : Container(
                        margin: const EdgeInsets.all(12),
                        width: 8,
                        height: 8,
                        child: Center(
                          child: CircularProgressIndicator.adaptive(
                            strokeWidth: 2,
                            value: status.progress,
                            valueColor: status.error != null
                                ? const AlwaysStoppedAnimation<Color>(
                                    Colors.orange,
                                  )
                                : null,
                          ),
                        ),
                      ),
                suffixIcon: controller.isSearchMode && globalSearch
                    ? controller.isSearching
                          ? const Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: 10.0,
                                horizontal: 12,
                              ),
                              child: SizedBox.square(
                                dimension: 24,
                                child: CircularProgressIndicator.adaptive(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : null
                    /*  
                          TextButton.icon(
                              onPressed: controller.setServer,
                              style: TextButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                textStyle: const TextStyle(fontSize: 12),
                              ),
                              icon: const Icon(Icons.edit_outlined, size: 16),
                              label: Text(
                                controller.searchServer ??
                                    Matrix.of(context).client.homeserver!.host,
                                maxLines: 2,
                              ),
                            )
                  */
                    : const SizedBox.shrink(),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56);
}
