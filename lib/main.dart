import 'package:flutter/material.dart';
import 'package:website/lobby.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'map/game_map.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const Map<String, Locale> _supportedLocales = {
    'English': Locale('en', ''),
    'Deutsch': Locale('de', ''),
  };

  @override
  Widget build(BuildContext context) {
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
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      onGenerateRoute: RouteGenerator._generateRoute,
    );
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
            break;
        }
      },
      settings: settings,
    );
  }
}
