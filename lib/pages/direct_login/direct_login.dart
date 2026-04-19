import 'package:flutter/material.dart';

import 'package:matrix/matrix.dart';

import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/config/setting_keys.dart';
import 'package:fluffychat/l10n/l10n.dart';
import 'package:fluffychat/pages/login/login.dart';
import 'package:fluffychat/utils/localized_exception_extension.dart';
import 'package:fluffychat/widgets/matrix.dart';

/// When not logged in, shows a loading state then the login form for a fixed
/// homeserver. User cannot change the homeserver.
class DirectLoginPage extends StatefulWidget {
  const DirectLoginPage({super.key});

  @override
  State<DirectLoginPage> createState() => _DirectLoginPageState();
}

class _DirectLoginPageState extends State<DirectLoginPage> {
  Client? _client;
  String? _error;
  bool _loading = true;

  Future<void> _prepareClient() async {
    if (!mounted) return;
    setState(() {
      _error = null;
      _loading = true;
    });

    try {
      final client = await Matrix.of(context).getLoginClient();
      final homeserverInput =
          (AppConfig.strictSingleHomeserver
                  ? AppConfig.forcedHomeserverHost
                  : AppSettings.defaultHomeserver.value)
              .trim()
              .toLowerCase()
              .replaceAll(' ', '-');
      var uri = Uri.parse(homeserverInput);
      if (uri.scheme.isEmpty) {
        uri = Uri.https(homeserverInput, '');
      }
      await client.checkHomeserver(uri);
      if (!mounted) return;
      setState(() {
        _client = client;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(
        () => _error = (e).toLocalizedString(
          context,
          ExceptionContext.checkHomeserver,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _prepareClient();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _client == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(L10n.of(context).loadingPleaseWait),
            ],
          ),
        ),
      );
    }

    if (_error != null && _client == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _loading ? null : _prepareClient,
                  child: Text(L10n.of(context).tryAgain),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_client != null) {
      return Login(client: _client!, hideBackButton: true);
    }

    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
