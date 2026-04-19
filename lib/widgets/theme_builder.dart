import 'package:flutter/material.dart';

import 'package:collection/collection.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fluffychat/config/setting_keys.dart';
import 'package:fluffychat/utils/color_value.dart';

class ThemeBuilder extends StatefulWidget {
  final Widget Function(
    BuildContext context,
    ThemeMode themeMode,
    Color? primaryColor,
    Locale locale,
  )
  builder;

  final String themeModeSettingsKey;
  final String primaryColorSettingsKey;
  final String localeSettingsKey;

  const ThemeBuilder({
    required this.builder,
    this.themeModeSettingsKey = 'theme_mode',
    this.primaryColorSettingsKey = 'primary_color',
    this.localeSettingsKey = 'chat.fluffy.app_locale',
    super.key,
  });

  @override
  State<ThemeBuilder> createState() => ThemeController();
}

class ThemeController extends State<ThemeBuilder> {
  SharedPreferences? _sharedPreferences;
  ThemeMode? _themeMode;
  Color? _primaryColor;
  Locale? _locale;

  static const Set<String> _supportedLocaleCodes = {'ar', 'en'};

  ThemeMode get themeMode => _themeMode ?? ThemeMode.system;

  Color? get primaryColor => _primaryColor;

  Locale get locale => _locale ?? Locale(AppSettings.appLocale.defaultValue);

  static ThemeController of(BuildContext context) =>
      Provider.of<ThemeController>(context, listen: false);

  void _loadData(dynamic _) async {
    final preferences = _sharedPreferences ??=
        await SharedPreferences.getInstance();

    final rawThemeMode = preferences.getString(widget.themeModeSettingsKey);
    final rawColor = preferences.getInt(widget.primaryColorSettingsKey);
    final rawLocale =
        preferences.getString(widget.localeSettingsKey) ??
        AppSettings.appLocale.defaultValue;

    setState(() {
      _themeMode = ThemeMode.values.singleWhereOrNull(
        (value) => value.name == rawThemeMode,
      );
      _primaryColor = rawColor == null ? null : Color(rawColor);
      final localeCode = _supportedLocaleCodes.contains(rawLocale)
          ? rawLocale
          : AppSettings.appLocale.defaultValue;
      _locale = Locale(localeCode);
    });
  }

  Future<void> setThemeMode(ThemeMode newThemeMode) async {
    final preferences = _sharedPreferences ??=
        await SharedPreferences.getInstance();
    await preferences.setString(widget.themeModeSettingsKey, newThemeMode.name);
    setState(() {
      _themeMode = newThemeMode;
    });
  }

  Future<void> setPrimaryColor(Color? newPrimaryColor) async {
    final preferences = _sharedPreferences ??=
        await SharedPreferences.getInstance();
    if (newPrimaryColor == null) {
      await preferences.remove(widget.primaryColorSettingsKey);
    } else {
      await preferences.setInt(
        widget.primaryColorSettingsKey,
        newPrimaryColor.hexValue,
      );
    }
    setState(() {
      _primaryColor = newPrimaryColor;
    });
  }

  Future<void> setLocale(Locale newLocale) async {
    final preferences = _sharedPreferences ??=
        await SharedPreferences.getInstance();
    final localeCode = _supportedLocaleCodes.contains(newLocale.languageCode)
        ? newLocale.languageCode
        : AppSettings.appLocale.defaultValue;
    await preferences.setString(widget.localeSettingsKey, localeCode);
    setState(() {
      _locale = Locale(localeCode);
    });
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback(_loadData);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Provider(
      create: (_) => this,
      child: DynamicColorBuilder(
        builder: (light, _) => widget.builder(
          context,
          themeMode,
          primaryColor ?? light?.primary,
          locale,
        ),
      ),
    );
  }
}
