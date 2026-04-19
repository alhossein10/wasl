import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:matrix/matrix.dart';

import 'package:fluffychat/l10n/l10n.dart';
import 'package:fluffychat/pages/new_private_chat/new_private_chat_view.dart';
import 'package:fluffychat/pages/new_private_chat/qr_scanner_modal.dart';
import 'package:fluffychat/utils/adaptive_bottom_sheet.dart';
import 'package:fluffychat/utils/fluffy_share.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/url_launcher.dart';
import 'package:fluffychat/widgets/matrix.dart';
import '../../widgets/adaptive_dialogs/user_dialog.dart';

class NewPrivateChat extends StatefulWidget {
  const NewPrivateChat({super.key});

  @override
  NewPrivateChatController createState() => NewPrivateChatController();
}

class NewPrivateChatController extends State<NewPrivateChat> {
  final TextEditingController controller = TextEditingController();
  final FocusNode textFieldFocus = FocusNode();

  Future<List<Profile>>? searchResponse;

  Timer? _searchCoolDown;

  static const Duration _coolDown = Duration(milliseconds: 500);

  void searchUsers([String? input]) async {
    final searchTerm = input ?? controller.text;
    if (searchTerm.isEmpty) {
      _searchCoolDown?.cancel();
      setState(() {
        searchResponse = _searchCoolDown = null;
      });
      return;
    }

    _searchCoolDown?.cancel();
    _searchCoolDown = Timer(_coolDown, () {
      setState(() {
        searchResponse = _searchUser(searchTerm);
      });
    });
  }

  Future<List<Profile>> _searchUser(String searchTerm) async {
    final client = Matrix.of(context).client;
    final result = await client.searchUserDirectory(searchTerm);
    final myDomain = client.userID?.domain;
    // Only show users from the same homeserver as the current user
    final profiles = myDomain == null
        ? result.results
        : result.results.where((p) => p.userId.domain == myDomain).toList();

    if (searchTerm.isValidMatrixId &&
        searchTerm.sigil == '@' &&
        !profiles.any((profile) => profile.userId == searchTerm)) {
      final termDomain = searchTerm.isValidMatrixId
          ? _domainFromMatrixId(searchTerm)
          : null;
      if (termDomain == null || termDomain == myDomain) {
        profiles.add(Profile(userId: searchTerm));
      }
    }

    return profiles;
  }

  static String? _domainFromMatrixId(String matrixId) {
    final idx = matrixId.indexOf(':');
    return idx > 0 ? matrixId.substring(idx + 1) : null;
  }

  void inviteAction() => FluffyShare.shareInviteLink(context);

  void openScannerAction() async {
    if (PlatformInfos.isAndroid) {
      final info = await DeviceInfoPlugin().androidInfo;
      if (info.version.sdkInt < 21) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(L10n.of(context).unsupportedAndroidVersionLong),
          ),
        );
        return;
      }
    }
    await showAdaptiveBottomSheet(
      context: context,
      builder: (_) => QrScannerModal(
        onScan: (link) => UrlLauncher(context, link).openMatrixToUrl(),
      ),
    );
  }

  void copyUserId() async {
    await Clipboard.setData(
      ClipboardData(text: Matrix.of(context).client.userID!),
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(L10n.of(context).copiedToClipboard)));
  }

  void openUserModal(Profile profile) =>
      UserDialog.show(context: context, profile: profile);

  @override
  Widget build(BuildContext context) => NewPrivateChatView(this);
}
