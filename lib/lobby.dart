import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(text),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.fixed,
        ));
      });
    }
    return Scaffold(
        body: Center(
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
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: _l10n.enter_game_code,
                    suffixIcon: IconButton(
                      onPressed: () {
                        _gameCodeController.clear();
                        _focusNode.requestFocus();
                      },
                      icon: const Icon(Icons.clear),
                    ),
                  ),
                  onFieldSubmitted: (value) => onSubmit(),
                  validator: (String? value) {
                    if (value == null || value.isEmpty || value.length != 10) {
                      return _l10n.please_enter_the_game_code;
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: onSubmit,
                child: Text(_l10n.submit),
              ),
            ],
          ),
        ),
      ),
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
