import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:latlong2/latlong.dart' hide Path;

import 'common.dart';

class SmokeGrenades {
  final List<SmokeGrenade> smokes;

  SmokeGrenades({this.smokes = const []});

  Iterable<SmokeGrenade> getSmokes(DateTime gameTime) {
    return smokes.where((smoke) =>
        gameTime.isBefore(smoke.endTime) &&
        !gameTime.isBefore(smoke.startTime));
  }

  factory SmokeGrenades.fromJson(List<dynamic> jsonSmokeGrenades) {
    return SmokeGrenades(smokes: [
      for (Map<String, dynamic> jsonSmokeGrenade in jsonSmokeGrenades)
        SmokeGrenade.fromJson(jsonSmokeGrenade)
    ]);
  }
}

class SmokeGrenade {
  final LatLng point;
  final double radius;
  final DateTime startTime;
  final DateTime endTime;
  bool ended = false;
  final Color _backgroundColor = const Color(0xFF5f5c5b);
  double _radiusMeter = 0.0;

  SmokeGrenade({
    required this.startTime,
    required this.endTime,
    required this.point,
    required this.radius,
  });

  factory SmokeGrenade.fromJson(Map<String, dynamic> json) {
    return SmokeGrenade(
        startTime: DateTime.fromMillisecondsSinceEpoch(json['startTime']),
        endTime: DateTime.fromMillisecondsSinceEpoch(json['endTime']),
        point: LatLng(json['lat'], json['lng']),
        radius: json['radius']);
  }
}

class SmokeGrenadeLayer extends StatelessWidget {
  final Iterable<SmokeGrenade> smokeGrenades;

  const SmokeGrenadeLayer({Key? key, required this.smokeGrenades})
      : super(key: key);

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (BuildContext context, BoxConstraints bc) {
          var smokeWidgets = <Widget>[];
          for (var smoke in smokeGrenades) {
            final map = FlutterMapState.maybeOf(context)!;

            var pos = map.project(smoke.point) - map.pixelOrigin;
            smoke._radiusMeter =
                calculateRadiusMeter(map, smoke.point, smoke.radius);

            smokeWidgets.add(
              Positioned(
                left: pos.x.toDouble() - smoke._radiusMeter,
                top: pos.y.toDouble() - smoke._radiusMeter,
                child: Container(
                  width: smoke._radiusMeter * 2,
                  height: smoke._radiusMeter * 2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: smoke._backgroundColor,
                  ),
                ),
              ),
            );
          }

          return Stack(
            children: smokeWidgets,
          );
        },
      );
}

/*
[{"startTime":{dateTimeAsMilliSeconds},"endTime":{dateTimeAsMilliSeconds}, "lat":5, "lng":45, "radius":45}]
 */
