import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:libris/common/database/database_platform.dart';
import 'package:libris/common/localization/app_localization.dart';
import 'package:libris/common/providers/database_provider.dart';
import 'package:libris/common/services/database_helper.dart';
import 'package:libris/common/theme/app_theme.dart';
import 'package:libris/features/home/screens/home_screen.dart';
import 'package:libris/features/settings/services/settings_service.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  configureDatabaseFactory();
  await DatabaseHelper.instance.database;

  final settingsService = SettingsService();
  final theme = await settingsService.getTheme();
  appThemeNotifier.value = theme;

  final lang = await settingsService.getLanguage();
  appLanguageNotifier.value = lang;

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => DatabaseProvider())],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: appThemeNotifier,
      builder: (context, mode, child) {
        return ValueListenableBuilder<String>(
          valueListenable: appLanguageNotifier,
          builder: (context, language, child) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: l10n('Libris Kütüphane', 'Libris Library'),
              locale: Locale(language),
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              supportedLocales: const [Locale('tr'), Locale('en')],
              themeMode: mode,
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              home: const HomeScreen(),
            );
          },
        );
      },
    );
  }
}
