import 'dart:math' as math;

import '../../data/discovery_stall.dart';
import '../../providers/discovery_providers.dart';

/// Where something sits on the map card, as fractions of its width and height.
class MapSpot {
  const MapSpot(this.x, this.y);

  final double x;
  final double y;
}

/// Where the person stands on the map: a little above the middle, so pins have
/// room above and below.
const MapSpot kMapCentre = MapSpot(0.5, 0.42);

/// Places stalls on the simulated map from their real coordinates.
///
/// North is up. The scale is chosen so the farthest stall fits, with a minimum
/// so one nearby stall does not fill the map. Pins stay inside a band that the
/// screens' floating controls and bottom sheets do not cover. A stall with no
/// coordinates is left out.
Map<int, MapSpot> layoutOnMap(List<DiscoveryStall> stalls, SearchCenter center) {
  final cosLat = math.cos(center.latitude * math.pi / 180);

  final offsets = <int, ({double east, double north})>{};

  for (final stall in stalls) {
    final lat = stall.latitude;
    final lng = stall.longitude;
    if (lat == null || lng == null) continue;

    offsets[stall.id] = (
      east: (lng - center.longitude) * 111.32 * cosLat,
      north: (lat - center.latitude) * 110.57,
    );
  }

  var span = 0.3;
  for (final offset in offsets.values) {
    span = math.max(span, math.max(offset.east.abs(), offset.north.abs()) * 1.2);
  }

  double clamp(double value, double low, double high) => value < low ? low : (value > high ? high : value);

  return {
    for (final entry in offsets.entries)
      entry.key: MapSpot(
        clamp(kMapCentre.x + entry.value.east / span * 0.36, 0.16, 0.9),
        clamp(kMapCentre.y - entry.value.north / span * 0.16, 0.2, 0.62),
      ),
  };
}
