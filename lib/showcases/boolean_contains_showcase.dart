import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:turf/boolean.dart';

import '_boolean_two_poly_base.dart';

class BooleanContainsShowcase extends StatelessWidget {
  const BooleanContainsShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    return TwoPolygonBooleanShowcase(
      label: 'contains',
      hint: 'Drag the red polygon entirely inside the blue one to flip true',
      fnSignature: 'booleanContains(blue, red)',
      predicate: (a, b) => booleanContains(a, b),
      defaultA: const [
        LatLng(0, 0),
        LatLng(0, 10),
        LatLng(10, 10),
        LatLng(10, 0),
      ],
      defaultB: const [
        LatLng(2, 2),
        LatLng(2, 6),
        LatLng(6, 6),
        LatLng(6, 2),
      ],
    );
  }
}
