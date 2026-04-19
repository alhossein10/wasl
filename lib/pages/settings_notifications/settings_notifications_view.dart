import 'package:flutter/material.dart';

import 'package:matrix/matrix.dart';

import 'package:fluffychat/config/themes.dart';
import 'package:fluffychat/l10n/l10n.dart';
import 'package:fluffychat/pages/settings_notifications/push_rule_extensions.dart';
import 'package:fluffychat/widgets/layouts/max_width_body.dart';
import '../../utils/localized_exception_extension.dart';
import '../../widgets/matrix.dart';
import 'settings_notifications.dart';

class SettingsNotificationsView extends StatelessWidget {
  final SettingsNotificationsController controller;

  const SettingsNotificationsView(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    final pushRules = Matrix.of(context).client.globalPushRules;

    /// Exclude Poll response from the list of rules shown in the UI.
    bool isPollResponseRule(PushRule r) => r.ruleId.contains('poll_response');

    /// Exclude Jitsi and Poll start/end (and one-to-one variants) from underride.
    bool isHiddenUnderrideRule(PushRule r) {
      final id = r.ruleId.toLowerCase();
      return id.contains('jitsi') ||
          id.contains('poll_start') ||
          id.contains('poll_end');
    }

    final overrideRules =
        pushRules?.override?.where((r) => !isPollResponseRule(r)).toList() ??
        <PushRule>[];

    final underrideRules =
        pushRules?.underride
            ?.where((r) => !isHiddenUnderrideRule(r))
            .toList() ??
        <PushRule>[];

    final pushCategories = [
      if (overrideRules.isNotEmpty)
        (rules: overrideRules, kind: PushRuleKind.override),
      if (pushRules?.content?.isNotEmpty ?? false)
        (rules: pushRules?.content ?? [], kind: PushRuleKind.content),
      // if (pushRules?.sender?.isNotEmpty ?? false)
      //   (rules: pushRules?.sender ?? [], kind: PushRuleKind.sender),
      if (underrideRules.isNotEmpty)
        (rules: underrideRules, kind: PushRuleKind.underride),
    ];
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !FluffyThemes.isColumnMode(context),
        centerTitle: FluffyThemes.isColumnMode(context),
        title: Text(L10n.of(context).notifications),
      ),
      body: MaxWidthBody(
        child: StreamBuilder(
          stream: Matrix.of(context).client.onSync.stream.where(
            (syncUpdate) =>
                syncUpdate.accountData?.any(
                  (accountData) => accountData.type == 'm.push_rules',
                ) ??
                false,
          ),
          builder: (BuildContext context, _) {
            final theme = Theme.of(context);
            return SelectionArea(
              child: Column(
                children: [
                  if (pushRules != null)
                    for (final category in pushCategories) ...[
                      ListTile(
                        title: Text(
                          category.kind.localized(L10n.of(context)),
                          style: TextStyle(
                            color: theme.colorScheme.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      for (final rule in category.rules)
                        ListTile(
                          title: Text(rule.getPushRuleName(L10n.of(context))),
                          subtitle: Text(
                            rule.getPushRuleDescription(L10n.of(context)),
                          ),
                          trailing: Switch.adaptive(
                            value: rule.enabled,
                            onChanged: controller.isLoading
                                ? null
                                : rule.ruleId != '.m.rule.master' &&
                                      Matrix.of(
                                        context,
                                      ).client.allPushNotificationsMuted
                                ? null
                                : (_) => controller.togglePushRule(
                                    category.kind,
                                    rule,
                                  ),
                          ),
                        ),
                      Divider(color: theme.dividerColor),
                    ],
                  ListTile(
                    title: Text(
                      L10n.of(context).devices,
                      style: TextStyle(
                        color: theme.colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  FutureBuilder<List<Pusher>?>(
                    future: controller.pusherFuture ??= Matrix.of(
                      context,
                    ).client.getPushers(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        Center(
                          child: Text(
                            snapshot.error!.toLocalizedString(context),
                          ),
                        );
                      }
                      if (snapshot.connectionState != ConnectionState.done) {
                        const Center(
                          child: CircularProgressIndicator.adaptive(
                            strokeWidth: 2,
                          ),
                        );
                      }
                      final pushers = snapshot.data ?? [];
                      if (pushers.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Text(L10n.of(context).noOtherDevicesFound),
                          ),
                        );
                      }
                      return ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: pushers.length,
                        itemBuilder: (_, i) => ListTile(
                          title: Text(
                            '${pushers[i].appDisplayName} - ${pushers[i].appId}',
                          ),
                          subtitle: Text(pushers[i].data.url.toString()),
                          onTap: () => controller.onPusherTap(pushers[i]),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
