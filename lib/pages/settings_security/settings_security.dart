import 'package:flutter/material.dart';

import 'package:matrix/matrix.dart';

import 'package:fluffychat/config/setting_keys.dart';
import 'package:fluffychat/l10n/l10n.dart';
import 'package:fluffychat/widgets/adaptive_dialogs/show_ok_cancel_alert_dialog.dart';
import 'package:fluffychat/widgets/adaptive_dialogs/show_text_input_dialog.dart';
import 'package:fluffychat/widgets/app_lock.dart';
import 'package:fluffychat/widgets/future_loading_dialog.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'settings_security_view.dart';

class SettingsSecurity extends StatefulWidget {
  const SettingsSecurity({super.key});

  @override
  SettingsSecurityController createState() => SettingsSecurityController();
}

class SettingsSecurityController extends State<SettingsSecurity> {
  bool hasPin = false;
  bool biometricEnabled = false;
  bool biometricSupported = false;

  Future<void> _loadAppLockState() async {
    if (!mounted) return;
    final appLock = AppLock.of(context);
    final enabled = await appLock.isBiometricEnabled();
    final supported = await appLock.isBiometricSupported();
    if (!mounted) return;
    setState(() {
      hasPin = appLock.hasConfiguredPin;
      biometricEnabled = enabled;
      biometricSupported = supported;
    });
  }

  void setAppLockAction() async {
    if (AppLock.of(context).isActive) {
      AppLock.of(context).showLockScreen();
    }
    final newLock = await showTextInputDialog(
      useRootNavigator: false,
      context: context,
      title: L10n.of(context).pleaseChooseAPasscode,
      message: hasPin
          ? L10n.of(context).changePinDescription
          : L10n.of(context).pinSetupAfterLoginDescription,
      cancelLabel: L10n.of(context).cancel,
      validator: (text) {
        if (text.length == 4 && int.tryParse(text) != null) {
          return null;
        }
        return L10n.of(context).pinMustBe4Digits;
      },
      keyboardType: TextInputType.number,
      obscureText: true,
      maxLines: 1,
      minLines: 1,
      maxLength: 4,
    );
    if (newLock != null && newLock.isNotEmpty) {
      await AppLock.of(context).changePincode(newLock);
      await _loadAppLockState();
    }
  }

  Future<void> removePinAction() async {
    final result = await showOkCancelAlertDialog(
      useRootNavigator: false,
      context: context,
      title: L10n.of(context).removePin,
      message: L10n.of(context).removePinWarning,
      okLabel: L10n.of(context).remove,
      cancelLabel: L10n.of(context).cancel,
      isDestructive: true,
    );
    if (result != OkCancelResult.ok) return;
    await AppLock.of(context).changePincode(null);
    await _loadAppLockState();
  }

  Future<void> changeFingerprintAction(bool enabled) async {
    if (!hasPin) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(L10n.of(context).setPinFirst)),
      );
      return;
    }
    if (!biometricSupported) return;
    await AppLock.of(context).setBiometricEnabled(enabled);
    await _loadAppLockState();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAppLockState());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAppLockState());
  }

  void deleteAccountAction() async {
    if (await showOkCancelAlertDialog(
          useRootNavigator: false,
          context: context,
          title: L10n.of(context).warning,
          message:
              '${L10n.of(context).deactivateAccountWarning}\n\n${L10n.of(context).pinRemovedOnLogoutWarning}',
          okLabel: L10n.of(context).ok,
          cancelLabel: L10n.of(context).cancel,
          isDestructive: true,
        ) ==
        OkCancelResult.cancel) {
      return;
    }
    final supposedMxid = Matrix.of(context).client.userID!;
    final mxid = await showTextInputDialog(
      useRootNavigator: false,
      context: context,
      title: L10n.of(context).confirmMatrixId,
      validator: (text) => text == supposedMxid
          ? null
          : L10n.of(context).supposedMxid(supposedMxid),
      isDestructive: true,
      okLabel: L10n.of(context).delete,
      cancelLabel: L10n.of(context).cancel,
    );
    if (mxid == null || mxid.isEmpty || mxid != supposedMxid) {
      return;
    }
    final resp = await showFutureLoadingDialog(
      context: context,
      delay: false,
      future: () =>
          Matrix.of(context).client.uiaRequestBackground<IdServerUnbindResult?>(
            (auth) => Matrix.of(context).client.deactivateAccount(auth: auth),
          ),
    );

    if (!resp.isError) {
      await showFutureLoadingDialog(
        context: context,
        future: () => Matrix.of(context).client.logout(),
      );
    }
  }

  Future<void> dehydrateAction() => Matrix.of(context).dehydrateAction(context);

  void changeShareKeysWith(ShareKeysWith? shareKeysWith) async {
    if (shareKeysWith == null) return;
    AppSettings.shareKeysWith.setItem(shareKeysWith.name);
    Matrix.of(context).client.shareKeysWith = shareKeysWith;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => SettingsSecurityView(this);
}
