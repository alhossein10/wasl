import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:fluffychat/config/app_color.dart';
import 'package:fluffychat/config/setting_keys.dart';
import 'app_config.dart';

abstract class FluffyThemes {
  static const double columnWidth = 380.0;

  static const double maxTimelineWidth = columnWidth * 2;

  static const double navRailWidth = 80.0;

  static bool isColumnModeByWidth(double width) =>
      width > columnWidth * 2 + navRailWidth;

  static bool isColumnMode(BuildContext context) =>
      isColumnModeByWidth(MediaQuery.sizeOf(context).width);

  static bool isThreeColumnMode(BuildContext context) =>
      MediaQuery.sizeOf(context).width > FluffyThemes.columnWidth * 3.5;

  static LinearGradient backgroundGradient(BuildContext context, int alpha) {
    final colorScheme = Theme.of(context).colorScheme;
    return LinearGradient(
      begin: Alignment.topCenter,
      colors: [
        colorScheme.primaryContainer.withAlpha(alpha),
        colorScheme.secondaryContainer.withAlpha(alpha),
        colorScheme.tertiaryContainer.withAlpha(alpha),
        colorScheme.primaryContainer.withAlpha(alpha),
      ],
    );
  }

  static const Duration animationDuration = Duration(milliseconds: 250);
  static const Curve animationCurve = Curves.easeInOut;

  static ThemeData buildTheme(
    BuildContext context,
    Brightness brightness, [
    Color? seed,
  ]) {
    final colorScheme = _telegramColorScheme(
      brightness,
      seed ?? Color(AppSettings.colorSchemeSeedInt.value),
    );
    final isColumnMode = FluffyThemes.isColumnMode(context);
    final borderRadius = BorderRadius.circular(AppConfig.borderRadius);
    final appBarBackground = brightness == Brightness.dark
        ? colorScheme.surfaceContainer
        : colorScheme.surface;
    return ThemeData(
      visualDensity: VisualDensity.standard,
      useMaterial3: true,
      brightness: brightness,
      // Global app font for all Text widgets.
      fontFamily: AppSettings.fontName.value,

      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      canvasColor: colorScheme.surface,
      dividerColor: brightness == Brightness.dark
          ? colorScheme.outlineVariant.withValues(alpha: 0.6)
          : colorScheme.outlineVariant,
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: colorScheme.surfaceContainerHigh,
        iconColor: colorScheme.onSurface,
        textStyle: TextStyle(
          color: colorScheme.onSurface,
          fontFamily: AppSettings.fontName.value,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConfig.borderRadius),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          iconColor: colorScheme.onSurface,
          disabledIconColor: colorScheme.onSurface,
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        selectionColor: colorScheme.primary.withValues(alpha: 0.25),
        selectionHandleColor: colorScheme.primary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerLow,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConfig.borderRadius + 4),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConfig.borderRadius + 4),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConfig.borderRadius + 4),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConfig.borderRadius + 4),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConfig.borderRadius + 4),
          borderSide: BorderSide(color: colorScheme.error, width: 1.6),
        ),
      ),
      chipTheme: ChipThemeData(
        showCheckmark: false,
        backgroundColor: colorScheme.surfaceContainerLow,
        selectedColor: colorScheme.primaryContainer,
        labelStyle: TextStyle(
          fontFamily: AppSettings.fontName.value,
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConfig.borderRadius + 8),
        ),
      ),
      appBarTheme: AppBarTheme(
        toolbarHeight: isColumnMode ? 70 : 60,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: AppSettings.fontName.value,
          fontSize: 21,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        foregroundColor: colorScheme.onSurface,
        shadowColor: isColumnMode
            ? colorScheme.shadow.withValues(alpha: 0.08)
            : null,
        surfaceTintColor: Colors.transparent,
        backgroundColor: appBarBackground,
        actionsPadding: isColumnMode
            ? const EdgeInsets.symmetric(horizontal: 16.0)
            : null,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: brightness.reversed,
          statusBarBrightness: brightness,
          systemNavigationBarIconBrightness: brightness.reversed,
          systemNavigationBarColor: colorScheme.surface,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: BorderSide(width: 1, color: colorScheme.primary),
          shape: RoundedRectangleBorder(
            side: BorderSide(color: colorScheme.primary),
            borderRadius: BorderRadius.circular(AppConfig.borderRadius + 10),
          ),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        strokeCap: StrokeCap.round,
        color: colorScheme.primary,
        refreshBackgroundColor: colorScheme.primaryContainer,
      ),
      snackBarTheme: isColumnMode
          ? const SnackBarThemeData(
              showCloseIcon: true,
              behavior: SnackBarBehavior.floating,
              width: FluffyThemes.columnWidth * 1.5,
            )
          : const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          minimumSize: const Size(52, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConfig.borderRadius + 10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            fontFamily: AppSettings.fontName.value,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 0,
        foregroundColor: colorScheme.onPrimary,
        backgroundColor: colorScheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConfig.borderRadius + 12),
        ),
      ),
    );
  }

  static ColorScheme _telegramColorScheme(Brightness brightness, Color seed) {
    final fallback = brightness == Brightness.dark ? _darkScheme : _lightScheme;
    final generated = ColorScheme.fromSeed(
      brightness: brightness,
      seedColor: seed,
    );
    return generated.copyWith(
      primary: fallback.primary,
      onPrimary: fallback.onPrimary,
      primaryContainer: fallback.primaryContainer,
      onPrimaryContainer: fallback.onPrimaryContainer,
      secondary: fallback.secondary,
      onSecondary: fallback.onSecondary,
      secondaryContainer: fallback.secondaryContainer,
      onSecondaryContainer: fallback.onSecondaryContainer,
      tertiary: fallback.tertiary,
      onTertiary: fallback.onTertiary,
      tertiaryContainer: fallback.tertiaryContainer,
      onTertiaryContainer: fallback.onTertiaryContainer,
      error: fallback.error,
      onError: fallback.onError,
      errorContainer: fallback.errorContainer,
      onErrorContainer: fallback.onErrorContainer,
      surface: fallback.surface,
      onSurface: fallback.onSurface,
      surfaceContainerLowest: fallback.surfaceContainerLowest,
      surfaceContainerLow: fallback.surfaceContainerLow,
      surfaceContainer: fallback.surfaceContainer,
      surfaceContainerHigh: fallback.surfaceContainerHigh,
      surfaceContainerHighest: fallback.surfaceContainerHighest,
      onSurfaceVariant: fallback.onSurfaceVariant,
      outline: fallback.outline,
      outlineVariant: fallback.outlineVariant,
      shadow: fallback.shadow,
      scrim: fallback.scrim,
      inverseSurface: fallback.inverseSurface,
      onInverseSurface: fallback.onInverseSurface,
      inversePrimary: fallback.inversePrimary,
    );
  }

  static const ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColor.telegramBlue,
    onPrimary: Color(0xffffffff),
    primaryContainer: Color(0xffd9ecff),
    onPrimaryContainer: Color(0xff0c3f70),
    secondary: Color(0xff4d637a),
    onSecondary: Color(0xffffffff),
    secondaryContainer: Color(0xffdde8f4),
    onSecondaryContainer: Color(0xff24384d),
    tertiary: Color(0xff50606f),
    onTertiary: Color(0xffffffff),
    tertiaryContainer: Color(0xffd8e7f6),
    onTertiaryContainer: Color(0xff273746),
    error: Color(0xffc83c3c),
    onError: Color(0xffffffff),
    errorContainer: Color(0xffffdad8),
    onErrorContainer: Color(0xff4a1111),
    surface: AppColor.surfaceLight,
    onSurface: AppColor.inkLight,
    surfaceContainerLowest: Color(0xffffffff),
    surfaceContainerLow: Color(0xfff7f9fc),
    surfaceContainer: Color(0xffeef3f8),
    surfaceContainerHigh: Color(0xffe5ecf3),
    surfaceContainerHighest: Color(0xffdde5ee),
    onSurfaceVariant: AppColor.inkLightMuted,
    outline: Color(0xff7a8999),
    outlineVariant: AppColor.surfaceLightBorder,
    shadow: Color(0xff000000),
    scrim: Color(0xff000000),
    inverseSurface: Color(0xff1d2936),
    onInverseSurface: Color(0xffedf2f8),
    inversePrimary: AppColor.telegramBlueSoft,
  );

  static const ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xff65b3ff),
    onPrimary: Color(0xff002d56),
    primaryContainer: Color(0xff0f3a62),
    onPrimaryContainer: Color(0xffd2e8ff),
    secondary: Color(0xffb7cce3),
    onSecondary: Color(0xff213446),
    secondaryContainer: Color(0xff2d4154),
    onSecondaryContainer: Color(0xffd4e8ff),
    tertiary: Color(0xffa7c8e5),
    onTertiary: Color(0xff12324b),
    tertiaryContainer: Color(0xff294861),
    onTertiaryContainer: Color(0xffd0e9ff),
    error: Color(0xffff8f8a),
    onError: Color(0xff68000a),
    errorContainer: Color(0xff8c111a),
    onErrorContainer: Color(0xffffdad8),
    surface: AppColor.surfaceDark,
    onSurface: AppColor.inkDark,
    surfaceContainerLowest: Color(0xff0c1117),
    surfaceContainerLow: Color(0xff121b24),
    surfaceContainer: AppColor.surfaceDarkRaised,
    surfaceContainerHigh: Color(0xff1d2a36),
    surfaceContainerHighest: Color(0xff263747),
    onSurfaceVariant: AppColor.inkDarkMuted,
    outline: Color(0xff96a8bd),
    outlineVariant: AppColor.surfaceDarkBorder,
    shadow: Color(0xff000000),
    scrim: Color(0xff000000),
    inverseSurface: Color(0xffdde4ec),
    onInverseSurface: Color(0xff2a3440),
    inversePrimary: AppColor.telegramBlue,
  );
}

extension on Brightness {
  Brightness get reversed =>
      this == Brightness.dark ? Brightness.light : Brightness.dark;
}

extension BubbleColorTheme on ThemeData {
  Color get bubbleColor => brightness == Brightness.light
      ? colorScheme.primary
      : colorScheme.primaryContainer;

  Color get onBubbleColor => brightness == Brightness.light
      ? colorScheme.onPrimary
      : colorScheme.onPrimaryContainer;

  Color get secondaryBubbleColor => HSLColor.fromColor(
    brightness == Brightness.light
        ? colorScheme.tertiary
        : colorScheme.tertiaryContainer,
  ).withSaturation(0.5).toColor();
}
