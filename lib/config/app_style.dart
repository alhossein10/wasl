import 'package:fluffychat/config/app_color.dart';
import 'package:fluffychat/config/setting_keys.dart';
import 'package:flutter/material.dart';

class AppStyles {
  static TextStyle dTextStyle = TextStyle(
    color: AppColor.tWhite,
    fontFamily: AppSettings.fontName.value,
  );
  static TextStyle textStyle16 = TextStyle(
    color: AppColor.tWhite,
    fontFamily: AppSettings.fontName.value,
    fontSize: 16,
  );
  static TextStyle textStyle14 = TextStyle(
    color: AppColor.tWhite,
    fontFamily: AppSettings.fontName.value,
    fontSize: 14,
  );
  static TextStyle textStyle18 = TextStyle(
    color: AppColor.tWhite,
    fontFamily: AppSettings.fontName.value,
    fontSize: 18,
  );

  /// Primary filled button (save, login, retry, etc.)
  static ButtonStyle filledButtonStyle = FilledButton.styleFrom(
    backgroundColor: AppColor.pForest1,
    foregroundColor: AppColor.tWhite,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    textStyle: dTextStyle.copyWith(fontWeight: FontWeight.w600),
  );

  /// Destructive filled button (delete).
  static ButtonStyle filledButtonStyleDestructive = FilledButton.styleFrom(
    backgroundColor: AppColor.cRed,
    foregroundColor: AppColor.tWhite,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    textStyle: dTextStyle.copyWith(fontWeight: FontWeight.w600),
  );

  /// Text button (cancel, secondary actions).
  static ButtonStyle textButtonStyle = TextButton.styleFrom(
    foregroundColor: AppColor.tWhite,
    textStyle: dTextStyle,
  );

  /// Outlined button (logout, tertiary actions).
  static ButtonStyle outlinedButtonStyle = OutlinedButton.styleFrom(
    foregroundColor: AppColor.sGoldenWheat1,
    side: const BorderSide(color: AppColor.sGoldenWheat1),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    textStyle: dTextStyle,
  );
}
