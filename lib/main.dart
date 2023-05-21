import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:website/lobby.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'map/game_map.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  static const String themeKey = 'THEME';

  const MyApp({Key? key}) : super(key: key);

  static const Map<String, Locale> _supportedLocales = {
    'English': Locale('en', ''),
    'Deutsch': Locale('de', ''),
  };

  ///Convert theme possibilities to theme mode
  static ThemeMode convertThemePossibilityToThemeMode(
      ThemePossibilities theme) {
    if (theme == ThemePossibilities.light) {
      return ThemeMode.light;
    } else {
      return ThemeMode.dark;
    }
  }

  static void update(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()?._update();

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  void _update() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: SharedPreferences.getInstance(),
        builder: (context, snapshot) {
          int? theme = snapshot.data?.getInt(MyApp.themeKey);
          return MaterialApp(
            title: 'AgentY',
            supportedLocales: MyApp._supportedLocales.values,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            localeResolutionCallback: (locale, supportedLocales) {
              for (var supportedLocale in supportedLocales) {
                if (supportedLocale.languageCode == locale!.languageCode) {
                  return supportedLocale;
                }
              }
              return supportedLocales.first;
            },
            themeMode: theme == null
                ? null
                : MyApp.convertThemePossibilityToThemeMode(
                    ThemePossibilities.values[theme]),
            theme: ThemeData(
                brightness: Brightness.light,
                colorScheme: const ColorScheme.light(
                    background: Color.fromARGB(249, 9, 143, 239))),
            darkTheme: ThemeData(
                brightness: Brightness.dark,
                colorScheme: const ColorScheme.dark(
                    background: Color.fromARGB(255, 0, 15, 107))),
            onGenerateRoute: RouteGenerator._generateRoute,
          );
        });
  }
}

class RouteGenerator {
  static Route<dynamic> _generateRoute(RouteSettings settings) {
    String? route;
    Map? queryParameters;
    if (settings.name != null) {
      var uriData = Uri.parse(settings.name!);
      route = uriData.path;
      queryParameters = uriData.queryParameters;
    }
    // print('generateRoute: Route $route, QueryParameters $queryParameters');
    return MaterialPageRoute(
      builder: (context) {
        switch (route) {
          case '/':
            return const LobbyPage();
          case '/game':
            if (queryParameters != null &&
                queryParameters.keys.contains("gameId")) {
              return GameMapPage(gameId: queryParameters["gameId"]);
            } else {
              return const LobbyPage(
                lobbyErrors: LobbyErrors.missingQueryParameter,
              );
            }
          case '/failed':
            return const LobbyPage(
              lobbyErrors: LobbyErrors.noGameFoundError,
            );
          default:
            return const LobbyPage(
              lobbyErrors: LobbyErrors.defaultError,
            );
        }
      },
      settings: settings,
    );
  }
}

enum ThemePossibilities { light, dark }
