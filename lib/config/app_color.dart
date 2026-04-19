import 'package:flutter/material.dart';

class AppColor {
  AppColor._();

  // Telegram-like accent colors
  static const Color telegramBlue = Color(0xff3390ec);
  static const Color telegramBlueDeep = Color(0xff2a7bd0);
  static const Color telegramBlueSoft = Color(0xff5ea9f3);

  // Neutral light surfaces
  static const Color surfaceLight = Color(0xfff4f6f9);
  static const Color surfaceLightRaised = Color(0xffffffff);
  static const Color surfaceLightBorder = Color(0xffdbe2ea);
  static const Color inkLight = Color(0xff10161f);
  static const Color inkLightMuted = Color(0xff637387);

  // Neutral dark surfaces
  static const Color surfaceDark = Color(0xff0f141a);
  static const Color surfaceDarkRaised = Color(0xff17212b);
  static const Color surfaceDarkBorder = Color(0xff273443);
  static const Color inkDark = Color(0xffeef4fb);
  static const Color inkDarkMuted = Color(0xffa3b5c9);

  // Legacy aliases retained for compatibility
  static const Color pForest1 = telegramBlue;
  static const Color pForest2 = telegramBlueDeep;
  static const Color pForest3 = surfaceDark;

  static const Color sGoldenWheat1 = surfaceLightBorder;
  static const Color sGoldenWheat2 = telegramBlue;
  static const Color sGoldenWheat3 = Color(0xffde4e4e);

  static const Color tWhite = surfaceLightRaised;
  static const Color tCharcoal1 = inkLightMuted;
  static const Color tCharcoal2 = inkLight;

  static const Color cRed = Color(0xffFF0000);
}
