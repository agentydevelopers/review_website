import 'dart:async';
import 'dart:math';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:rive/rive.dart';
import 'package:website/map/item.dart';
import 'package:website/map/outer_circle.dart';
import 'package:website/map/player.dart';
import 'package:website/map/smoke_grenade.dart';

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
  final List<double> _timerMultiplySteps = const [0.5, 1, 1.5, 2, 4];
  Data? _data;
  Duration? _gameDuration;
  DateTime? _gameTime;
  bool _running = true, _oldRunningValue = false, _scrollChange = false;
  Timer? _timer;
  int _timerMultiplyIndex = 1;

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
            automaticallyImplyLeading: false,
            title: Text(_l10n.agenty_game_review),
            leading: IconButton (
              icon: Icon(Icons.home),
              onPressed: () {
                Navigator.pushNamed(
                    context, '/');
              },
            ),
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
                options:
                    MapOptions(center: LatLng(50.097695, 8.670508), zoom: 17),
                children: [
                  TileLayer(
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
                            isMobile: !kIsWeb,
                            point: _data!.gameArenaCenter,
                            radius: _data!.gameArenaRadius))
                ],
              ),
              if (_data != null)
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Slider(
                          value: _gameTime!
                              .difference(_data!.startTime)
                              .inMilliseconds
                              .toDouble(),
                          min: 0,
                          divisions: _gameDuration!.inSeconds * 2,
                          label: _gameTime!.toIso8601String(),
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
                        Text(_gameTime!.toIso8601String())
                      ],
                    ),
                    ItemListDisplay(items: _data!.items.setState(_gameTime!)),
                  ],
                ),
            ],
          ),
          floatingActionButton: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FloatingActionButton(
                heroTag: 'timeMultiply',
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
                backgroundColor:
                    _data == null || _scrollChange ? Colors.grey : Colors.blue,
                child: Text('x${_timerMultiplySteps[_timerMultiplyIndex]}'),
              ),
              const SizedBox(
                height: 10,
              ),
              FloatingActionButton(
                heroTag: 'start',
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
                backgroundColor:
                    _data == null || _scrollChange ? Colors.grey : Colors.blue,
                child: _running
                    ? const Icon(Icons.pause)
                    : const Icon(Icons.play_arrow),
              ),
              const SizedBox(
                height: 10,
              ),
              FloatingActionButton(
                heroTag: 'refresh',
                onPressed: _data == null
                    ? null
                    : () {
                        setState(() {
                          _gameTime = _data!.startTime;
                          _startTimer();
                        });
                      },
                backgroundColor: _data == null || _gameTime == _data!.startTime
                    ? Colors.grey
                    : Colors.blue,
                child: const Icon(Icons.refresh),
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
