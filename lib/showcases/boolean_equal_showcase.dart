import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:turf/boolean.dart';

import '_boolean_two_poly_base.dart';

class BooleanEqualShowcase extends StatelessWidget {
  const BooleanEqualShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    return TwoPolygonBooleanShowcase(
      label: 'equal',
      hint: 'Drag any vertex to break geometric equality',
      fnSignature: 'booleanEqual(f1, f2)',
      predicate: (a, b) => booleanEqual(a, b),
      defaultA: const [
        LatLng(0, 0),
        LatLng(0, 5),
        LatLng(5, 5),
        LatLng(5, 0),
      ],
      defaultB: const [
        LatLng(0, 0),
        LatLng(0, 5),
        LatLng(5, 5),
        LatLng(5, 0),
      ],
    );
  }
}
