import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:turf/boolean.dart';

import '_boolean_two_poly_base.dart';

class BooleanOverlapShowcase extends StatelessWidget {
  const BooleanOverlapShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    return TwoPolygonBooleanShowcase(
      label: 'overlap',
      hint: 'True when polygons share some but not all points',
      fnSignature: 'booleanOverlap(f1, f2)',
      predicate: (a, b) => booleanOverlap(a, b),
      defaultA: const [
        LatLng(0, 0),
        LatLng(0, 5),
        LatLng(5, 5),
        LatLng(5, 0),
      ],
      defaultB: const [
        LatLng(1, 1),
        LatLng(1, 6),
        LatLng(6, 6),
        LatLng(6, 1),
      ],
    );
  }
}
