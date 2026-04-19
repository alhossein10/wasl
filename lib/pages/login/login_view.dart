import 'package:fluffychat/config/app_color.dart';
import 'package:flutter/material.dart';

import 'package:fluffychat/l10n/l10n.dart';
import 'package:fluffychat/widgets/app_text_field.dart';
import 'package:fluffychat/widgets/layouts/login_scaffold.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'login.dart';

class LoginView extends StatelessWidget {
  final LoginController controller;

  const LoginView(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // final homeserver = controller.widget.client.homeserver
    //     .toString()
    //     .replaceFirst('https://', '');
    // final title = L10n.of(context).logInTo(homeserver);
    // final titleParts = title.split(homeserver);

    return LoginScaffold(
      enforceMobileMode: Matrix.of(
        context,
      ).widget.clients.any((client) => client.isLogged()),
      appBar: AppBar(
        leading: controller.widget.hideBackButton || controller.loading
            ? null
            : const Center(child: BackButton()),
        automaticallyImplyLeading:
            !controller.widget.hideBackButton && !controller.loading,
        titleSpacing: !controller.loading ? 0 : null,
        title: Text(L10n.of(context).login),
      ),
      body: Builder(
        builder: (context) {
          return AutofillGroup(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: <Widget>[
                const SizedBox(height: 8),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: colorScheme.primary.withValues(
                          alpha: 0.14,
                        ),
                        child: Icon(
                          Icons.send_rounded,
                          color: colorScheme.primary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        L10n.of(context).login,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 20),
                      AppTextField(
                        controller: controller.usernameController,
                        label: L10n.of(context).emailOrUsername,
                        hintText: 'username',
                        errorText: controller.usernameError,
                        readOnly: controller.loading,
                        autocorrect: false,
                        autofocus: true,
                        onChanged: controller.checkWellKnownWithCoolDown,
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: controller.loading
                            ? null
                            : [AutofillHints.username],
                        prefixIcon: const Icon(Icons.person_outline_rounded),
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        controller: controller.passwordController,
                        label: L10n.of(context).password,
                        hintText: '******',
                        errorText: controller.passwordError,
                        readOnly: controller.loading,
                        autocorrect: false,
                        autofillHints: controller.loading
                            ? null
                            : [AutofillHints.password],
                        textInputAction: TextInputAction.go,
                        obscureText: !controller.showPassword,
                        onFieldSubmitted: (_) => controller.login(),
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          onPressed: controller.toggleShowPassword,
                          icon: Icon(
                            controller.showPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColor.pForest1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                          ),
                          onPressed: controller.loading
                              ? null
                              : controller.login,
                          child: controller.loading
                              ? const LinearProgressIndicator()
                              : Text(L10n.of(context).login),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: controller.loading
                            ? () {}
                            : controller.passwordForgotten,
                        style: TextButton.styleFrom(
                          foregroundColor: colorScheme.primary,
                        ),
                        child: Text(L10n.of(context).passwordForgotten),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      ),
    );
  }
}
