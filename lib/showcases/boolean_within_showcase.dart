import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:turf/boolean.dart';

import '_boolean_two_poly_base.dart';

class BooleanWithinShowcase extends StatelessWidget {
  const BooleanWithinShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    return TwoPolygonBooleanShowcase(
      label: 'within',
      hint: 'Returns true when the blue polygon lies completely inside the red',
      fnSignature: 'booleanWithin(blue, red)',
      predicate: (a, b) => booleanWithin(a, b),
      defaultA: const [
        LatLng(2, 2),
        LatLng(2, 6),
        LatLng(6, 6),
        LatLng(6, 2),
      ],
      defaultB: const [
        LatLng(0, 0),
        LatLng(0, 10),
        LatLng(10, 10),
        LatLng(10, 0),
      ],
    );
  }
}
