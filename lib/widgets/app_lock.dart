import 'package:flutter/material.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:matrix/matrix.dart';
import 'package:provider/provider.dart';

import 'package:fluffychat/l10n/l10n.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/adaptive_dialogs/show_ok_cancel_alert_dialog.dart';
import 'package:fluffychat/widgets/adaptive_dialogs/show_text_input_dialog.dart';
import 'package:fluffychat/widgets/lock_screen.dart';

class AppLockWidget extends StatefulWidget {
  const AppLockWidget({
    required this.child,
    required this.pincode,
    required this.clients,
    required this.navigatorKey,
    super.key,
  });

  final List<Client> clients;
  final String? pincode;
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  State<AppLockWidget> createState() => AppLock();
}

class AppLock extends State<AppLockWidget> with WidgetsBindingObserver {
  BuildContext get _dialogContext => widget.navigatorKey.currentContext ?? context;
  static const _pinStorageKey = 'chat.fluffy.app_lock';
  static const _biometricStorageKey = 'chat.fluffy.app_lock_biometric';

  String? _pincode;
  bool _isLocked = false;
  bool _paused = false;
  bool _pinSetupPromptShown = false;

  bool get _hasConfiguredPin =>
      _pincode != null && int.tryParse(_pincode!) != null && _pincode!.length == 4;
  bool get hasConfiguredPin => _hasConfiguredPin;
  bool get isActive =>
      _hasConfiguredPin && !_paused;

  @override
  void initState() {
    _pincode = widget.pincode;
    _isLocked = _hasConfiguredPin;
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback(_checkLoggedIn);
  }

  void _checkLoggedIn(dynamic _) async {
    if (widget.clients.any((client) => client.isLogged())) {
      await maybePromptPinSetup();
      return;
    }

    await _clearLockData();
    setState(() {
      _pinSetupPromptShown = false;
      _isLocked = false;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (isActive &&
        (state == AppLifecycleState.hidden || state == AppLifecycleState.paused) &&
        !_isLocked &&
        isActive) {
      showLockScreen();
    }
  }

  bool get isLocked => _isLocked;

  Future<void> changePincode(String? pincode) async {
    await const FlutterSecureStorage().write(
      key: _pinStorageKey,
      value: pincode,
    );
    _pincode = pincode;
    if (pincode == null) {
      await setBiometricEnabled(false);
    }
    if (mounted) {
      setState(() {
        if (!_hasConfiguredPin) {
          _isLocked = false;
        }
      });
    }
    return;
  }

  Future<void> _clearLockData() async {
    await const FlutterSecureStorage().write(
      key: _pinStorageKey,
      value: null,
    );
    await const FlutterSecureStorage().write(
      key: _biometricStorageKey,
      value: null,
    );
    _pincode = null;
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await const FlutterSecureStorage().write(
      key: _biometricStorageKey,
      value: enabled ? 'true' : 'false',
    );
    if (mounted) setState(() {});
  }

  Future<bool> isBiometricEnabled() async {
    final value = await const FlutterSecureStorage().read(key: _biometricStorageKey);
    return value == 'true';
  }

  Future<bool> isBiometricSupported() async {
    final localAuth = LocalAuthentication();
    return await localAuth.isDeviceSupported() &&
        await localAuth.canCheckBiometrics;
  }

  bool unlock(String pincode) {
    final isCorrect = pincode == _pincode;
    if (isCorrect) {
      setState(() {
        _isLocked = false;
      });
    }
    return isCorrect;
  }

  bool unlockWithStoredPin() {
    final pin = _pincode;
    if (pin == null) return false;
    return unlock(pin);
  }

  void showLockScreen() => setState(() {
    _isLocked = true;
  });

  Future<void> onLoginSuccessful() async {
    _pinSetupPromptShown = false;
    await maybePromptPinSetup(force: true);
  }

  Future<void> onLoginStateChanged() async {
    _checkLoggedIn(null);
  }

  Future<void> maybePromptPinSetup({bool force = false}) async {
    if (!mounted || !PlatformInfos.isMobile) return;
    if (_hasConfiguredPin) return;
    if (_pinSetupPromptShown && !force) return;
    if (!widget.clients.any((client) => client.isLogged())) return;

    _pinSetupPromptShown = true;
    final l10n = L10n.of(_dialogContext);
    final pin = await showTextInputDialog(
      useRootNavigator: true,
      context: _dialogContext,
      title: l10n.pleaseChooseAPasscode,
      message: l10n.pinSetupAfterLoginDescription,
      okLabel: l10n.ok,
      cancelLabel: l10n.skipForNow,
      validator: (text) {
        if (text.length == 4 && int.tryParse(text) != null) {
          return null;
        }
        return l10n.pinMustBe4Digits;
      },
      keyboardType: TextInputType.number,
      obscureText: true,
      maxLines: 1,
      minLines: 1,
      maxLength: 4,
    );
    if (pin == null || pin.isEmpty) {
      return;
    }
    await changePincode(pin);

    final localAuth = LocalAuthentication();
    final canUseBiometric =
        await localAuth.isDeviceSupported() && await localAuth.canCheckBiometrics;
    if (!mounted || !canUseBiometric) return;

    final useBiometric = await showOkCancelAlertDialog(
      useRootNavigator: true,
      context: _dialogContext,
      title: l10n.useFingerprintToUnlockTitle,
      message: l10n.useFingerprintToUnlockDescription,
      okLabel: l10n.ok,
      cancelLabel: l10n.cancel,
    );
    await setBiometricEnabled(useBiometric == OkCancelResult.ok);
  }

  Future<T> pauseWhile<T>(Future<T> future) async {
    _paused = true;
    try {
      return await future;
    } finally {
      _paused = false;
    }
  }

  static AppLock of(BuildContext context) =>
      Provider.of<AppLock>(context, listen: false);

  @override
  Widget build(BuildContext context) => Provider<AppLock>(
    create: (_) => this,
    child: Stack(
      fit: StackFit.expand,
      children: [widget.child, if (isLocked) const LockScreen()],
    ),
  );
}
