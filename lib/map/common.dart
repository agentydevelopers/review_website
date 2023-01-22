import 'dart:ui';

import 'package:flutter_map/plugin_api.dart';
import 'package:latlong2/latlong.dart';

double calculateRadiusMeter(FlutterMapState map, LatLng point, double radius) {
  var pos = _getPos(map, point);
  var rPos = map
      .project(const Distance().offset(point, radius, 180))
      .multiplyBy(map.getZoomScale(map.zoom, map.zoom)) -
      map.pixelOrigin;

  return rPos.y - pos.y as double;
}

Offset calculateOffset(FlutterMapState map, LatLng point) {
  var pos = _getPos(map, point);
  return Offset(pos.x.toDouble(), pos.y.toDouble());
}

CustomPoint<num> _getPos(FlutterMapState map, LatLng point) {
  return map.project(point).multiplyBy(map.getZoomScale(map.zoom, map.zoom)) -
      map.pixelOrigin;
}
