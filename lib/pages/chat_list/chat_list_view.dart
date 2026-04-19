import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

import 'package:fluffychat/config/setting_keys.dart';
import 'package:fluffychat/config/themes.dart';
import 'package:fluffychat/l10n/l10n.dart';
import 'package:fluffychat/pages/chat_list/chat_list.dart';
import 'package:fluffychat/widgets/navigation_rail.dart';
import 'chat_list_body.dart';

class ChatListView extends StatelessWidget {
  final ChatListController controller;

  const ChatListView(this.controller, {super.key});

  void _onBottomNavigationTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        if (controller.activeSpaceId != null) {
          controller.clearActiveSpace();
        }
        if (controller.isSearchMode) {
          controller.cancelSearch();
        }
        final route = GoRouterState.of(context).uri.path;
        if (route != '/rooms') {
          context.go('/rooms');
        }
        break;
      case 1:
        context.go('/rooms/newprivatechat');
        break;
      case 2:
        context.go('/rooms/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isColumnMode = FluffyThemes.isColumnMode(context);
    final showRail = isColumnMode || AppSettings.displayNavigationRail.value;
    final showBottomNav = !showRail;
    final contactsLabel =
        Localizations.localeOf(
          context,
        ).languageCode.toLowerCase().startsWith('ar')
        ? 'جهات الاتصال'
        : 'Contacts';

    return PopScope(
      canPop: !controller.isSearchMode && controller.activeSpaceId == null,
      onPopInvokedWithResult: (pop, _) {
        if (pop) return;
        if (controller.activeSpaceId != null) {
          controller.clearActiveSpace();
          return;
        }
        if (controller.isSearchMode) {
          controller.cancelSearch();
          return;
        }
      },
      child: Row(
        children: [
          if (showRail) ...[
            SpacesNavigationRail(
              activeSpaceId: controller.activeSpaceId,
              onGoToChats: controller.clearActiveSpace,
              onGoToSpaceId: controller.setActiveSpace,
            ),
            Container(color: Theme.of(context).dividerColor, width: 1),
          ],
          Expanded(
            child: GestureDetector(
              onTap: FocusManager.instance.primaryFocus?.unfocus,
              excludeFromSemantics: true,
              behavior: HitTestBehavior.translucent,
              child: Scaffold(
                body: ChatListViewBody(controller),
                bottomNavigationBar: showBottomNav
                    ? NavigationBar(
                        selectedIndex: 0,
                        height: 68,
                        onDestinationSelected: (index) =>
                            _onBottomNavigationTap(context, index),
                        destinations: [
                          NavigationDestination(
                            icon: const Icon(Icons.chat_bubble_outline_rounded),
                            selectedIcon: const Icon(Icons.chat_bubble_rounded),
                            label: L10n.of(context).chats,
                          ),
                          NavigationDestination(
                            icon: const Icon(Icons.person_outline_rounded),
                            selectedIcon: const Icon(Icons.person_rounded),
                            label: contactsLabel,
                          ),
                          NavigationDestination(
                            icon: const Icon(Icons.settings_outlined),
                            selectedIcon: const Icon(Icons.settings),
                            label: L10n.of(context).settings,
                          ),
                        ],
                      )
                    : null,
                floatingActionButton:
                    !controller.isSearchMode && controller.activeSpaceId == null
                    ? FloatingActionButton(
                        onPressed: () => context.go('/rooms/newprivatechat'),
                        child: const Icon(Icons.edit_outlined),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
