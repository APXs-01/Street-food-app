import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Something placed on the map at ([x], [y]), as fractions of the map's width
/// and height. By default the child hangs from that point (a pin's tip);
/// [centered] puts its middle there instead (a location dot).
class MapPlacement {
  const MapPlacement({required this.x, required this.y, required this.child, this.centered = false});

  final double x;
  final double y;
  final Widget child;
  final bool centered;
}

/// A stand-in for a real map: a generic backdrop (sea, a park, a block grid) with
/// [placements] laid over it. The backdrop is decoration and is not the user's
/// real surroundings; only the pins are real, placed from the stalls' actual
/// coordinates. There is no map SDK in the app yet; when one is added this is
/// the widget to replace.
class SimulatedMap extends StatelessWidget {
  const SimulatedMap({super.key, this.placements = const []});

  final List<MapPlacement> placements;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        return Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.hardEdge,
          children: [
            const CustomPaint(painter: _MapPainter()),
            for (final placement in placements)
              Positioned(
                left: placement.x * width,
                top: placement.y * height,
                child: FractionalTranslation(
                  translation: placement.centered ? const Offset(-0.5, -0.5) : const Offset(-0.5, -1),
                  child: placement.child,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _MapPainter extends CustomPainter {
  const _MapPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.mapLand);

    // The sea along the left edge, with a soft shoreline.
    final shore = Path()
      ..moveTo(0, 0)
      ..lineTo(w * 0.14, 0)
      ..quadraticBezierTo(w * 0.17, h * 0.25, w * 0.13, h * 0.5)
      ..quadraticBezierTo(w * 0.10, h * 0.75, w * 0.15, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(shore, Paint()..color = AppColors.mapWater);

    // Galle Face Green: the long park beside the sea.
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.2, h * 0.05, w * 0.3, h * 0.6), const Radius.circular(18)),
      Paint()..color = AppColors.mapPark,
    );

    final block = Paint()..color = AppColors.mapBlock;

    // City blocks east of the park; the gaps between them read as streets.
    for (var column = 0; column < 3; column++) {
      for (var row = 0; row < 5; row++) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * (0.55 + column * 0.15), h * (0.03 + row * 0.2), w * 0.125, h * 0.16),
            const Radius.circular(6),
          ),
          block,
        );
      }
    }

    // Blocks south of the park.
    for (var column = 0; column < 2; column++) {
      for (var row = 0; row < 2; row++) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * (0.2 + column * 0.16), h * (0.69 + row * 0.16), w * 0.14, h * 0.13),
            const Radius.circular(6),
          ),
          block,
        );
      }
    }

    // One main road across the grid.
    canvas.drawLine(
      Offset(w * 0.2, h * 0.67),
      Offset(w, h * 0.67),
      Paint()
        ..color = AppColors.surface
        ..strokeWidth = 5,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
