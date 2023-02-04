import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'main.dart';

enum LobbyErrors { noGameFoundError, missingQueryParameter, defaultError }

class LobbyPage extends StatefulWidget {
  final LobbyErrors? lobbyErrors;

  const LobbyPage({super.key, this.lobbyErrors});

  @override
  State<LobbyPage> createState() => _LobbyPageState();
}

class _LobbyPageState extends State<LobbyPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _gameCodeController = TextEditingController();
  late FocusNode _focusNode;
  late AppLocalizations _l10n;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    _l10n = AppLocalizations.of(context)!;
    if (widget.lobbyErrors != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        String? text;
        switch (widget.lobbyErrors!) {
          case LobbyErrors.defaultError:
            text = _l10n.default_error;
            break;
          case LobbyErrors.noGameFoundError:
            text = _l10n.no_game_found_error;
            break;
          case LobbyErrors.missingQueryParameter:
            text = _l10n.missing_query_parameter;
            break;
        }
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {
              ScaffoldMessenger.of(context).removeCurrentSnackBar();
            },
          ),
          content: Text(text, style: TextStyle(color: Colors.white)),
          duration: const Duration(minutes: 30),
          behavior: SnackBarBehavior.fixed,
          backgroundColor: Theme
              .of(context)
              .backgroundColor,
        ));
      });
    } else {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
    }
    return Scaffold(
        body: Stack(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: _l10n.theme,
                  onPressed: () async {
                    SharedPreferences pref = await SharedPreferences
                        .getInstance();
                    await pref.setInt(
                        MyApp.themeKey,
                        Theme
                            .of(context)
                            .brightness == Brightness.dark
                            ? ThemePossibilities.light.index
                            : ThemePossibilities.dark.index);
                    setState(() {
                      MyApp.update(context);
                    });
                  },
                  icon: Icon(
                      Theme
                          .of(context)
                          .brightness == Brightness.dark
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                      color: Colors.white),
                )
              ],
            ),
            Center(
              child: Container(
                padding: const EdgeInsets.all(40.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: <Widget>[
                      SizedBox(
                        width: 200,
                        child: TextFormField(
                          controller: _gameCodeController,
                          focusNode: _focusNode,
                          autofocus: true,
                          maxLength: 10,
                          cursorColor: Theme
                              .of(context)
                              .backgroundColor,
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: Theme
                                    .of(context)
                                    .backgroundColor,
                              ),
                            ),
                            hintText: _l10n.enter_game_code,
                            suffixIcon: IconButton(
                              onPressed: () {
                                _gameCodeController.clear();
                                _focusNode.requestFocus();
                              },
                              icon: Icon(
                                Icons.clear,
                                color: _focusNode.hasFocus ? Theme
                                    .of(context)
                                    .backgroundColor : null,
                              ),
                            ),
                          ),
                          onFieldSubmitted: (value) => onSubmit(),
                          validator: (String? value) {
                            if (value == null ||
                                value.isEmpty ||
                                value.length != 10) {
                              return _l10n.please_enter_the_game_code;
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all(
                                Theme
                                    .of(context)
                                    .backgroundColor)),
                        onPressed: onSubmit,
                        child: Text(_l10n.submit),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ));
  }

  void onSubmit() {
    if (_formKey.currentState!.validate()) {
      Navigator.pushNamed(
          context, '/game?gameId=${_gameCodeController.value.text}');
      // Process data.
    } else {
      _focusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }
}
