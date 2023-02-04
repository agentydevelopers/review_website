import 'dart:async';
import 'dart:math';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:rive/rive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:website/main.dart';
import 'package:website/map/item.dart';
import 'package:website/map/outer_circle.dart';
import 'package:website/map/player.dart';
import 'package:website/map/smoke_grenade.dart';
import 'package:share_plus/share_plus.dart';

import 'data.dart';

class GameMapPage extends StatefulWidget {
  final String gameId;

  const GameMapPage({super.key, required this.gameId});

  @override
  State<GameMapPage> createState() => _GameMapPageState();
}

class _GameMapPageState extends State<GameMapPage> {
  late AppLocalizations _l10n;
  final MapController _mapController = MapController();
  final List<double> _timerMultiplySteps = const [0.5, 1.0, 1.5, 2.0, 4.0];
  Data? _data;
  Duration? _gameDuration;
  DateTime? _gameTime;
  bool _running = true,
      _oldRunningValue = false,
      _scrollChange = false,
      _moving = false;
  Timer? _timer;
  int _timerMultiplyIndex = 1;
  final DateFormat dateFormatter = DateFormat('EEEE d.MMMM y');
  final DateFormat timeFormatter = DateFormat('H:m:ss.S');

  @override
  void initState() {
    Data.fetchData(widget.gameId).then((value) {
      //TODO remove dummy data
      if (value == null) {
        // Navigator.pushNamed(context, '/failed');
        // return;
        value = Data.dummyData();
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _data = value;
          _gameTime = value!.startTime;
          _gameDuration = value.endTime.difference(value.startTime);
          _startTimer();
          _mapController.fitBounds(
              _calculateLatLngBoundsWithRadius(
                  _data!.gameArenaCenter, _data!.gameArenaRadius),
              options: const FitBoundsOptions(maxZoom: 19.5));
        });
      });
    });
    super.initState();
  }

  LatLngBounds _calculateLatLngBoundsWithRadius(
      LatLng position, double radius) {
    double calcRadius = radius / (111325 * cos(position.latitudeInRad));
    LatLng topLeft =
        LatLng(position.latitude - calcRadius, position.longitude - calcRadius);
    LatLng bottomRight =
        LatLng(position.latitude + calcRadius, position.longitude + calcRadius);
    return LatLngBounds(topLeft, bottomRight);
  }

  @override
  Widget build(BuildContext context) {
    _l10n = AppLocalizations.of(context)!;
    List<PolylineMarker> polylineMarkers =
        _data == null ? [] : _data!.players.getPolylinesAndMarker(_gameTime!);
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).backgroundColor,
            automaticallyImplyLeading: false,
            title: Text(_l10n.agenty_game_review),
            leading: IconButton(
              icon: const Icon(
                Icons.home,
                color: Colors.white,
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/');
              },
            ),
            actions: [
              IconButton(
                tooltip: _running ? _l10n.pause : _l10n.resume,
                onPressed: _data == null
                    ? null
                    : () {
                        setState(() {
                          if (!_gameTime!.isBefore(_data!.endTime) ||
                              _gameTime == _data!.startTime) {
                            _gameTime = _data!.startTime;
                            _startTimer();
                          }
                          _running = !_running;
                        });
                      },
                color:
                    _data == null || _scrollChange ? Colors.grey : Colors.white,
                icon: _running
                    ? const Icon(Icons.pause)
                    : const Icon(Icons.play_arrow),
              ),
              Tooltip(
                message: _l10n.time_multiply,
                child: TextButton(
                  onPressed: _data == null
                      ? null
                      : () {
                          setState(() {
                            _timerMultiplyIndex++;
                            if (_timerMultiplyIndex >=
                                _timerMultiplySteps.length) {
                              _timerMultiplyIndex = 0;
                            }
                          });
                        },
                  child: Text(
                      'x${_timerMultiplySteps[_timerMultiplyIndex].toStringAsFixed(1)}',
                      style: TextStyle(
                          color: _data == null ? Colors.grey : Colors.white)),
                ),
              ),
              IconButton(
                tooltip: _l10n.refresh,
                onPressed: _data == null
                    ? null
                    : () {
                        setState(() {
                          _gameTime = _data!.startTime;
                          _startTimer();
                        });
                      },
                color: _data == null || _gameTime == _data!.startTime
                    ? Colors.grey
                    : Colors.white,
                icon: const Icon(Icons.refresh),
              ),
              IconButton(
                tooltip: _l10n.theme,
                onPressed: () async {
                  SharedPreferences pref =
                      await SharedPreferences.getInstance();
                  await pref.setInt(
                      MyApp.themeKey,
                      Theme.of(context).brightness == Brightness.dark
                          ? ThemePossibilities.light.index
                          : ThemePossibilities.dark.index);
                  setState(() {
                    MyApp.update(context);
                  });
                },
                icon: Icon(
                    Theme.of(context).brightness == Brightness.dark
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                    color: Colors.white),
              ),
              if (!kIsWeb)
                IconButton(
                  tooltip: _l10n.share,
                  onPressed: () {
                    Share.share(
                        'https://github.com'); //TODO set link, maybe clipboard for web or qr code creation
                  },
                  icon: const Icon(Icons.share, color: Colors.white),
                ),
            ],
          ),
          body: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                nonRotatedChildren: [
                  AttributionWidget.defaultWidget(
                      source: 'OpenStreetMap contributors',
                      onSourceTapped: null)
                ],
                options: MapOptions(
                  onMapEvent: (event) {
                    if (event is MapEventMoveStart) {
                      setState(() {
                        _moving = true;
                      });
                    } else if (event is MapEventFlingAnimationEnd ||
                        event is MapEventFlingAnimationNotStarted) {
                      setState(() {
                        _moving = false;
                      });
                    }
                  },
                  center: LatLng(50.097695, 8.670508),
                  zoom: 17,
                  maxBounds: LatLngBounds(
                    LatLng(-90, -180.0),
                    LatLng(90.0, 180.0),
                  ),
                ),
                children: [
                  TileLayer(
                    backgroundColor:
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.black
                            : Colors.white,
                    maxNativeZoom: 18.0,
                    urlTemplate:
                        'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'agenty.website',
                    subdomains: const ['a', 'b', 'c'],
                    tilesContainerBuilder:
                        Theme.of(context).brightness == Brightness.dark
                            ? darkModeTilesContainerBuilder
                            : null,
                  ),
                  if (_data != null)
                    SmokeGrenadeLayer(
                        smokeGrenades:
                            _data!.smokeGrenades.getSmokes(_gameTime!)),
                  if (_data != null)
                    PolylineLayer(
                      polylines: [
                        for (PolylineMarker polylineMarker in polylineMarkers)
                          if (polylineMarker.polyline != null)
                            polylineMarker.polyline!
                      ],
                    ),
                  if (_data != null)
                    MarkerLayer(
                      markers: [
                            for (PolylineMarker polylineMarker
                                in polylineMarkers)
                              if (polylineMarker.marker != null)
                                polylineMarker.marker!
                          ] +
                          _data!.coins.setState(_gameTime!),
                    ),
                  if (_data != null)
                    OuterCircleLayer(
                        marker: OuterCircleMarker(
                            borderColor: Theme.of(context).backgroundColor,
                            isMobile: !kIsWeb,
                            point: _data!.gameArenaCenter,
                            radius: _data!.gameArenaRadius))
                ],
              ),
              if (_data != null)
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 75, bottom: 10),
                      child: Slider(
                        activeColor: Theme.of(context).backgroundColor,
                        value: _gameTime!
                            .difference(_data!.startTime)
                            .inMilliseconds
                            .toDouble(),
                        min: 0,
                        divisions: _gameDuration!.inSeconds * 2,
                        label:
                            '${dateFormatter.format(_gameTime!)}, ${timeFormatter.format(_gameTime!)}',
                        max: _gameDuration!.inMilliseconds.toDouble(),
                        onChangeStart: (value) {
                          _oldRunningValue = _running;
                          setState(() {
                            _scrollChange = true;
                            _running = false;
                          });
                        },
                        onChanged: (double s) {
                          setState(() {
                            _gameTime = _data!.startTime
                                .add(Duration(milliseconds: s.toInt()));
                          });
                        },
                        onChangeEnd: (value) {
                          setState(() {
                            _scrollChange = false;
                            _running = _oldRunningValue;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              if (_data != null)
                ItemListDisplay(
                    items: _data!.items.setState(_gameTime!, context)),
              if (_data != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                          color: Theme.of(context).backgroundColor,
                          borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(15.0),
                              bottomRight: Radius.circular(15.0))),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          direction: Axis.vertical,
                          children: [
                            Text(
                              dateFormatter.format(_gameTime!),
                              style: const TextStyle(color: Colors.white),
                            ),
                            Text(timeFormatter.format(_gameTime!),
                                style: const TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          floatingActionButton: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FloatingActionButton(
                heroTag: _l10n.center,
                onPressed: _moving
                    ? null
                    : () {
                        _mapController.fitBounds(
                            _calculateLatLngBoundsWithRadius(
                                _data!.gameArenaCenter, _data!.gameArenaRadius),
                            options: const FitBoundsOptions(maxZoom: 19.5));
                      },
                backgroundColor:
                    _moving ? Colors.grey : Theme.of(context).backgroundColor,
                child: const Icon(Icons.my_location, color: Colors.white),
              ),
            ],
          ),
        ),
        Visibility(
          visible: _data == null,
          child: Container(
            color: const Color.fromARGB(200, 10, 10, 10),
            child: const RiveAnimation.asset(
              'assets/loading_compass.riv',
              artboard: 'compass',
              animations: ['active'],
            ),
          ),
        )
      ],
    );
  }

  void _startTimer() {
    _timer ??= Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (!mounted || !_running) return;
      setState(() {
        _gameTime = _gameTime!.add(Duration(
            milliseconds:
                (30 * _timerMultiplySteps[_timerMultiplyIndex]).toInt()));
        if (!_gameTime!.isBefore(_data!.endTime)) {
          _gameTime = _data!.endTime;
          _running = false;
          _timer?.cancel();
          _timer = null;
        }
      });
    });
  }
}
