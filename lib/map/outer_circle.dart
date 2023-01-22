import 'package:flutter/cupertino.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:latlong2/latlong.dart' hide Path;

import 'common.dart';

class OuterCircleMarker {
  final LatLng point;
  final double radius;
  final Color backgroundColor;
  final double borderStrokeWidth;
  final Color borderColor;
  final bool isMobile;
  double _radiusMeter = 0.0;
  Offset _offset = Offset.zero;

  OuterCircleMarker({
    required this.point,
    required this.radius,
    required this.isMobile,
    this.backgroundColor = const Color(0x80f44336),
    this.borderStrokeWidth = 3.0,
    this.borderColor = const Color(0xff2196f3),
  });
}

class OuterCircleLayer extends StatelessWidget {
  final OuterCircleMarker marker;

  const OuterCircleLayer({Key? key, required this.marker}) : super(key: key);

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (BuildContext context, BoxConstraints bc) {
          final map = FlutterMapState.maybeOf(context)!;
          var circleWidgets = <Widget>[];
          marker._offset = calculateOffset(map, marker.point);
          marker._radiusMeter =
              calculateRadiusMeter(map, marker.point, marker.radius);

          circleWidgets.add(
            CustomPaint(
              painter: CircleExtraPainter(marker),
              size: Size(bc.maxWidth, bc.maxHeight),
            ),
          );

          return Stack(
            children: circleWidgets,
          );
        },
      );
}

class CircleExtraPainter extends CustomPainter {
  final OuterCircleMarker circle;

  CircleExtraPainter(this.circle);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.clipRect(rect);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = circle.borderColor
      ..strokeWidth = circle.borderStrokeWidth;
    canvas.drawCircle(circle._offset, circle._radiusMeter, paint);
    if (circle.isMobile) {
      canvas.drawPath(
          Path.combine(
            PathOperation.difference,
            Path()..addRect(rect),
            Path()
              ..addOval(Rect.fromCircle(
                  center: circle._offset, radius: circle._radiusMeter))
              ..close(),
          ),
          Paint()..color = circle.backgroundColor);
    }
  }

  @override
  bool shouldRepaint(CircleExtraPainter oldDelegate) => false;
}
